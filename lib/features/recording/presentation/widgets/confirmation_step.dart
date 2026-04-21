import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/utils/recording_title.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/platform/file_ops.dart' as file_ops;
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/waveform_visualizer.dart';
import '../../../project/presentation/notifiers/project_notifier.dart';
import '../../../storyteller/domain/entities/storyteller.dart';
import '../../../storyteller/presentation/notifiers/project_storytellers_notifier.dart';
import '../../../storyteller/presentation/widgets/storyteller_picker.dart';
import '../../../sync/presentation/notifiers/sync_notifier.dart';
import '../../data/providers.dart';
import '../../data/services/direct_recording_uploader.dart';
import '../../domain/entities/classification.dart';
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
    required this.onDiscard,
  });

  final RecordingResult result;
  final String genreId;
  final String? subcategoryId;
  final String? registerId;
  final String? genreName;
  final String? subcategoryName;
  final String? registerName;
  final VoidCallback onReRecord;
  final VoidCallback onDiscard;

  @override
  ConsumerState<ConfirmationStep> createState() => _ConfirmationStepState();
}

class _ConfirmationStepState extends ConsumerState<ConfirmationStep> {
  final _descriptionController = TextEditingController();
  AudioPlayer? _player;
  bool _isPlaying = false;
  bool _isSaving = false;
  Duration _position = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Storyteller? _selectedStoryteller;

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
    Future.microtask(_prefetchStorytellers);
  }

  void _prefetchStorytellers() {
    if (!mounted) return;
    final projectId = ref.read(projectNotifierProvider).activeProject?.id;
    if (projectId == null || projectId.isEmpty) return;
    final state = ref.read(projectStorytellersNotifierProvider);
    if (state.projectId != projectId || state.storytellers.isEmpty) {
      ref.read(projectStorytellersNotifierProvider.notifier).fetch(projectId);
    }
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
      if (kIsWeb) {
        final bytes = await file_ops.readFileBytes(widget.result.filePath);
        if (bytes.isEmpty) {
          debugPrint('Recording file is empty at ${widget.result.filePath}');
          return;
        }
        final mime = _mimeForFormat(widget.result.format);
        final dataUri = Uri.dataFromBytes(bytes, mimeType: mime).toString();
        await _player!.setUrl(dataUri);
      } else {
        final fileSize = await file_ops.fileLength(widget.result.filePath);
        if (fileSize <= 0) {
          debugPrint(
            'Recording file is 0 bytes at ${widget.result.filePath} — '
            'microphone likely did not capture audio.',
          );
          return;
        }
        await _player!.setFilePath(widget.result.filePath);
      }
    } catch (e, st) {
      debugPrint('Player load failed: $e\n$st');
    }
  }

  String _mimeForFormat(String format) {
    switch (format) {
      case 'webm':
        return 'audio/webm';
      case 'mp4':
      case 'm4a':
        return 'audio/mp4';
      case 'ogg':
        return 'audio/ogg';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      default:
        return 'audio/mp4';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
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
    if (_selectedStoryteller == null) return;
    setState(() => _isSaving = true);

    final localeTag = Localizations.localeOf(context).toString();
    final projectState = ref.read(projectNotifierProvider);
    final projectId = projectState.activeProject?.id ?? '';
    final currentUserId = ref.read(authNotifierProvider).currentUser?.id;

    if (kIsWeb) {
      await _saveWebDirect(projectId, currentUserId, localeTag);
      return;
    }

    final repo = ref.read(localRecordingRepositoryProvider);
    final syncNotifier = ref.read(syncNotifierProvider.notifier);
    final isOnline = ref.read(syncNotifierProvider).isOnline;

    int fileSize = 0;
    try {
      fileSize = await file_ops.fileLength(widget.result.filePath);
    } catch (_) {}

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
        storytellerId: Value(_selectedStoryteller!.id),
        userId: currentUserId != null
            ? Value(currentUserId)
            : const Value.absent(),
        title: Value(defaultRecordingTitle(locale: localeTag)),
        description: _descriptionController.text.trim().isNotEmpty
            ? Value(_descriptionController.text.trim())
            : const Value.absent(),
        durationSeconds: Value(widget.result.durationSeconds),
        fileSizeBytes: Value(fileSize),
        format: Value(widget.result.format),
        localFilePath: Value(widget.result.filePath),
        recordedAt: Value(DateTime.now()),
      ),
    );

    if (isOnline) {
      unawaited(syncNotifier.processQueue());
    }

    if (mounted) {
      HapticFeedback.mediumImpact();
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.recording_saved)));
      context.go('/home');
    }
  }

  Future<void> _saveWebDirect(
    String projectId,
    String? currentUserId,
    String localeTag,
  ) async {
    final l10n = AppLocalizations.of(context);
    final uploader = ref.read(directRecordingUploaderProvider);
    final localRepo = ref.read(localRecordingRepositoryProvider);
    try {
      final bytes = await file_ops.readFileBytes(widget.result.filePath);
      if (bytes.isEmpty) {
        throw Exception('Recording has no bytes');
      }

      final subcategoryId =
          widget.subcategoryId != null && widget.subcategoryId!.isNotEmpty
          ? widget.subcategoryId!
          : 'unclassified';
      final description = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();
      final recordedAt = DateTime.now();

      final serverId = await uploader.upload(
        bytes: bytes,
        meta: DirectUploadMetadata(
          projectId: projectId,
          genreId: widget.genreId,
          subcategoryId: subcategoryId,
          registerId: widget.registerId,
          storytellerId: _selectedStoryteller!.id,
          userId: currentUserId,
          title: defaultRecordingTitle(locale: localeTag),
          description: description,
          durationSeconds: widget.result.durationSeconds,
          fileSizeBytes: bytes.length,
          format: widget.result.format,
          recordedAt: recordedAt,
        ),
      );

      final localId =
          '${recordedAt.millisecondsSinceEpoch}_${widget.genreId.hashCode}';
      try {
        await localRepo.insertRecording(
          LocalRecordingsCompanion(
            id: Value(localId),
            projectId: Value(projectId),
            genreId: Value(widget.genreId),
            subcategoryId: Value(subcategoryId),
            registerId:
                widget.registerId != null && widget.registerId!.isNotEmpty
                ? Value(widget.registerId!)
                : const Value.absent(),
            storytellerId: Value(_selectedStoryteller!.id),
            userId: currentUserId != null
                ? Value(currentUserId)
                : const Value.absent(),
            title: Value(defaultRecordingTitle(locale: localeTag)),
            description: description != null
                ? Value(description)
                : const Value.absent(),
            durationSeconds: Value(widget.result.durationSeconds),
            fileSizeBytes: Value(bytes.length),
            format: Value(widget.result.format),
            localFilePath: const Value(''),
            uploadStatus: const Value('uploaded'),
            serverId: Value(serverId),
            recordedAt: Value(recordedAt),
          ),
        );
      } catch (_) {}

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.recording_saved)));
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        final friendly = friendlyErrorMessage(e.toString(), l10n);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.recording_uploadFailed(friendly))),
        );
        setState(() => _isSaving = false);
      }
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
      try {
        await file_ops.deleteFile(widget.result.filePath);
      } catch (_) {}

      if (mounted) {
        widget.onDiscard();
      }
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

              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: widget.genreId == kUnclassifiedGenreId
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.tag,
                              size: 12,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.quickRecord_classifyLater,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.amber.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : tagLabel.isNotEmpty
                    ? Container(
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
                      )
                    : const SizedBox.shrink(),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      _buildWaveformPlayer(colors, amplitudes),
                      const SizedBox(height: 6),
                      Text(
                        '${formatPositionMS(_position)} / ${formatDurationMinSec(widget.result.durationSeconds)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.secondary,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: _togglePlayback,
                  child: Container(
                    width: 56,
                    height: 56,
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
                      size: 24,
                    ),
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
                    StorytellerPicker(
                      projectId:
                          ref.read(projectNotifierProvider).activeProject?.id ??
                          '',
                      selected: _selectedStoryteller,
                      onChanged: (s) =>
                          setState(() => _selectedStoryteller = s),
                      showAddNew: true,
                    ),
                    if (_selectedStoryteller == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.storyteller_required,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.error,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: l10n.recording_descriptionHint,
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
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_isSaving || _selectedStoryteller == null)
                            ? null
                            : _save,
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
