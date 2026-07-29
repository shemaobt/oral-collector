import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/errors/app_exception.dart' show ConflictException;
import '../../../../core/platform/file_ops.dart' as file_ops;
import '../../../../core/platform/file_source.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/utils/recording_title.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/error_snack_bar.dart';
import '../../../../shared/widgets/waveform_visualizer.dart';
import '../../../project/presentation/notifiers/project_notifier.dart';
import '../../../storyteller/domain/entities/storyteller.dart';
import '../../../storyteller/presentation/notifiers/project_storytellers_notifier.dart';
import '../../../storyteller/presentation/widgets/storyteller_picker.dart';
import '../../../sync/presentation/notifiers/sync_notifier.dart';
import '../../data/providers.dart';
import '../../data/services/audio_probe.dart';
import '../../data/services/direct_recording_uploader.dart';
import '../../domain/entities/classification.dart';
import '../../domain/entities/local_recording_entity.dart';
import '../notifiers/recording_session_notifier.dart';
import '../notifiers/recording_session_state.dart';

/// Matches the 30 s `_apiTimeout` the upload paths use for their own API calls.
const _titleLookupTimeout = Duration(seconds: 30);

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
    this.onSaved,
    this.showReRecord = true,
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

  /// When set, runs instead of the default `go('/home')` after a successful
  /// save (crash-recovery uses it to mark the session recovered and route to
  /// the recordings list). When null, the normal new-recording flow applies.
  final VoidCallback? onSaved;

  /// Recovery has no segments to re-record, so the host hides the button.
  final bool showReRecord;

  @override
  ConsumerState<ConfirmationStep> createState() => _ConfirmationStepState();
}

class _ConfirmationStepState extends ConsumerState<ConfirmationStep> {
  static final _log = Logger('ConfirmationStep');

  final _descriptionController = TextEditingController();
  final _titleController = TextEditingController();
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  String? _playerBlobUrl;
  bool _isPlaying = false;
  bool _isSaving = false;
  Duration _position = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Storyteller? _selectedStoryteller;
  List<String?> _existingTitles = const [];
  bool _titleConflict = false;

  // Captured in initState so dispose() can clear the marker without touching
  // `ref` — flutter_riverpod 2.x invalidates `ref` before State.dispose runs
  // and any ref.read() in dispose throws "Cannot use ref after disposed",
  // which would leave the provider dirty and trip AppShell's discard dialog
  // on the next tab tap.
  late final StateController<RecordingResult?> _pendingDecisionController;

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
    _pendingDecisionController = ref.read(
      pendingRecordingDecisionProvider.notifier,
    );
    _initPlayer();
    Future.microtask(_prefetchStorytellers);
    Future.microtask(_loadExistingTitles);
    // Defer until after the current build/layout pass: Riverpod forbids
    // mutating providers inside widget lifecycle callbacks, and initState
    // runs inside a build when this widget is mounted under a LayoutBuilder
    // (the Scaffold body in QuickRecordingScreen does exactly that).
    Future.microtask(() {
      if (!mounted) return;
      _pendingDecisionController.state = widget.result;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_titleController.text.isEmpty) {
      final localeTag = Localizations.localeOf(context).toString();
      _titleController.text = defaultRecordingTitle(locale: localeTag);
    }
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

  /// The local half of the duplicate-title guard: the titles already stored on
  /// this device answer while the user types, and keep working offline where
  /// [_titleTakenOnServer] cannot. Skipped on web, where the local mirror is
  /// written best-effort and may not hold the project's recordings.
  Future<void> _loadExistingTitles() async {
    if (!mounted || kIsWeb) return;
    final projectId = ref.read(projectNotifierProvider).activeProject?.id;
    if (projectId == null || projectId.isEmpty) return;
    final recordings = await ref
        .read(localRecordingRepositoryProvider)
        .getAllRecordings(projectId);
    if (!mounted) return;
    setState(() {
      _existingTitles = recordings.map((r) => r.title).toList();
      _titleConflict = _titleTakenLocally(_titleController.text);
    });
  }

  /// Judges the title the save would actually persist, not the raw text: `_save`
  /// stores `resolveRecordingTitle(...)`, so comparing the raw value lets
  /// `"Taken "` slip past the inline warning and collide once trimmed.
  bool _titleTakenLocally(String value) =>
      isTitleTaken(_existingTitles, resolveRecordingTitle(value));

  void _onTitleChanged(String value) {
    final conflict = _titleTakenLocally(value);
    if (conflict != _titleConflict) {
      setState(() => _titleConflict = conflict);
    }
  }

  Future<void> _initPlayer() async {
    _player = AudioPlayer();
    _playerStateSub = _player!.playerStateStream.listen((playerState) {
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
    _positionSub = _player!.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);
    });
    _durationSub = _player!.durationStream.listen((dur) {
      if (!mounted || dur == null) return;
      setState(() => _totalDuration = dur);
    });
    try {
      if (kIsWeb) {
        final bytes = await file_ops.readFileBytes(widget.result.filePath);
        if (bytes.isEmpty) {
          _log.warning('Recording file is empty at ${widget.result.filePath}');
          return;
        }
        final mime = _mimeForFormat(widget.result.format);
        _playerBlobUrl = createPlayableBlobUrl(bytes, mime);
        await _player!.setUrl(_playerBlobUrl!);
      } else {
        final fileSize = await file_ops.fileLength(widget.result.filePath);
        if (fileSize <= 0) {
          _log.warning(
            'Recording file is 0 bytes at ${widget.result.filePath} — '
            'microphone likely did not capture audio.',
          );
          return;
        }
        await _player!.setFilePath(widget.result.filePath);
      }
    } catch (e, st) {
      _log.warning('Player load failed', e, st);
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
    _titleController.dispose();
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player?.dispose();
    final url = _playerBlobUrl;
    if (url != null) {
      revokePlayableBlobUrl(url);
      _playerBlobUrl = null;
    }
    // Identity equality is intentional here: if a successor widget has already
    // replaced the provider with its own RecordingResult, the references will
    // differ even when the values look similar, and we leave that successor's
    // marker untouched. RecordingResult does not override `==`, so this is
    // the same as `identical(...)`.
    //
    // Defer the actual mutation: dispose() runs inside finalizeTree, and
    // Riverpod refuses to notify listeners during a build phase. The
    // controller object outlives the widget, so the microtask can use it
    // safely.
    final controller = _pendingDecisionController;
    final ownedResult = widget.result;
    Future.microtask(() {
      if (controller.state == ownedResult) {
        controller.state = null;
      }
    });
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_player == null) return;
    unawaited(HapticFeedback.lightImpact());
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

  /// The backend deduplicates on (project_id, title), so a clash would silently
  /// overwrite the earlier recording. Best-effort by design: offline or on any
  /// API failure this answers false and the save proceeds untouched — losing a
  /// recording to a flaky lookup would be far worse than a late 409. The
  /// timeout is part of that: the save blocks on this answer, and the HTTP
  /// client only bounds the connect phase, so a connected-but-silent server
  /// would otherwise hold the spinner up forever.
  Future<bool> _titleTakenOnServer(String projectId, String title) async {
    if (projectId.isEmpty || !ref.read(syncNotifierProvider).isOnline) {
      return false;
    }
    try {
      final matches = await ref
          .read(recordingApiRepositoryProvider)
          .listRecordings(projectId, title: title, limit: 1)
          .timeout(_titleLookupTimeout);
      return isTitleTaken(matches.map((r) => r.title), title);
    } catch (_) {
      return false;
    }
  }

  void _showDuplicateTitleMessage(String title) {
    final l10n = AppLocalizations.of(context);
    showErrorSnackBar(
      context,
      '',
      template: (_) => l10n.recording_duplicateTitleMessage(title),
    );
  }

  Future<void> _save() async {
    if (_selectedStoryteller == null) return;
    setState(() => _isSaving = true);

    final localeTag = Localizations.localeOf(context).toString();
    final projectState = ref.read(projectNotifierProvider);
    final projectId = projectState.activeProject?.id ?? '';
    final currentUserId = ref.read(authNotifierProvider).currentUser?.id;
    final resolvedTitle = resolveRecordingTitle(
      _titleController.text,
      locale: localeTag,
    );

    if (await _titleTakenOnServer(projectId, resolvedTitle)) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showDuplicateTitleMessage(resolvedTitle);
      return;
    }
    if (!mounted) return;

    if (kIsWeb) {
      await _saveWebDirect(projectId, currentUserId, localeTag);
      return;
    }

    final repo = ref.read(localRecordingRepositoryProvider);
    final syncNotifier = ref.read(syncNotifierProvider.notifier);
    final isOnline = ref.read(syncNotifierProvider).isOnline;
    final l10n = AppLocalizations.of(context);

    int fileSize = 0;
    try {
      fileSize = await file_ops.fileLength(widget.result.filePath);
    } catch (_) {}

    final id =
        '${DateTime.now().millisecondsSinceEpoch}_${widget.genreId.hashCode}';
    final recordedAt = DateTime.now();

    try {
      await repo.saveRecording(
        LocalRecordingEntity(
          id: id,
          projectId: projectId,
          genreId: widget.genreId,
          storytellerId: _selectedStoryteller!.id,
          userId: currentUserId,
          title: resolvedTitle,
          description: _descriptionController.text.trim(),
          durationSeconds: widget.result.durationSeconds,
          fileSizeBytes: fileSize,
          format: widget.result.format,
          localFilePath: widget.result.filePath,
          recordedAt: recordedAt,
          subcategoryId: widget.subcategoryId,
          registerId: widget.registerId,
          uploadStatus: 'local',
          cleaningStatus: 'none',
          createdAt: recordedAt,
          retryCount: 0,
          uploadedBytes: 0,
        ),
      );

      if (isOnline) {
        unawaited(syncNotifier.processQueue());
      }

      if (mounted) {
        unawaited(HapticFeedback.mediumImpact());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.recording_saved)));
        if (widget.onSaved != null) {
          widget.onSaved!();
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e, template: l10n.recording_uploadFailed);
        setState(() => _isSaving = false);
      }
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
    final resolvedTitle = resolveRecordingTitle(
      _titleController.text,
      locale: localeTag,
    );
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

      final source = FileSource.fromBytes(
        bytes,
        name: widget.result.filePath,
        mimeType: _mimeForFormat(widget.result.format),
      );

      final serverId = await uploader.upload(
        source: source,
        meta: DirectUploadMetadata(
          projectId: projectId,
          genreId: widget.genreId,
          subcategoryId: subcategoryId,
          registerId: widget.registerId,
          storytellerId: _selectedStoryteller!.id,
          userId: currentUserId,
          title: resolvedTitle,
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
        await localRepo.saveRecording(
          LocalRecordingEntity(
            id: localId,
            projectId: projectId,
            genreId: widget.genreId,
            storytellerId: _selectedStoryteller!.id,
            userId: currentUserId,
            title: resolvedTitle,
            description: description,
            durationSeconds: widget.result.durationSeconds,
            fileSizeBytes: bytes.length,
            format: widget.result.format,
            localFilePath: '',
            recordedAt: recordedAt,
            subcategoryId: subcategoryId,
            registerId: widget.registerId,
            uploadStatus: 'uploaded',
            serverId: serverId,
            cleaningStatus: 'none',
            createdAt: recordedAt,
            retryCount: 0,
            uploadedBytes: 0,
          ),
        );
      } catch (_) {}

      if (mounted) {
        unawaited(HapticFeedback.mediumImpact());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.recording_saved)));
        context.go('/home');
      }
    } on ConflictException {
      if (mounted) {
        _showDuplicateTitleMessage(resolvedTitle);
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e, template: l10n.recording_uploadFailed);
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
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    final seed = widget.result.durationSeconds.hashCode;
    final amplitudes = List.generate(
      80,
      (i) => (0.15 + 0.7 * (((i * 7 + seed) * 13 + 3) % 17) / 16.0).clamp(
        0.1,
        0.9,
      ),
    );

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        unawaited(_discard());
      },
      child: SizedBox.expand(
        child: ColoredBox(
          color: colors.background,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: SpacingScale.s20),
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

                      _ClassificationTag(
                        genreId: widget.genreId,
                        genreName: widget.genreName,
                        subcategoryName: widget.subcategoryName,
                        registerName: widget.registerName,
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SpacingScale.s20,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: SpacingScale.s12),
                            _buildWaveformPlayer(colors, amplitudes),
                            const SizedBox(height: SpacingScale.s8),
                            Text(
                              '${formatPositionMS(_position)} / ${formatDurationMinSec(widget.result.durationSeconds)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.secondary,
                                fontFeatures: [
                                  const FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: SpacingScale.s12,
                        ),
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
                              color: AppColors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          SpacingScale.s20,
                          0,
                          SpacingScale.s20,
                          AppShell.scrollBottomPadding,
                        ),
                        child: Column(
                          children: [
                            _DetailsForm(
                              titleController: _titleController,
                              onTitleChanged: _onTitleChanged,
                              titleConflict: _titleConflict,
                              descriptionController: _descriptionController,
                              selectedStoryteller: _selectedStoryteller,
                              onStorytellerChanged: (s) =>
                                  setState(() => _selectedStoryteller = s),
                              projectId:
                                  ref
                                      .read(projectNotifierProvider)
                                      .activeProject
                                      ?.id ??
                                  '',
                            ),
                            const SizedBox(height: SpacingScale.s16),
                            _ActionButtons(
                              isSaving: _isSaving,
                              onSave:
                                  (_isSaving ||
                                      _selectedStoryteller == null ||
                                      _titleConflict)
                                  ? null
                                  : _save,
                              showReRecord: widget.showReRecord,
                              onReRecord: _isSaving
                                  ? null
                                  : () {
                                      _player?.stop();
                                      widget.onReRecord();
                                    },
                              onDiscard: _isSaving ? null : _discard,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                  barColor: colors.foreground.withValues(alpha: 0.3),
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

class _ClassificationTag extends StatelessWidget {
  const _ClassificationTag({
    required this.genreId,
    required this.genreName,
    required this.subcategoryName,
    required this.registerName,
  });

  final String genreId;
  final String? genreName;
  final String? subcategoryName;
  final String? registerName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    final tagParts = <String>[];
    if (genreName != null) tagParts.add(genreName!);
    if (subcategoryName != null) tagParts.add(subcategoryName!);
    if (registerName != null) tagParts.add(registerName!);
    final tagLabel = tagParts.join(' / ');

    return Padding(
      padding: const EdgeInsets.only(top: SpacingScale.s8),
      child: genreId == kUnclassifiedGenreId
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingScale.s12,
                vertical: SpacingScale.s4,
              ),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(RadiusScale.r16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.tag, size: 12, color: colors.warning),
                  const SizedBox(width: SpacingScale.s4),
                  Text(
                    l10n.quickRecord_classifyLater,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : tagLabel.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingScale.s12,
                vertical: SpacingScale.s4,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(RadiusScale.r16),
              ),
              child: Text(
                tagLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.secondary,
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _DetailsForm extends StatelessWidget {
  const _DetailsForm({
    required this.titleController,
    required this.onTitleChanged,
    required this.titleConflict,
    required this.descriptionController,
    required this.selectedStoryteller,
    required this.onStorytellerChanged,
    required this.projectId,
  });

  final TextEditingController titleController;
  final ValueChanged<String> onTitleChanged;
  final bool titleConflict;
  final TextEditingController descriptionController;
  final Storyteller? selectedStoryteller;
  final ValueChanged<Storyteller?> onStorytellerChanged;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            borderRadius: BorderRadius.circular(RadiusScale.r16),
          ),
          padding: const EdgeInsets.fromLTRB(
            SpacingScale.s16,
            SpacingScale.s8,
            SpacingScale.s16,
            SpacingScale.s8,
          ),
          child: Row(
            children: [
              Icon(LucideIcons.type, size: 20, color: colors.secondary),
              const SizedBox(width: SpacingScale.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.recording_title,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextField(
                      controller: titleController,
                      onChanged: onTitleChanged,
                      maxLines: 1,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colors.foreground,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: false,
                        fillColor: AppColors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (titleConflict)
          Padding(
            padding: const EdgeInsets.only(top: SpacingScale.s8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.recording_duplicateTitleTitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.error,
                ),
              ),
            ),
          ),
        const SizedBox(height: SpacingScale.s12),
        StorytellerPicker(
          projectId: projectId,
          selected: selectedStoryteller,
          onChanged: onStorytellerChanged,
          showAddNew: true,
        ),
        if (selectedStoryteller == null)
          Padding(
            padding: const EdgeInsets.only(top: SpacingScale.s8),
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
        const SizedBox(height: SpacingScale.s12),
        TextField(
          controller: descriptionController,
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
              borderRadius: BorderRadius.circular(RadiusScale.r12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RadiusScale.r12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RadiusScale.r12),
              borderSide: BorderSide(color: colors.accent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: SpacingScale.s16,
              vertical: SpacingScale.s16,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isSaving,
    required this.onSave,
    required this.showReRecord,
    required this.onReRecord,
    required this.onDiscard,
  });

  final bool isSaving;
  final VoidCallback? onSave;
  final bool showReRecord;
  final VoidCallback? onReRecord;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RadiusScale.r16),
              ),
              elevation: 0,
            ),
            child: isSaving
                ? const SizedBox(
                    width: SpacingScale.s20,
                    height: SpacingScale.s20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : Text(
                    l10n.recording_saveRecording,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        if (showReRecord) ...[
          const SizedBox(height: SpacingScale.s8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: onReRecord,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.border.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusScale.r16),
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
        ],
        const SizedBox(height: SpacingScale.s4),
        TextButton(
          onPressed: onDiscard,
          style: TextButton.styleFrom(foregroundColor: colors.error),
          child: Text(l10n.recording_discard),
        ),
      ],
    );
  }
}
