import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/utils/recording_title.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/platform/file_ops.dart' as file_ops;
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/waveform_visualizer.dart';
import '../../../project/presentation/notifiers/project_notifier.dart';
import '../../data/providers.dart';
import '../notifiers/recording_session_state.dart';

class ConfirmationStep extends ConsumerStatefulWidget {
  const ConfirmationStep({
    super.key,
    required this.result,
    required this.genreId,
    required this.subcategoryId,
    this.registerId,
    required this.genreName,
    required this.subcategoryName,
    this.registerName,
    required this.onReRecord,
  });

  final RecordingResult result;
  final String genreId;
  final String? subcategoryId;
  final String? registerId;
  final String? genreName;
  final String? subcategoryName;
  final String? registerName;
  final VoidCallback onReRecord;

  @override
  ConsumerState<ConfirmationStep> createState() => _ConfirmationStepState();
}

class _ConfirmationStepState extends ConsumerState<ConfirmationStep> {
  final _titleController = TextEditingController();
  AudioPlayer? _player;
  bool _isPlaying = false;
  bool _isSaving = false;
  Duration _position = Duration.zero;
  Duration _totalDuration = Duration.zero;

  double get _progress {
    if (_totalDuration.inMilliseconds == 0) return 0.0;
    return (_position.inMilliseconds / _totalDuration.inMilliseconds).clamp(
      0.0,
      1.0,
    );
  }

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _player = AudioPlayer();
    _player!.playerStateStream.listen((playerState) {
      if (!mounted) return;
      final playing = playerState.playing;
      final completed =
          playerState.processingState == ProcessingState.completed;
      setState(() {
        _isPlaying = playing && !completed;
      });
      if (completed) {
        _player!.seek(Duration.zero);
        _player!.pause();
      }
    });
    _player!.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);
    });
    _player!.durationStream.listen((dur) {
      if (!mounted || dur == null) return;
      setState(() => _totalDuration = dur);
    });
    try {
      await _player!.setFilePath(widget.result.filePath);
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleController.dispose();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_player == null) return;
    HapticFeedback.lightImpact();
    if (_isPlaying) {
      await _player!.pause();
    } else {
      await _player!.play();
    }
  }

  void _seekTo(double fraction) {
    if (_totalDuration.inMilliseconds == 0) return;
    _player?.seek(
      Duration(
        milliseconds: (_totalDuration.inMilliseconds * fraction.clamp(0.0, 1.0))
            .round(),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final projectState = ref.read(projectNotifierProvider);
    final projectId = projectState.activeProject?.id ?? '';
    final repo = ref.read(localRecordingRepositoryProvider);

    int fileSize = 0;
    if (!kIsWeb) {
      try {
        fileSize = await file_ops.fileLength(widget.result.filePath);
      } catch (_) {}
    }

    final id =
        '${DateTime.now().millisecondsSinceEpoch}_${widget.genreId.hashCode}';

    await repo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(id),
        projectId: Value(projectId),
        genreId: Value(widget.genreId),
        subcategoryId:
            widget.subcategoryId != null && widget.subcategoryId!.isNotEmpty
            ? Value(widget.subcategoryId!)
            : const Value.absent(),
        registerId: widget.registerId != null && widget.registerId!.isNotEmpty
            ? Value(widget.registerId!)
            : const Value.absent(),
        title: Value(
          _titleController.text.trim().isNotEmpty
              ? _titleController.text.trim()
              : defaultRecordingTitle(),
        ),
        durationSeconds: Value(widget.result.durationSeconds),
        fileSizeBytes: Value(fileSize),
        localFilePath: Value(widget.result.filePath),
        recordedAt: Value(DateTime.now()),
      ),
    );

    if (mounted) {
      HapticFeedback.mediumImpact();
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.recording_saved)));
      context.go('/home');
    }
  }

  Future<void> _discard() async {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recording_discardTitle),
        content: Text(l10n.recording_discardMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: colors.error),
            child: Text(l10n.recording_discard),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!kIsWeb) {
        try {
          await file_ops.deleteFile(widget.result.filePath);
        } catch (_) {}
      }

      if (mounted) context.go('/genre/${widget.genreId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    final tagParts = <String>[];
    if (widget.genreName != null) tagParts.add(widget.genreName!);
    if (widget.subcategoryName != null) tagParts.add(widget.subcategoryName!);
    if (widget.registerName != null) tagParts.add(widget.registerName!);
    final tagLabel = tagParts.join(' / ');

    final seed = widget.result.durationSeconds.hashCode;
    final amplitudes = List.generate(
      80,
      (i) => (0.15 + 0.7 * (((i * 7 + seed) * 13 + 3) % 17) / 16.0).clamp(
        0.1,
        0.9,
      ),
    );

    return SizedBox.expand(
      child: ColoredBox(
        color: colors.background,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  formatDurationMinSec(widget.result.durationSeconds),
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w200,
                    fontSize: 48,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ),

              if (tagLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      tagLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.secondary,
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildWaveformPlayer(colors, amplitudes),

                      const SizedBox(height: 6),

                      Text(
                        '${formatPositionMS(_position)} / ${formatDurationMinSec(widget.result.durationSeconds)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.secondary,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),

                      const SizedBox(height: 24),

                      GestureDetector(
                        onTap: _togglePlayback,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.accent,
                            boxShadow: [
                              BoxShadow(
                                color: colors.accent.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isPlaying ? LucideIcons.pause : LucideIcons.play,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  AppShell.scrollBottomPadding,
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: l10n.recording_titleHint,
                        hintStyle: TextStyle(color: colors.secondary),
                        filled: true,
                        fillColor: colors.surfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colors.accent,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l10n.recording_saveRecording,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () {
                                _player?.stop();
                                widget.onReRecord();
                              },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: colors.border.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          l10n.recording_recordAgain,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colors.foreground,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    TextButton(
                      onPressed: _isSaving ? null : _discard,
                      style: TextButton.styleFrom(
                        foregroundColor: colors.error,
                      ),
                      child: Text(l10n.recording_discard),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaveformPlayer(AppColorSet colors, List<double> amplitudes) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _seekTo(d.localPosition.dx / width),
          onHorizontalDragUpdate: (d) => _seekTo(d.localPosition.dx / width),
          child: SizedBox(
            height: 100,
            child: Stack(
              children: [
                WaveformVisualizer(
                  amplitudes: amplitudes,
                  barColor: colors.foreground.withValues(alpha: 0.12),
                  fillWidth: true,
                  height: 100,
                  barCount: 80,
                ),

                ClipRect(
                  clipper: _ProgressClipper(progress: _progress),
                  child: WaveformVisualizer(
                    amplitudes: amplitudes,
                    barColor: colors.accent,
                    fillWidth: true,
                    height: 100,
                    barCount: 80,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProgressClipper extends CustomClipper<Rect> {
  final double progress;
  const _ProgressClipper({required this.progress});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * progress, size.height);
  }

  @override
  bool shouldReclip(covariant _ProgressClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}
