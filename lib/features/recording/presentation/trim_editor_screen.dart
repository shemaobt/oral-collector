import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/database/app_database.dart';
import '../../../core/platform/ffmpeg_ops.dart' as ffmpeg;
import '../../../core/platform/file_ops.dart' as file_ops;
import '../../../core/theme/app_colors.dart';
import '../../genre/presentation/notifiers/genre_notifier.dart';
import '../data/providers.dart';
import '../data/services/recording_trash.dart';
import '../data/services/waveform_extractor.dart';
import '../domain/entities/register.dart';
import '../../../core/l10n/content_l10n.dart';
import 'widgets/edit_transport_bar.dart';
import 'widgets/edit_volume_control.dart';
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
  LocalRecording? _recording;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  AudioPlayer? _player;
  Duration _totalDuration = Duration.zero;

  List<double> _splitPoints = [];

  Set<int> _excludedSegments = {};

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

  double _gainDb = 0.0;

  Map<String, String?> _segGenreBySig = {};
  Map<String, String?> _segSubcatBySig = {};
  Map<String, String?> _segRegisterBySig = {};

  String _sigAt(double midpointFraction) {
    return midpointFraction.toStringAsFixed(3);
  }

  String _sigForSegment(int i) {
    final mid = (_boundaries[i] + _boundaries[i + 1]) / 2.0;
    return _sigAt(mid);
  }

  String _effectiveGenre(int i) {
    final sig = _sigForSegment(i);
    final v = _segGenreBySig.containsKey(sig)
        ? _segGenreBySig[sig]
        : _recording?.genreId;
    return v ?? _recording?.genreId ?? '';
  }

  String? _effectiveSubcategory(int i) {
    final sig = _sigForSegment(i);
    return _segSubcatBySig.containsKey(sig)
        ? _segSubcatBySig[sig]
        : _recording?.subcategoryId;
  }

  String? _effectiveRegister(int i) {
    final sig = _sigForSegment(i);
    return _segRegisterBySig.containsKey(sig)
        ? _segRegisterBySig[sig]
        : _recording?.registerId;
  }

  Map<String, String?> _remapBySig(
    Map<String, String?> previous,
    List<double> previousBoundaries,
    List<double> newBoundaries,
  ) {
    final result = <String, String?>{};
    final previousSegCount = previousBoundaries.length - 1;
    final newSegCount = newBoundaries.length - 1;
    final previousMids = <double>[
      for (var i = 0; i < previousSegCount; i++)
        (previousBoundaries[i] + previousBoundaries[i + 1]) / 2.0,
    ];

    for (var j = 0; j < newSegCount; j++) {
      final newMid = (newBoundaries[j] + newBoundaries[j + 1]) / 2.0;
      double bestDist = double.infinity;
      int? bestIdx;
      for (var i = 0; i < previousMids.length; i++) {
        final d = (newMid - previousMids[i]).abs();
        if (d < bestDist) {
          bestDist = d;
          bestIdx = i;
        }
      }
      if (bestIdx == null || bestDist > 0.02) continue;
      final oldSig = _sigAt(previousMids[bestIdx]);
      if (!previous.containsKey(oldSig)) continue;
      final newSig = _sigAt(newMid);
      result[newSig] = previous[oldSig];
    }
    return result;
  }

  List<double> get _sortedSplits => [..._splitPoints]..sort();

  List<double> get _boundaries {
    final s = _sortedSplits;
    return [0.0, ...s, 1.0];
  }

  int get _segmentCount => _boundaries.length - 1;

  int get _keptCount => _segmentCount - _excludedSegments.length;

  Duration _segmentStart(int i) {
    return Duration(
      milliseconds: (_boundaries[i] * _totalDuration.inMilliseconds).round(),
    );
  }

  Duration _segmentEnd(int i) {
    return Duration(
      milliseconds: (_boundaries[i + 1] * _totalDuration.inMilliseconds)
          .round(),
    );
  }

  Duration _segmentDuration(int i) => _segmentEnd(i) - _segmentStart(i);

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    Future.microtask(_loadRecording);
  }

  @override
  void dispose() {
    _previewSub?.cancel();
    _transportPositionSub?.cancel();
    _transportStateSub?.cancel();
    _player?.dispose();
    super.dispose();
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
        .where((g) => g.id == (genreId ?? _recording?.genreId))
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
    final recording = _recording;
    if (recording == null) return;

    final sig = _sigForSegment(index);
    final initialGenre = _segGenreBySig.containsKey(sig)
        ? _segGenreBySig[sig]
        : null;
    final initialSub = _segSubcatBySig.containsKey(sig)
        ? _segSubcatBySig[sig]
        : recording.subcategoryId;
    final initialReg = _segRegisterBySig.containsKey(sig)
        ? _segRegisterBySig[sig]
        : recording.registerId;

    final result = await showModalBottomSheet<SegmentTaxonomyResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SegmentTaxonomySheet(
        parentGenreId: recording.genreId,
        initialGenreId: initialGenre,
        initialSubcategoryId: initialSub,
        initialRegisterId: initialReg,
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      if (result.applyToAll) {
        _segGenreBySig = {
          for (var i = 0; i < _segmentCount; i++)
            _sigForSegment(i): result.genreId,
        };
        _segSubcatBySig = {
          for (var i = 0; i < _segmentCount; i++)
            _sigForSegment(i): result.subcategoryId,
        };
        _segRegisterBySig = {
          for (var i = 0; i < _segmentCount; i++)
            _sigForSegment(i): result.registerId,
        };
      } else {
        _segGenreBySig = {..._segGenreBySig, sig: result.genreId};
        _segSubcatBySig = {..._segSubcatBySig, sig: result.subcategoryId};
        _segRegisterBySig = {..._segRegisterBySig, sig: result.registerId};
      }
    });
  }

  void _copyFromPrevious(int index) {
    if (index <= 0) return;
    final previousSig = _sigForSegment(index - 1);
    final currentSig = _sigForSegment(index);

    final prevGenre = _segGenreBySig.containsKey(previousSig)
        ? _segGenreBySig[previousSig]
        : null;
    final prevSub = _segSubcatBySig.containsKey(previousSig)
        ? _segSubcatBySig[previousSig]
        : _recording?.subcategoryId;
    final prevReg = _segRegisterBySig.containsKey(previousSig)
        ? _segRegisterBySig[previousSig]
        : _recording?.registerId;

    HapticFeedback.lightImpact();
    setState(() {
      _segGenreBySig = {..._segGenreBySig, currentSig: prevGenre};
      _segSubcatBySig = {..._segSubcatBySig, currentSig: prevSub};
      _segRegisterBySig = {..._segRegisterBySig, currentSig: prevReg};
    });
  }

  void _seekPlayheadTo(double fraction) {
    final player = _player;
    if (player == null) return;
    final totalMs = _totalDuration.inMilliseconds;
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
    final clamped = _gainDb.clamp(-12.0, 0.0);
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

  Future<void> _loadRecording() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      LocalRecording? recording;

      if (kIsWeb) {
        final apiRepo = ref.read(recordingApiRepositoryProvider);
        final server = await apiRepo.getRecording(widget.recordingId);
        recording = LocalRecording(
          id: server.id,
          projectId: server.projectId,
          genreId: server.genreId,
          subcategoryId: server.subcategoryId,
          registerId: server.registerId,
          title: server.title,
          durationSeconds: server.durationSeconds,
          fileSizeBytes: server.fileSizeBytes,
          format: server.format,
          localFilePath: '',
          uploadStatus: server.uploadStatus,
          serverId: server.id,
          gcsUrl: server.gcsUrl,
          cleaningStatus: server.cleaningStatus,
          recordedAt: server.recordedAt,
          createdAt: server.recordedAt,
          retryCount: 0,
          uploadedBytes: 0,
        );
      } else {
        final localRepo = ref.read(localRecordingRepositoryProvider);

        recording = await localRepo.getRecordingById(widget.recordingId);
        recording ??= await localRepo.getRecordingByServerId(
          widget.recordingId,
        );

        if (recording == null) {
          try {
            final apiRepo = ref.read(recordingApiRepositoryProvider);
            final server = await apiRepo.getRecording(widget.recordingId);
            recording = LocalRecording(
              id: server.id,
              projectId: server.projectId,
              genreId: server.genreId,
              subcategoryId: server.subcategoryId,
              registerId: server.registerId,
              title: server.title,
              durationSeconds: server.durationSeconds,
              fileSizeBytes: server.fileSizeBytes,
              format: server.format,
              localFilePath: '',
              uploadStatus: server.uploadStatus,
              serverId: server.id,
              gcsUrl: server.gcsUrl,
              cleaningStatus: server.cleaningStatus,
              recordedAt: server.recordedAt,
              createdAt: server.recordedAt,
              retryCount: 0,
              uploadedBytes: 0,
            );
          } catch (_) {}
        }
      }

      if (recording == null || !mounted) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (kIsWeb) {
        if (recording.gcsUrl == null) {
          if (mounted) {
            setState(() {
              _recording = recording;
              _isLoading = false;
              _errorMessage = 'Audio URL not available for this recording.';
            });
          }
          return;
        }
        try {
          await _player!.setUrl(recording.gcsUrl!);
        } catch (_) {}
      } else {
        if (recording.localFilePath.isEmpty ||
            !await file_ops.fileExists(recording.localFilePath)) {
          if (mounted) {
            setState(() {
              _recording = recording;
              _isLoading = false;
              _errorMessage =
                  'Local audio file not available. Download the recording first.';
            });
          }
          return;
        }
        await _player!.setFilePath(recording.localFilePath);
      }

      var duration = _player!.duration ?? Duration.zero;

      if (duration == Duration.zero && recording.durationSeconds > 0) {
        duration = Duration(
          milliseconds: (recording.durationSeconds * 1000).round(),
        );
      }

      const barCount = 2000;
      List<double> bars;

      if (!kIsWeb && recording.localFilePath.isNotEmpty) {
        final peaks = await WaveformExtractor.extractPeaks(
          recording.localFilePath,
          targetCount: barCount,
        );
        if (peaks.isEmpty) {
          final rng = Random(recording.localFilePath.hashCode);
          bars = List.generate(barCount, (_) => 0.15 + rng.nextDouble() * 0.85);
        } else {
          bars = peaks.peaks;
        }
      } else {
        final rng = Random((recording.gcsUrl ?? recording.id).hashCode);
        bars = List.generate(barCount, (_) => 0.15 + rng.nextDouble() * 0.85);
      }

      if (mounted) {
        setState(() {
          _recording = recording;
          _totalDuration = duration;
          _waveformBars = bars;
          _isLoading = false;
        });
        _attachTransportListeners();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addSplitAtPlayhead() {
    final totalMs = _totalDuration.inMilliseconds;
    if (totalMs <= 0) return;
    final fraction = (_transportPosition.inMilliseconds / totalMs).clamp(
      0.0,
      1.0,
    );
    const minGap = 0.03;
    if (fraction <= minGap || fraction >= 1.0 - minGap) return;
    for (final p in _splitPoints) {
      if ((fraction - p).abs() < minGap) return;
    }
    HapticFeedback.lightImpact();
    _onSplitPointsChanged([..._splitPoints, fraction]);
  }

  bool get _canSplitAtPlayhead {
    final totalMs = _totalDuration.inMilliseconds;
    if (totalMs <= 0) return false;
    final fraction = _transportPosition.inMilliseconds / totalMs;
    const minGap = 0.03;
    if (fraction <= minGap || fraction >= 1.0 - minGap) return false;
    for (final p in _splitPoints) {
      if ((fraction - p).abs() < minGap) return false;
    }
    return true;
  }

  void _onSplitPointsChanged(List<double> pts) {
    final newSegCount = pts.length + 1;
    final pruned = _excludedSegments.where((i) => i < newSegCount).toSet();

    final previousBoundaries = [..._boundaries];
    final sortedNew = [...pts]..sort();
    final newBoundaries = [0.0, ...sortedNew, 1.0];
    final remappedGenre = _remapBySig(
      _segGenreBySig,
      previousBoundaries,
      newBoundaries,
    );
    final remappedSubcat = _remapBySig(
      _segSubcatBySig,
      previousBoundaries,
      newBoundaries,
    );
    final remappedReg = _remapBySig(
      _segRegisterBySig,
      previousBoundaries,
      newBoundaries,
    );

    setState(() {
      _splitPoints = pts;
      _excludedSegments = pruned;
      _segGenreBySig = remappedGenre;
      _segSubcatBySig = remappedSubcat;
      _segRegisterBySig = remappedReg;
    });
  }

  void _toggleExclude(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      final updated = Set<int>.from(_excludedSegments);
      if (updated.contains(index)) {
        updated.remove(index);
      } else {
        if (updated.length >= _segmentCount - 1) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.trim_atLeastOneSegment)));
          return;
        }
        updated.add(index);
      }
      _excludedSegments = updated;
    });
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

    final startTime = _segmentStart(index);
    final endTime = _segmentEnd(index);

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
    _previewSub?.cancel();
    _previewSub = null;
    await _player?.pause();
    if (mounted) setState(() => _playingSegment = null);
  }

  List<int> get _keptSegmentIndices {
    return [
      for (var i = 0; i < _segmentCount; i++)
        if (!_excludedSegments.contains(i)) i,
    ];
  }

  Future<void> _saveSplit() async {
    final recording = _recording;
    if (recording == null || _splitPoints.isEmpty) return;
    if (_keptCount == 0) return;

    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.trim_saveConfirmTitle),
        content: Text(l10n.trim_saveConfirmBody(_keptCount)),
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

    setState(() => _isSaving = true);

    try {
      await _stopPreview();
      await _player?.stop();

      if (kIsWeb) {
        await _saveSplitServerSide(recording);
      } else {
        await _saveSplitLocally(recording);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error splitting: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveSplitServerSide(LocalRecording recording) async {
    final serverId = recording.serverId ?? recording.id;
    final kept = _keptSegmentIndices;

    final segments = kept.map((i) {
      final effGenre = _effectiveGenre(i);
      final effSubcat = _effectiveSubcategory(i);
      final effRegister = _effectiveRegister(i);
      return {
        'start_seconds': _segmentStart(i).inMilliseconds / 1000.0,
        'end_seconds': _segmentEnd(i).inMilliseconds / 1000.0,
        if (effGenre.isNotEmpty && effGenre != recording.genreId)
          'genre_id': effGenre,
        if (effSubcat != null && effSubcat.isNotEmpty)
          'subcategory_id': effSubcat,
        if (effRegister != null && effRegister.isNotEmpty)
          'register_id': effRegister,
      };
    }).toList();

    final apiRepo = ref.read(recordingApiRepositoryProvider);
    final payloadSegments = _gainDb.abs() > 0.01
        ? segments.map((s) => {...s, 'gain_db': _gainDb}).toList()
        : segments;
    await apiRepo.splitRecording(serverId: serverId, segments: payloadSegments);

    if (mounted) {
      final l10n = AppLocalizations.of(context);
      final msg = _excludedSegments.isNotEmpty
          ? l10n.trim_savedSegments(kept.length, _excludedSegments.length)
          : l10n.trim_splitInto(kept.length);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go('/recordings');
      }
    }
  }

  Future<void> _saveSplitLocally(LocalRecording recording) async {
    final dir = await getApplicationDocumentsDirectory();
    final repo = ref.read(localRecordingRepositoryProvider);
    final now = DateTime.now();
    final originalTitle = recording.title ?? 'Recording';
    final kept = _keptSegmentIndices;
    final keptTotal = kept.length;

    for (var k = 0; k < keptTotal; k++) {
      final i = kept[k];
      final startSec = _segmentStart(i).inMilliseconds / 1000.0;
      final endSec = _segmentEnd(i).inMilliseconds / 1000.0;
      final segDuration = endSec - startSec;

      final outputPath =
          '${dir.path}/split_${now.millisecondsSinceEpoch}_$k.m4a';

      final needReencode = _gainDb.abs() > 0.01;
      final command = needReencode
          ? '-y -i "${recording.localFilePath}" -ss $startSec -to $endSec '
                '-af "volume=${_gainDb.toStringAsFixed(2)}dB" '
                '-c:a aac -b:a 128k "$outputPath"'
          : '-y -i "${recording.localFilePath}" -ss $startSec -to $endSec '
                '-c copy "$outputPath"';

      final success = await ffmpeg.executeFFmpegCommand(command);
      if (!success) {
        throw Exception('FFmpeg failed on segment ${k + 1}');
      }

      final fileSize = await file_ops.fileLength(outputPath);

      final id =
          '${now.millisecondsSinceEpoch}_${k}_${recording.genreId.hashCode}';

      final effGenre = _effectiveGenre(i);
      final effSubcat = _effectiveSubcategory(i);
      final effRegister = _effectiveRegister(i);
      await repo.insertRecording(
        LocalRecordingsCompanion(
          id: Value(id),
          projectId: Value(recording.projectId),
          genreId: Value(effGenre.isNotEmpty ? effGenre : recording.genreId),
          subcategoryId: (effSubcat != null && effSubcat.isNotEmpty)
              ? Value(effSubcat)
              : const Value.absent(),
          registerId: (effRegister != null && effRegister.isNotEmpty)
              ? Value(effRegister)
              : const Value.absent(),
          title: Value(
            keptTotal == 1
                ? originalTitle
                : '$originalTitle (${k + 1}/$keptTotal)',
          ),
          durationSeconds: Value(segDuration),
          fileSizeBytes: Value(fileSize),
          format: const Value('m4a'),
          localFilePath: Value(outputPath),
          recordedAt: Value(recording.recordedAt),
        ),
      );
    }

    await RecordingTrash.putInTrash(
      sourcePath: recording.localFilePath,
      metadata: {
        'id': recording.id,
        'title': recording.title,
        'projectId': recording.projectId,
        'genreId': recording.genreId,
        'subcategoryId': recording.subcategoryId,
        'registerId': recording.registerId,
        'durationSeconds': recording.durationSeconds,
        'fileSizeBytes': recording.fileSizeBytes,
        'format': recording.format,
        'serverId': recording.serverId,
        'gcsUrl': recording.gcsUrl,
        'recordedAt': recording.recordedAt.toIso8601String(),
      },
    );
    await repo.deleteRecording(recording.id);

    final serverId = recording.serverId;
    if (serverId != null && serverId.isNotEmpty) {
      try {
        final apiRepo = ref.read(recordingApiRepositoryProvider);
        await apiRepo.deleteRecording(serverId);
      } catch (_) {}
    }

    if (mounted) {
      HapticFeedback.mediumImpact();
      final l10n = AppLocalizations.of(context);
      final msg = _excludedSegments.isNotEmpty
          ? l10n.trim_savedSegments(keptTotal, _excludedSegments.length)
          : l10n.trim_splitInto(keptTotal);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go('/recordings');
      }
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

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(l10n.trim_title),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_recording == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(l10n.trim_title),
        ),
        body: Center(child: Text(l10n.trim_notFound)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(l10n.trim_title),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.downloadCloud,
                  size: 48,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final colors = AppColors.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasSplits = _splitPoints.isNotEmpty;

    final totalMs = _totalDuration.inMilliseconds;
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
          duration: _totalDuration,
          onPlayPause: _toggleTransport,
          canSplitAtPosition: _canSplitAtPlayhead,
          onSplitAtPosition: _addSplitAtPlayhead,
        ),
        const SizedBox(height: 10),
        if (!kIsWeb)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: EditVolumeControl(
              gainDb: _gainDb,
              peakAmplitude: _visiblePeak(),
              volumeLabel: l10n.trim_volume,
              clippingLabel: l10n.trim_peakClip,
              boostOnSaveLabel: l10n.trim_boostOnSave,
              onChanged: (v) {
                setState(() => _gainDb = v);
                _applyPreviewVolume();
              },
            ),
          ),
        TrimWaveformPanel(
          waveformBars: _waveformBars,
          splitPoints: _splitPoints,
          onSplitPointsChanged: _onSplitPointsChanged,
          playingSegment: _playingSegment,
          excludedSegments: _excludedSegments,
          hasSplits: hasSplits,
          keptCount: _keptCount,
          segmentCount: _segmentCount,
          totalDurationLabel: _fmt(_totalDuration),
          totalDurationShortLabel: _fmtShort(_totalDuration),
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
          onClearAll: () => setState(() {
            _splitPoints = [];
            _excludedSegments = {};
          }),
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
              if (_excludedSegments.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _excludedSegments = {});
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
          const SizedBox(height: 10),
          ...List.generate(_segmentCount, (i) {
            final isPlaying = _playingSegment == i;
            final isExcluded = _excludedSegments.contains(i);
            final effGenre = _effectiveGenre(i);
            final effSubcat = _effectiveSubcategory(i);
            final effRegister = _effectiveRegister(i);
            final subName = _subcategoryNameFor(l10n, effSubcat, effGenre);
            final regName = _registerNameFor(l10n, effRegister);
            final sig = _sigForSegment(i);
            final hasSubcatOverride = _segSubcatBySig.containsKey(sig);
            final hasRegOverride = _segRegisterBySig.containsKey(sig);
            final hasGenreOverride = _segGenreBySig.containsKey(sig);
            final genreName = hasGenreOverride
                ? _genreNameFor(l10n, effGenre)
                : null;
            final subDisplay = genreName != null
                ? (subName != null
                      ? '$genreName · $subName'
                      : '$genreName · ${l10n.trim_inheritLabel}')
                : subName;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SegmentCard(
                index: i,
                total: _segmentCount,
                start: _fmt(_segmentStart(i)),
                end: _fmt(_segmentEnd(i)),
                duration: _fmtShort(_segmentDuration(i)),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              border: Border.all(color: colors.border.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Icon(
                  LucideIcons.splitSquareHorizontal,
                  size: 36,
                  color: colors.foreground.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 12),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: waveformPanel,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(0, 24, 24, 16),
                          child: segmentsList,
                        ),
                      ),
                      _buildActionBar(colors, isDark, hasSplits, l10n),
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
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      waveformPanel,
                      const SizedBox(height: 20),
                      segmentsList,
                    ],
                  ),
                ),
              ),
              _buildActionBar(colors, isDark, hasSplits, l10n),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionBar(
    AppColorSet colors,
    bool isDark,
    bool hasSplits,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                onPressed: _isSaving
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n.common_cancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (_isSaving || !hasSplits || _keptCount == 0)
                    ? null
                    : _saveSplit,
                icon: _isSaving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.scissors, size: 16),
                label: Text(
                  _isSaving
                      ? l10n.trim_splitting
                      : hasSplits
                      ? l10n.trim_saveSegments(_keptCount)
                      : l10n.trim_addSplitsFirst,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  disabledBackgroundColor: colors.accent.withValues(
                    alpha: 0.25,
                  ),
                  disabledForegroundColor: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
