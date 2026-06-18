import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/l10n/content_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../genre/presentation/notifiers/genre_notifier.dart';
import '../data/providers.dart';
import '../data/services/waveform_loader.dart';
import '../domain/entities/register.dart';
import 'notifiers/recording_player_notifier.dart';
import 'notifiers/trim_editor_notifier.dart';
import 'notifiers/trim_editor_state.dart';
import 'trim_edit_decision.dart';
import 'widgets/edit_transport_bar.dart';
import 'widgets/edit_volume_control.dart';
import 'widgets/playback_key_handler.dart';
import 'widgets/segment_card.dart';
import 'widgets/segment_taxonomy_sheet.dart';
import 'widgets/trim_waveform_panel.dart';

class TrimEditorScreen extends ConsumerStatefulWidget {
  const TrimEditorScreen({super.key, required this.recordingId});

  final String recordingId;

  @override
  ConsumerState<TrimEditorScreen> createState() => _TrimEditorScreenState();
}

class _TrimEditorScreenState extends ConsumerState<TrimEditorScreen> {
  // Editing + load state lives in TrimEditorNotifier (ENG-193); the widget keeps
  // only the audio player, transport playback and the waveform viewport.
  AudioPlayer? _player;

  int? _playingSegment;
  List<double> _waveformBars = [];

  StreamSubscription<Duration>? _previewSub;
  StreamSubscription<Duration>? _transportPositionSub;
  StreamSubscription<PlayerState>? _transportStateSub;

  bool _isTransportPlaying = false;
  Duration _transportPosition = Duration.zero;
  final Stopwatch _playheadThrottle = Stopwatch()..start();
  final Stopwatch _sinceLocalSeek = Stopwatch();

  double _zoom = 1.0;
  double _panFraction = 0.0;

  TrimEditorNotifier get _notifier =>
      ref.read(trimEditorProvider(widget.recordingId).notifier);
  TrimEditorState get _state =>
      ref.read(trimEditorProvider(widget.recordingId));

  @override
  void initState() {
    super.initState();
    _player = ref.read(audioPlayerFactoryProvider)();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _previewSub?.cancel();
    _transportPositionSub?.cancel();
    _transportStateSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  /// The notifier resolves the recording row; the widget owns the player, the
  /// file-availability check and the waveform/duration, finishing the load via
  /// the notifier's [TrimEditorNotifier.setUnavailable]/[completeLoad].
  Future<void> _load() async {
    await _notifier.load(isWeb: kIsWeb);
    if (!mounted) return;
    final recording = _state.recording;
    if (recording == null) return; // notifier set not-found / load error

    try {
      if (kIsWeb) {
        if (recording.gcsUrl == null) {
          _notifier.setUnavailable(
            'Audio URL not available for this recording.',
          );
          return;
        }
        try {
          await _player!.setUrl(recording.gcsUrl!);
        } catch (_) {}
      } else {
        if (recording.localFilePath.isEmpty ||
            !await ref.read(fileExistsProvider)(recording.localFilePath)) {
          _notifier.setUnavailable(
            'Local audio file not available. Download the recording first.',
          );
          return;
        }
        await _player!.setFilePath(recording.localFilePath);
      }
      if (!mounted) return;

      var duration = _player!.duration ?? Duration.zero;
      if (duration == Duration.zero && recording.durationSeconds > 0) {
        duration = Duration(
          milliseconds: (recording.durationSeconds * 1000).round(),
        );
      }

      const barCount = 2000;
      List<double> bars;
      if (!kIsWeb && recording.localFilePath.isNotEmpty) {
        final peaks = await ref.read(waveformLoaderProvider)(
          recording.localFilePath,
          targetCount: barCount,
        );
        if (peaks.isEmpty) {
          final rng = Random(recording.localFilePath.hashCode);
          bars = List.generate(barCount, (_) => 0.15 + rng.nextDouble() * 0.85);
        } else {
          bars = peaks;
        }
      } else {
        final rng = Random((recording.gcsUrl ?? recording.id).hashCode);
        bars = List.generate(barCount, (_) => 0.15 + rng.nextDouble() * 0.85);
      }
      if (!mounted) return;

      setState(() => _waveformBars = bars);
      _notifier.completeLoad(totalDuration: duration);
      _attachTransportListeners();
    } catch (_) {
      if (mounted) _notifier.loadFailed();
    }
  }

  void _attachTransportListeners() {
    final player = _player;
    if (player == null) return;

    _transportPositionSub?.cancel();
    _transportPositionSub = player.positionStream.listen((pos) {
      if (!mounted) return;
      if (_playingSegment != null) return;
      if (_sinceLocalSeek.isRunning &&
          _sinceLocalSeek.elapsedMilliseconds < 250) {
        return;
      }
      if (_playheadThrottle.elapsedMilliseconds < 33) return;
      _playheadThrottle.reset();
      setState(() => _transportPosition = pos);
    });

    _transportStateSub?.cancel();
    _transportStateSub = player.playerStateStream.listen((state) {
      if (!mounted) return;
      final playing = state.playing && _playingSegment == null;
      if (playing != _isTransportPlaying) {
        setState(() => _isTransportPlaying = playing);
      }
      if (state.processingState == ProcessingState.completed) {
        player.pause();
        player.seek(Duration.zero);
        if (mounted) {
          setState(() {
            _isTransportPlaying = false;
            _transportPosition = Duration.zero;
          });
        }
      }
    });
  }

  String? _subcategoryNameFor(
    AppLocalizations l10n,
    String? subcategoryId,
    String? genreId,
  ) {
    if (subcategoryId == null || subcategoryId.isEmpty) return null;
    final genres = ref.read(genreNotifierProvider).genres;
    final genre = genres
        .where((g) => g.id == (genreId ?? _state.recording?.genreId))
        .firstOrNull;
    final sub = genre?.subcategories
        .where((s) => s.id == subcategoryId)
        .firstOrNull;
    if (sub == null) return null;
    return localizedSubcategoryName(l10n, sub.name);
  }

  String? _genreNameFor(AppLocalizations l10n, String? genreId) {
    if (genreId == null || genreId.isEmpty) return null;
    final genres = ref.read(genreNotifierProvider).genres;
    final genre = genres.where((g) => g.id == genreId).firstOrNull;
    if (genre == null) return null;
    return localizedGenreName(l10n, genre.name);
  }

  String? _registerNameFor(AppLocalizations l10n, String? registerId) {
    if (registerId == null || registerId.isEmpty) return null;
    final reg = kRegisters.where((r) => r.id == registerId).firstOrNull;
    if (reg == null) return null;
    return localizedRegisterName(l10n, reg.name);
  }

  Future<void> _openTaxonomySheet(int index) async {
    final recording = _state.recording;
    if (recording == null) return;

    final sig = _state.sigForSegment(index);
    final initialGenre = _state.segGenreBySig.containsKey(sig)
        ? _state.segGenreBySig[sig]
        : null;
    final initialSub = _state.segSubcatBySig.containsKey(sig)
        ? _state.segSubcatBySig[sig]
        : recording.subcategoryId;
    final initialReg = _state.segRegisterBySig.containsKey(sig)
        ? _state.segRegisterBySig[sig]
        : recording.registerId;

    final result = await showModalBottomSheet<SegmentTaxonomyResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RadiusScale.r20),
        ),
      ),
      builder: (ctx) => SegmentTaxonomySheet(
        parentGenreId: recording.genreId,
        parentSecondaryGenreId: recording.secondaryGenreId,
        parentSecondarySubcategoryId: recording.secondarySubcategoryId,
        parentSecondaryRegisterId: recording.secondaryRegisterId,
        initialGenreId: initialGenre,
        initialSubcategoryId: initialSub,
        initialRegisterId: initialReg,
      ),
    );

    if (result == null || !mounted) return;

    _notifier.setSegmentTaxonomy(
      index: index,
      applyToAll: result.applyToAll,
      genreId: result.genreId,
      subcategoryId: result.subcategoryId,
      registerId: result.registerId,
    );
  }

  void _copyFromPrevious(int index) {
    HapticFeedback.lightImpact();
    _notifier.copyFromPrevious(index);
  }

  void _seekPlayheadTo(double fraction) {
    final player = _player;
    if (player == null) return;
    final totalMs = _state.totalDuration.inMilliseconds;
    if (totalMs <= 0) return;
    final target = Duration(
      milliseconds: (fraction.clamp(0.0, 1.0) * totalMs).round(),
    );

    if (_playingSegment != null) {
      _previewSub?.cancel();
      _previewSub = null;
    }
    if (mounted) {
      setState(() {
        _transportPosition = target;
        _playingSegment = null;
      });
    }
    _sinceLocalSeek
      ..reset()
      ..start();

    player.pause();
    player.seek(target);
  }

  void _seekAndPlay(double fraction) {
    final player = _player;
    if (player == null) return;

    _seekPlayheadTo(fraction);

    if (!player.playing) {
      _applyPreviewVolume();
      player.play();
    }
  }

  Future<void> _toggleTransport() async {
    final player = _player;
    if (player == null) return;

    if (_playingSegment != null) {
      await _stopPreview();
    }

    if (player.playing) {
      await player.pause();
      if (mounted) {
        setState(() => _transportPosition = player.position);
      }
    } else {
      await _applyPreviewVolume();
      await player.play();
    }
  }

  Future<void> _applyPreviewVolume() async {
    final player = _player;
    if (player == null) return;
    final clamped = _state.gainDb.clamp(-12.0, 0.0);
    final multiplier = pow(10, clamped / 20).toDouble();
    try {
      await player.setVolume(multiplier.clamp(0.0, 1.0));
    } on Exception {
      // ignore
    }
  }

  double _visiblePeak() {
    if (_waveformBars.isEmpty) return 0.0;
    final viewportStart = _panFraction;
    final viewportEnd = _panFraction + 1.0 / _zoom;
    final first = (viewportStart * _waveformBars.length).floor().clamp(
      0,
      _waveformBars.length - 1,
    );
    final last = (viewportEnd * _waveformBars.length).ceil().clamp(
      first,
      _waveformBars.length,
    );
    var peak = 0.0;
    for (var i = first; i < last; i++) {
      if (_waveformBars[i] > peak) peak = _waveformBars[i];
    }
    return peak;
  }

  void _addSplitAtPlayhead() {
    final totalMs = _state.totalDuration.inMilliseconds;
    if (totalMs <= 0) return;
    final fraction = (_transportPosition.inMilliseconds / totalMs).clamp(
      0.0,
      1.0,
    );
    const minGap = 0.03;
    if (fraction <= minGap || fraction >= 1.0 - minGap) return;
    for (final p in _state.splitPoints) {
      if ((fraction - p).abs() < minGap) return;
    }
    HapticFeedback.lightImpact();
    _notifier.setSplitPoints([..._state.splitPoints, fraction]);
  }

  bool get _canSplitAtPlayhead {
    final totalMs = _state.totalDuration.inMilliseconds;
    if (totalMs <= 0) return false;
    final fraction = _transportPosition.inMilliseconds / totalMs;
    const minGap = 0.03;
    if (fraction <= minGap || fraction >= 1.0 - minGap) return false;
    for (final p in _state.splitPoints) {
      if ((fraction - p).abs() < minGap) return false;
    }
    return true;
  }

  void _toggleExclude(int index) {
    HapticFeedback.lightImpact();
    if (!_notifier.toggleExclude(index)) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.trim_atLeastOneSegment)));
    }
  }

  Future<void> _previewSegment(int index) async {
    if (_player == null) return;

    final wasPlaying = _playingSegment == index && _player!.playing;

    await _stopPreview();

    if (wasPlaying) return;

    if (_isTransportPlaying) {
      await _player!.pause();
      if (mounted) setState(() => _isTransportPlaying = false);
    }

    final startTime = _state.segmentStart(index);
    final endTime = _state.segmentEnd(index);

    await _applyPreviewVolume();
    await _player!.seek(startTime);

    setState(() => _playingSegment = index);

    _previewSub = _player!.positionStream.listen((position) {
      if (position < startTime - const Duration(milliseconds: 100)) return;
      if (position >= endTime) {
        _player!.pause();
        if (mounted) setState(() => _playingSegment = null);
      }
    });

    await _player!.play();
  }

  Future<void> _stopPreview() async {
    unawaited(_previewSub?.cancel());
    _previewSub = null;
    await _player?.pause();
    if (mounted) setState(() => _playingSegment = null);
  }

  Future<void> _saveSplit() async {
    final recording = _state.recording;
    if (recording == null) return;
    if (!_state.decision.canSave) return;

    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.trim_saveConfirmTitle),
        content: Text(l10n.trim_saveConfirmBody(_state.keptCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.common_save),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _stopPreview();
    await _player?.stop();
    if (!mounted) return;

    final localeTag = Localizations.localeOf(context).toString();
    final outcome = await _notifier.saveSplit(
      isWeb: kIsWeb,
      localeTag: localeTag,
    );
    if (!mounted) return;

    switch (outcome) {
      case TrimSaveSucceeded(
        :final mode,
        :final keptCount,
        :final excludedCount,
      ):
        // The local save path haptic-confirms; the server path never did.
        if (!kIsWeb) unawaited(HapticFeedback.mediumImpact());
        final msg = mode == TrimSaveMode.boostOnly
            ? l10n.trim_boostApplied
            : excludedCount > 0
            ? l10n.trim_savedSegments(keptCount, excludedCount)
            : l10n.trim_splitInto(keptCount);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        if (context.canPop()) {
          context.pop(true);
        } else {
          context.go('/recordings');
        }
      case TrimSaveFailed(:final error):
        final friendly = friendlyErrorFor(error, l10n);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.trim_splitError(friendly))));
      case TrimSaveAborted():
        break;
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(
      2,
      '0',
    );
    return '$m:$s.$ms';
  }

  String _fmtShort(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(trimEditorProvider(widget.recordingId));

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(l10n.trim_title),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Error takes precedence over not-found: a failed load leaves the recording
    // null, so checking not-found first would mask the real error (ENG-140 F21).
    final errorText =
        state.errorMessage ??
        (state.loadError != null
            ? friendlyErrorFor(state.loadError!, l10n)
            : null);
    if (errorText != null) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(l10n.trim_title),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(SpacingScale.s32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.downloadCloud,
                  size: 48,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(height: SpacingScale.s16),
                Text(
                  errorText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.recording == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(l10n.trim_title),
        ),
        body: Center(child: Text(l10n.trim_notFound)),
      );
    }

    final colors = AppColors.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasSplits = state.splitPoints.isNotEmpty;

    final totalMs = state.totalDuration.inMilliseconds;
    final hasPosition =
        _transportPosition > Duration.zero || _isTransportPlaying;
    final double? playheadFraction = (hasPosition && totalMs > 0)
        ? (_transportPosition.inMilliseconds / totalMs).clamp(0.0, 1.0)
        : null;

    final waveformPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditTransportBar(
          isPlaying: _isTransportPlaying,
          position: _transportPosition,
          duration: state.totalDuration,
          onPlayPause: _toggleTransport,
          canSplitAtPosition: _canSplitAtPlayhead,
          onSplitAtPosition: _addSplitAtPlayhead,
        ),
        const SizedBox(height: SpacingScale.s8),
        Padding(
          padding: const EdgeInsets.only(bottom: SpacingScale.s8),
          child: EditVolumeControl(
            gainDb: state.gainDb,
            peakAmplitude: _visiblePeak(),
            volumeLabel: l10n.trim_volume,
            clippingLabel: l10n.trim_peakClip,
            boostOnSaveLabel: l10n.trim_boostOnSave,
            onChanged: (v) {
              _notifier.setGain(v);
              _applyPreviewVolume();
            },
          ),
        ),
        TrimWaveformPanel(
          waveformBars: _waveformBars,
          splitPoints: state.splitPoints,
          onSplitPointsChanged: _notifier.setSplitPoints,
          playingSegment: _playingSegment,
          excludedSegments: state.excludedSegments,
          hasSplits: hasSplits,
          keptCount: state.keptCount,
          segmentCount: state.segmentCount,
          totalDurationLabel: _fmt(state.totalDuration),
          totalDurationShortLabel: _fmtShort(state.totalDuration),
          playheadFraction: playheadFraction,
          onPlayheadSeek: _seekPlayheadTo,
          onSeekAndPlay: _seekAndPlay,
          zoom: _zoom,
          panFraction: _panFraction,
          onZoomPanChanged: (v) => setState(() {
            _zoom = v.zoom;
            _panFraction = v.panFraction;
          }),
          onResetZoom: () => setState(() {
            _zoom = 1.0;
            _panFraction = 0.0;
          }),
          onClearAll: () => _notifier.clearAllSplits(),
        ),
      ],
    );

    final segmentsList = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasSplits) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.trim_segments,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (state.excludedSegments.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _notifier.restoreAllExcluded();
                  },
                  child: Text(
                    l10n.trim_restoreAll,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.accent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: SpacingScale.s8),
          ...List.generate(state.segmentCount, (i) {
            final isPlaying = _playingSegment == i;
            final isExcluded = state.excludedSegments.contains(i);
            final effGenre = state.effectiveGenre(i);
            final effSubcat = state.effectiveSubcategory(i);
            final effRegister = state.effectiveRegister(i);
            final subName = _subcategoryNameFor(l10n, effSubcat, effGenre);
            final regName = _registerNameFor(l10n, effRegister);
            final sig = state.sigForSegment(i);
            final hasSubcatOverride = state.segSubcatBySig.containsKey(sig);
            final hasRegOverride = state.segRegisterBySig.containsKey(sig);
            final hasGenreOverride = state.segGenreBySig.containsKey(sig);
            final genreName = hasGenreOverride
                ? _genreNameFor(l10n, effGenre)
                : null;
            final subDisplay = genreName != null
                ? (subName != null
                      ? '$genreName · $subName'
                      : '$genreName · ${l10n.trim_inheritLabel}')
                : subName;
            return Padding(
              padding: const EdgeInsets.only(bottom: SpacingScale.s8),
              child: SegmentCard(
                index: i,
                total: state.segmentCount,
                start: _fmt(state.segmentStart(i)),
                end: _fmt(state.segmentEnd(i)),
                duration: _fmtShort(state.segmentDuration(i)),
                isPlaying: isPlaying,
                isExcluded: isExcluded,
                onPlayPause: () => _previewSegment(i),
                onToggleExclude: () => _toggleExclude(i),
                colors: colors,
                isDark: isDark,
                subcategoryLabel: subDisplay,
                registerLabel: regName,
                inheritLabel: l10n.trim_inheritLabel,
                copyFromPreviousLabel: l10n.trim_copyFromPrevious,
                hasSubcategoryOverride: hasSubcatOverride || hasGenreOverride,
                hasRegisterOverride: hasRegOverride,
                canCopyFromPrevious: i > 0,
                onClassify: () => _openTaxonomySheet(i),
                onCopyFromPrevious: i > 0 ? () => _copyFromPrevious(i) : null,
              ),
            );
          }),
        ] else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingScale.s24,
              vertical: SpacingScale.s32,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: colors.border.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(RadiusScale.r16),
            ),
            child: Column(
              children: [
                Icon(
                  LucideIcons.splitSquareHorizontal,
                  size: 36,
                  color: colors.foreground.withValues(alpha: 0.2),
                ),
                const SizedBox(height: SpacingScale.s12),
                Text(
                  l10n.trim_instructions,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.foreground.withValues(alpha: 0.4),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(l10n.trim_title),
        actions: [
          TextButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/recordings');
              }
            },
            child: Text(
              l10n.common_cancel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.foreground.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
      body: PlaybackKeyHandler(
        onSpace: _toggleTransport,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(SpacingScale.s24),
                      child: waveformPanel,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(
                              0,
                              SpacingScale.s24,
                              SpacingScale.s24,
                              SpacingScale.s16,
                            ),
                            child: segmentsList,
                          ),
                        ),
                        _buildActionBar(colors, isDark, hasSplits, l10n, state),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingScale.s16,
                      vertical: SpacingScale.s16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        waveformPanel,
                        const SizedBox(height: SpacingScale.s20),
                        segmentsList,
                      ],
                    ),
                  ),
                ),
                _buildActionBar(colors, isDark, hasSplits, l10n, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionBar(
    AppColorSet colors,
    bool isDark,
    bool hasSplits,
    AppLocalizations l10n,
    TrimEditorState state,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        SpacingScale.s16,
        SpacingScale.s12,
        SpacingScale.s16,
        SpacingScale.s16,
      ),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: 0.15)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: state.isSaving
                    ? null
                    : () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/recordings');
                        }
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.foreground.withValues(
                    alpha: isDark ? 0.8 : 0.7,
                  ),
                  side: BorderSide(
                    color: colors.border.withValues(alpha: isDark ? 0.4 : 0.35),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: SpacingScale.s16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RadiusScale.r12),
                  ),
                ),
                child: Text(l10n.common_cancel),
              ),
            ),
            const SizedBox(width: SpacingScale.s12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (state.isSaving || !state.decision.canSave)
                    ? null
                    : _saveSplit,
                icon: state.isSaving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? AppColors.black : AppColors.white,
                        ),
                      )
                    : Icon(
                        state.decision.mode == TrimSaveMode.boostOnly
                            ? LucideIcons.volume2
                            : LucideIcons.scissors,
                        size: 16,
                      ),
                label: Text(
                  state.isSaving
                      ? l10n.trim_splitting
                      : state.decision.mode == TrimSaveMode.boostOnly
                      ? l10n.trim_applyBoost
                      : hasSplits
                      ? l10n.trim_saveSegments(state.keptCount)
                      : l10n.trim_addSplitsFirst,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: isDark ? AppColors.black : AppColors.white,
                  disabledBackgroundColor: colors.accent.withValues(
                    alpha: 0.25,
                  ),
                  disabledForegroundColor: isDark
                      ? AppColors.black.withValues(alpha: 0.3)
                      : AppColors.white.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(
                    vertical: SpacingScale.s16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RadiusScale.r12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
