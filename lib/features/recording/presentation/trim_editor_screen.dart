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
import '../data/providers.dart';
import 'widgets/segment_card.dart';
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
    _player?.dispose();
    super.dispose();
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

      final rng = Random(
        kIsWeb
            ? (recording.gcsUrl ?? recording.id).hashCode
            : recording.localFilePath.hashCode,
      );
      const barCount = 70;
      final bars = List.generate(
        barCount,
        (_) => 0.15 + rng.nextDouble() * 0.85,
      );

      if (mounted) {
        setState(() {
          _recording = recording;
          _totalDuration = duration;
          _waveformBars = bars;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSplitPointsChanged(List<double> pts) {
    final newSegCount = pts.length + 1;
    final pruned = _excludedSegments.where((i) => i < newSegCount).toSet();
    setState(() {
      _splitPoints = pts;
      _excludedSegments = pruned;
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

    final startTime = _segmentStart(index);
    final endTime = _segmentEnd(index);

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
      return {
        'start_seconds': _segmentStart(i).inMilliseconds / 1000.0,
        'end_seconds': _segmentEnd(i).inMilliseconds / 1000.0,
      };
    }).toList();

    final apiRepo = ref.read(recordingApiRepositoryProvider);
    await apiRepo.splitRecording(serverId: serverId, segments: segments);

    if (mounted) {
      final l10n = AppLocalizations.of(context);
      final msg = _excludedSegments.isNotEmpty
          ? l10n.trim_savedSegments(kept.length, _excludedSegments.length)
          : l10n.trim_splitInto(kept.length);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      context.pop(true);
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

      final command =
          '-i "${recording.localFilePath}" -ss $startSec -to $endSec -c copy "$outputPath"';

      final success = await ffmpeg.executeFFmpegCommand(command);
      if (!success) {
        throw Exception('FFmpeg failed on segment ${k + 1}');
      }

      final fileSize = await file_ops.fileLength(outputPath);

      final id =
          '${now.millisecondsSinceEpoch}_${k}_${recording.genreId.hashCode}';

      await repo.insertRecording(
        LocalRecordingsCompanion(
          id: Value(id),
          projectId: Value(recording.projectId),
          genreId: Value(recording.genreId),
          subcategoryId:
              recording.subcategoryId != null &&
                  recording.subcategoryId!.isNotEmpty
              ? Value(recording.subcategoryId!)
              : const Value.absent(),
          registerId:
              recording.registerId != null && recording.registerId!.isNotEmpty
              ? Value(recording.registerId!)
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

    await file_ops.deleteFile(recording.localFilePath);
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
      context.pop(true);
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

    final waveformPanel = TrimWaveformPanel(
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
      onClearAll: () => setState(() {
        _splitPoints = [];
        _excludedSegments = {};
      }),
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
            onPressed: () => context.pop(),
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
                  child: Padding(
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
                onPressed: _isSaving ? null : () => context.pop(),
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
