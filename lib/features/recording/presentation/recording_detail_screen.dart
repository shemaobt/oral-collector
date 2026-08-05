import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path/path.dart' as p;

import '../../../../core/l10n/content_l10n.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/platform/file_ops.dart' as file_ops;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/error_snack_bar.dart';
import '../../auth/data/providers/role_provider.dart';
import '../../genre/presentation/notifiers/genre_notifier.dart';
import '../../project/presentation/notifiers/stats_notifier.dart';
import '../../storyteller/domain/entities/storyteller.dart';
import '../../storyteller/presentation/widgets/storyteller_picker.dart';
import '../../sync/presentation/notifiers/sync_notifier.dart';
import '../data/services/audio_exporter.dart';
import '../data/supported_audio_formats.dart';
import '../domain/entities/classification.dart';
import '../domain/entities/local_recording_entity.dart';
import '../domain/entities/local_recording_entity_classification.dart';
import '../domain/entities/register.dart';
import '../domain/entities/review_pendency.dart';
import '../domain/recording_edit_policy.dart';
import 'notifiers/recording_detail_notifier.dart';
import 'notifiers/recording_detail_state.dart';
import 'notifiers/recordings_list_notifier.dart';
import 'widgets/classify_recording_dialog.dart';
import 'widgets/complete_ficha_overlay.dart';
import 'widgets/complete_ficha_sheet.dart';
import 'widgets/edit_recording_details_sheet.dart';
import 'widgets/move_category_dialog.dart';
import 'widgets/recording_action_menu.dart';
import 'widgets/recording_classification_section.dart';
import 'widgets/recording_hero_player.dart';
import 'widgets/recording_info_grid.dart';
import 'widgets/recording_quick_actions.dart';
import 'widgets/recording_status_section.dart';
import 'widgets/recording_storyteller_section.dart';
import 'widgets/recording_upload_banners.dart';
import 'widgets/recording_upload_progress_section.dart';
import 'widgets/replace_audio_dialog.dart';
import 'widgets/secondary_classification_fields.dart';

class RecordingDetailScreen extends ConsumerStatefulWidget {
  const RecordingDetailScreen({super.key, required this.recordingId});

  final String recordingId;

  @override
  ConsumerState<RecordingDetailScreen> createState() =>
      _RecordingDetailScreenState();
}

class _RecordingDetailScreenState extends ConsumerState<RecordingDetailScreen> {
  RecordingDetailNotifier get _notifier =>
      ref.read(recordingDetailProvider(widget.recordingId).notifier);
  RecordingDetailState get _state =>
      ref.read(recordingDetailProvider(widget.recordingId));

  bool get _canEditRecording {
    final recording = _state.recording;
    if (recording == null) return false;
    return canEditRecording(
      user: ref.read(authNotifierProvider).currentUser,
      canManageProject: ref
          .read(roleNotifierProvider.notifier)
          .canManageProject(recording.projectId),
      recordingUserId: recording.userId,
    );
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_notifier.load);
  }

  Future<void> _onStorytellerChanged(Storyteller? storyteller) async {
    final recording = _state.recording;
    if (recording == null) return;
    await _notifier.setStoryteller(recording, storyteller);
  }

  Future<void> _pickStoryteller() async {
    final recording = _state.recording;
    if (recording == null) return;
    final picked = await showStorytellerPickerSheet(
      context,
      projectId: recording.projectId,
      showAddNew: true,
    );
    if (picked == null) return;
    await _onStorytellerChanged(picked);
  }

  Future<void> _openEditDetails() async {
    final recording = _state.recording;
    if (recording == null) return;
    final result = await showEditRecordingDetailsSheet(
      context,
      initialTitle: recording.title ?? '',
      initialDescription: recording.description ?? '',
    );
    if (result == null || !mounted) return;

    final outcome = await _notifier.saveDetails(
      recording,
      title: result.title,
      description: result.description,
    );
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (outcome == RecordingMutationResult.forbidden) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.recording_updateNoPermission),
          backgroundColor: AppColors.of(context).warning,
        ),
      );
    } else if (outcome == RecordingMutationResult.titleConflict) {
      // The new name is taken too; the recording stays conflicted so the banner
      // keeps offering another rename.
      showErrorSnackBar(
        context,
        '',
        template: (_) => l10n.recording_duplicateTitleMessage(result.title),
      );
    }
  }

  Future<void> _toggleCleaningStatus() async {
    final recording = _state.recording;
    if (recording == null) return;
    final result = await _notifier.toggleCleaningStatus(recording);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    switch (result) {
      case RecordingMutationResult.forbidden:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.recording_updateNoPermission),
            backgroundColor: AppColors.of(context).warning,
          ),
        );
      // Only a title edit can clash; elsewhere it reads as a plain failure.
      case RecordingMutationResult.failed ||
          RecordingMutationResult.titleConflict:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.recording_cleaningStatusFailed)),
        );
      case RecordingMutationResult.success:
        break;
    }
  }

  Future<void> _deleteRecording() async {
    final recording = _state.recording;
    if (recording == null) return;

    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recording_deleteTitle),
        content: Text(l10n.recording_deleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: colors.error),
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ref
        .read(recordingsListNotifierProvider.notifier)
        .deleteRecording(recording);
    if (!mounted) return;
    switch (result) {
      case DeleteRecordingResult.forbidden:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.recording_deleteNoPermission),
            backgroundColor: AppColors.of(context).warning,
          ),
        );
        return;
      case DeleteRecordingResult.failed:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.recording_deleteFailed)));
        return;
      case DeleteRecordingResult.ok:
        break;
    }

    if (ref.read(syncNotifierProvider).isOnline) {
      unawaited(
        ref
            .read(statsNotifierProvider.notifier)
            .fetchGenreStats(recording.projectId),
      );
    }

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/recordings');
    }
  }

  Future<bool> _ensureLocalFile(LocalRecordingEntity recording) async {
    if (kIsWeb) return false;

    final hasLocal =
        recording.localFilePath.isNotEmpty &&
        await file_ops.fileExists(recording.localFilePath);
    if (hasLocal) return true;

    if (recording.gcsUrl == null || recording.gcsUrl!.isEmpty) return false;
    if (!mounted) return false;

    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final shouldDownload = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recording_downloadAudio),
        content: Text(l10n.recording_downloadAudioMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: colors.accent),
            child: Text(l10n.common_download),
          ),
        ],
      ),
    );

    if (shouldDownload != true || !mounted) return false;

    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    try {
      await _notifier.downloadAndCache(recording);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        showErrorSnackBar(context, e);
      }
      return false;
    }

    if (mounted) Navigator.of(context).pop();
    return true;
  }

  Rect? _shareAnchorRect() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  Future<double> _probeDuration(String filePath) async {
    final player = AudioPlayer();
    try {
      final duration = await player.setFilePath(filePath);
      if (duration != null) {
        return duration.inMilliseconds / 1000.0;
      }
    } catch (_) {
      return 0.0;
    } finally {
      await player.dispose();
    }
    return 0.0;
  }

  Future<void> _handleTrim() async {
    final recording = _state.recording;
    if (recording == null) return;

    if (kIsWeb && recording.serverId != null) {
      if (!mounted) return;
      unawaited(
        context.push('/recording/${recording.serverId ?? recording.id}/trim'),
      );
      return;
    }

    final hasLocalFile = await _ensureLocalFile(recording);
    if (!hasLocalFile) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.recording_audioNotAvailable)),
        );
      }
      return;
    }

    if (!mounted) return;
    final result = await context.push<bool>(
      '/recording/${widget.recordingId}/trim',
    );
    if (result == true) {
      if (mounted) {
        if (context.canPop()) {
          context.pop(true);
        } else {
          context.go('/recordings');
        }
      }
    }
  }

  Future<void> _handleExportAudio() async {
    final recording = _state.recording;
    if (recording == null) return;

    final l10n = AppLocalizations.of(context);
    final suggestedName =
        '${(recording.title ?? 'recording').trim().isEmpty ? 'recording' : recording.title!.trim()}'
        '.${recording.format}';

    if (kIsWeb) {
      final gcsUrl = recording.gcsUrl;
      if (gcsUrl == null || gcsUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.recording_audioNotAvailable)),
        );
        return;
      }
      unawaited(
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const PopScope(
            canPop: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
      try {
        final tempPath = await _notifier.downloadForExport(recording);
        final result = await AudioExporter.shareAudio(
          localFilePath: tempPath,
          suggestedName: suggestedName,
          sharePositionOrigin: _shareAnchorRect(),
        );
        if (mounted) Navigator.of(context).pop();
        if (!result.success && mounted) {
          // O motivo de AudioExporter é técnico/inglês (já registrado em log);
          // mapeá-lo dispararia ramos de import (ex.: "file not found"), então
          // ao usuário mostramos só a mensagem localizada de share.
          showErrorSnackBar(
            context,
            '',
            template: (_) => l10n.recording_exportShareFailed,
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop();
          showErrorSnackBar(context, e);
        }
      }
      return;
    }

    final hasLocalFile = await _ensureLocalFile(recording);
    if (!hasLocalFile) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.recording_audioNotAvailable)),
        );
      }
      return;
    }

    final fresh = _state.recording;
    if (fresh == null) return;
    final result = await AudioExporter.shareAudio(
      localFilePath: fresh.localFilePath,
      suggestedName: suggestedName,
      sharePositionOrigin: _shareAnchorRect(),
    );
    if (!result.success && mounted) {
      showErrorSnackBar(
        context,
        '',
        template: (_) => l10n.recording_exportShareFailed,
      );
    }
  }

  Future<void> _handleReplaceAudio() async {
    final recording = _state.recording;
    if (recording == null) return;

    final l10n = AppLocalizations.of(context);

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.recording_replaceNotAvailableWeb)),
      );
      return;
    }

    final fresh = recording;
    final wasUploaded =
        fresh.uploadStatus == 'uploaded' || fresh.uploadStatus == 'verified';

    if (!mounted) return;
    final confirmed = await ReplaceAudioDialog.show(
      context,
      wasUploaded: wasUploaded,
    );
    if (!confirmed || !mounted) return;

    FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: kSupportedAudioExtensions.toList(),
      );
    } catch (_) {
      picked = null;
    }
    if (picked == null || picked.files.isEmpty) return;

    final pickedFile = picked.files.first;
    final pickedPath = pickedFile.path;
    if (pickedPath == null) return;

    final pickedExt = p
        .extension(pickedFile.name)
        .replaceFirst('.', '')
        .toLowerCase();
    if (!kSupportedAudioExtensions.contains(pickedExt) ||
        pickedExt != fresh.format.toLowerCase()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.recording_replaceFormatMismatch(fresh.format, pickedExt),
            ),
          ),
        );
      }
      return;
    }

    final duration = await _probeDuration(pickedPath);
    if (duration <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.recording_replaceInvalidAudio)),
        );
      }
      return;
    }

    if (!mounted) return;
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    final ok = await _notifier.replaceAudio(
      fresh,
      sourcePath: pickedPath,
      fileName: pickedFile.name,
      durationSeconds: duration,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? l10n.recording_replaceSuccess : l10n.recording_replaceFailed,
        ),
      ),
    );
  }

  Future<void> _moveCategory() async {
    final recording = _state.recording;
    if (recording == null) return;

    final result = await showDialog<MoveCategoryResult>(
      context: context,
      builder: (context) => MoveCategoryDialog(
        currentGenreId: recording.genreId,
        currentSubcategoryId: recording.subcategoryId,
        currentPrimaryRegisterId: recording.registerId,
        currentSecondaryGenreId: recording.secondaryGenreId,
        currentSecondarySubcategoryId: recording.secondarySubcategoryId,
        currentSecondaryRegisterId: recording.secondaryRegisterId,
      ),
    );

    if (result == null) return;

    final outcome = await _notifier.moveCategory(recording, result);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    switch (outcome) {
      case RecordingMutationResult.forbidden:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.recording_moveNoPermission),
            backgroundColor: AppColors.of(context).warning,
          ),
        );
      // Only a title edit can clash; elsewhere it reads as a plain failure.
      case RecordingMutationResult.failed ||
          RecordingMutationResult.titleConflict:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.recording_updateFailed)));
      case RecordingMutationResult.success:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.recording_movedSuccess)));
    }
  }

  Future<void> _classifyRecording() async {
    final recording = _state.recording;
    if (recording == null) return;

    final result = await showDialog<ClassifyResult>(
      context: context,
      builder: (context) => const ClassifyRecordingDialog(),
    );

    if (result == null) return;

    final outcome = await _notifier.classify(recording, result);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    switch (outcome) {
      case RecordingMutationResult.forbidden:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.recording_moveNoPermission),
            backgroundColor: AppColors.of(context).warning,
          ),
        );
      // Only a title edit can clash; elsewhere it reads as a plain failure.
      case RecordingMutationResult.failed ||
          RecordingMutationResult.titleConflict:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.recording_updateFailed)));
      case RecordingMutationResult.success:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.classify_success)));
    }
  }

  Future<void> _editSecondaryClassification() async {
    final recording = _state.recording;
    if (recording == null) return;

    final l10n = AppLocalizations.of(context);
    final initial =
        (recording.secondaryGenreId != null &&
                recording.secondaryGenreId!.isNotEmpty) ||
            (recording.secondaryRegisterId != null &&
                recording.secondaryRegisterId!.isNotEmpty)
        ? SecondaryValues(
            genreId: recording.secondaryGenreId,
            subcategoryId: recording.secondarySubcategoryId,
            registerId: recording.secondaryRegisterId,
          )
        : null;

    final result = await showDialog<SecondaryValues?>(
      context: context,
      builder: (context) => _SecondaryEditDialog(
        primaryGenreId: recording.genreId,
        primarySubcategoryId: recording.subcategoryId,
        primaryRegisterId: recording.registerId,
        initial: initial,
      ),
    );

    if (result == null) return;

    await _persistSecondary(
      recording: recording,
      values: result.isEmpty ? null : result,
      successMessage: result.isEmpty
          ? l10n.recording_secondaryRemoved
          : l10n.recording_secondaryUpdated,
    );
  }

  Future<void> _clearSecondaryClassification() async {
    final recording = _state.recording;
    if (recording == null) return;
    final l10n = AppLocalizations.of(context);
    await _persistSecondary(
      recording: recording,
      values: null,
      successMessage: l10n.recording_secondaryRemoved,
    );
  }

  Future<void> _persistSecondary({
    required LocalRecordingEntity recording,
    required SecondaryValues? values,
    required String successMessage,
  }) async {
    final outcome = await _notifier.saveSecondary(recording, values);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    switch (outcome) {
      case RecordingMutationResult.forbidden:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.recording_moveNoPermission),
            backgroundColor: AppColors.of(context).warning,
          ),
        );
      // Only a title edit can clash; elsewhere it reads as a plain failure.
      case RecordingMutationResult.failed ||
          RecordingMutationResult.titleConflict:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.recording_updateFailed)));
      case RecordingMutationResult.success:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
    }
  }

  Future<void> _retryUpload() async {
    final recording = _state.recording;
    if (recording == null) return;
    await ref.read(syncNotifierProvider.notifier).resetAndRetry(recording.id);
    await _notifier.load();
  }

  Widget _completeFichaOverlay(LocalRecordingEntity recording) {
    return CompleteFichaOverlay(
      pendencyCount: recordingPendencies(recording).length,
      onTap: _openCompleteFichaSheet,
    );
  }

  Future<void> _openCompleteFichaSheet() async {
    final recording = _state.recording;
    if (recording == null) return;
    final steps = recordingPendencies(recording);
    if (steps.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      // The step list is frozen at open time so nothing shifts under the user's
      // finger; only what is still open is recomputed, to tick steps off as the
      // user comes back from each editor.
      builder: (_) => Consumer(
        builder: (context, sheetRef, _) {
          final current = sheetRef
              .watch(recordingDetailProvider(widget.recordingId))
              .recording;
          final open = current == null
              ? const <PendencyKind>[]
              : recordingPendencies(current);
          return CompleteFichaSheet(
            steps: steps,
            resolved: steps.where((step) => !open.contains(step)).toSet(),
            onStep: _onFichaStep,
          );
        },
      ),
    );
  }

  Future<void> _onFichaStep(PendencyKind kind) => switch (kind) {
    PendencyKind.classification => _classifyRecording(),
    PendencyKind.description => _openEditDetails(),
    PendencyKind.storyteller => _pickStoryteller(),
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordingDetailProvider(widget.recordingId));

    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final recording = state.recording;
    if (recording == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: Center(child: Text(l10n.recording_notFound)),
      );
    }

    final genreNotifier = ref.read(genreNotifierProvider.notifier);
    final rawGenreName = genreNotifier.getGenreName(recording.genreId);
    final rawSubcategoryName = recording.subcategoryId != null
        ? genreNotifier.getSubcategoryName(recording.subcategoryId!)
        : null;
    final rawRegisterName = getRegisterName(recording.registerId);

    final genreName = rawGenreName != null
        ? localizedGenreName(l10n, rawGenreName)
        : null;
    final subcategoryName = rawSubcategoryName != null
        ? localizedSubcategoryName(l10n, rawSubcategoryName)
        : null;
    final registerName = rawRegisterName != null
        ? localizedRegisterName(l10n, rawRegisterName)
        : null;

    final isUnclassified = recording.isUnclassified;
    final hasSecondary = recording.hasSecondary;

    final rawSecondaryGenreName = recording.secondaryGenreId != null
        ? genreNotifier.getGenreName(recording.secondaryGenreId!)
        : null;
    final rawSecondarySubcategoryName = recording.secondarySubcategoryId != null
        ? genreNotifier.getSubcategoryName(recording.secondarySubcategoryId!)
        : null;
    final rawSecondaryRegisterName = getRegisterName(
      recording.secondaryRegisterId,
    );
    final secondaryGenreName = rawSecondaryGenreName != null
        ? localizedGenreName(l10n, rawSecondaryGenreName)
        : null;
    final secondarySubcategoryName = rawSecondarySubcategoryName != null
        ? localizedSubcategoryName(l10n, rawSecondarySubcategoryName)
        : null;
    final secondaryRegisterName = rawSecondaryRegisterName != null
        ? localizedRegisterName(l10n, rawSecondaryRegisterName)
        : null;
    final secondaryBreadcrumbParts = <String>[];
    if (secondaryGenreName != null) {
      secondaryBreadcrumbParts.add(secondaryGenreName);
    }
    if (secondarySubcategoryName != null) {
      secondaryBreadcrumbParts.add(secondarySubcategoryName);
    }
    final secondaryBreadcrumb = secondaryBreadcrumbParts.join(' > ');

    final breadcrumbParts = <String>[];
    if (genreName != null) breadcrumbParts.add(genreName);
    if (subcategoryName != null) breadcrumbParts.add(subcategoryName);
    final genreBreadcrumb = isUnclassified
        ? l10n.recording_unclassified
        : breadcrumbParts.isNotEmpty
        ? breadcrumbParts.join(' > ')
        : l10n.recording_unknownGenre;

    final titleAndGenre = RecordingClassificationSection(
      recording: recording,
      theme: theme,
      colors: colors,
      genreBreadcrumb: genreBreadcrumb,
      registerName: registerName,
      isUnclassified: isUnclassified,
      hasSecondary: hasSecondary,
      secondaryBreadcrumb: secondaryBreadcrumb,
      secondaryRegisterName: secondaryRegisterName,
      canEdit: _canEditRecording,
      onEditDetails: _openEditDetails,
      onEditSecondary: _editSecondaryClassification,
      onClearSecondary: _clearSecondaryClassification,
    );

    final infoGrid = RecordingInfoGrid(
      recording: recording,
      colors: colors,
      theme: theme,
      formattedDuration: formatDurationLong(recording.durationSeconds),
      formattedDate: formatDateFull(recording.recordedAt),
      formattedSize: formatFileSize(recording.fileSizeBytes),
    );

    final statusSection = RecordingStatusSection(
      recording: recording,
      colors: colors,
      theme: theme,
      onToggleCleaning: _toggleCleaningStatus,
      onRetryUpload:
          recording.uploadStatus == 'failed' ||
              recording.uploadStatus == 'failed_exhausted' ||
              recording.uploadStatus == 'uploading' ||
              (recording.uploadStatus == 'local' && recording.retryCount > 0)
          ? _retryUpload
          : null,
    );

    final quickActions = RecordingQuickActions(
      recording: recording,
      colors: colors,
      theme: theme,
      canEdit: _canEditRecording,
      onTrim: _handleTrim,
      onToggleCleaning: _toggleCleaningStatus,
      onMoveCategory: isUnclassified ? _classifyRecording : _moveCategory,
      onDelete: _deleteRecording,
      isUnclassified: isUnclassified,
    );

    final banners = RecordingUploadBanners(
      recording: recording,
      canEdit: _canEditRecording,
      onEditDetails: _openEditDetails,
      onRetryUpload: _retryUpload,
      onDelete: _deleteRecording,
      onClearSecondary: _clearSecondaryClassification,
    );

    final storytellerSection = RecordingStorytellerSection(
      storytellerId: recording.storytellerId,
      userId: recording.userId,
      resolvedStoryteller: state.resolvedStoryteller,
      canEdit: _canEditRecording,
      onEditStoryteller: _canEditRecording ? _pickStoryteller : null,
    );

    final detailContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RecordingUploadProgressSection(recordingId: recording.id),
        banners,
        titleAndGenre,
        const SizedBox(height: SpacingScale.s20),
        storytellerSection,
        const SizedBox(height: SpacingScale.s24),
        infoGrid,
        const SizedBox(height: SpacingScale.s24),
        statusSection,
        const SizedBox(height: SpacingScale.s24),
        quickActions,
      ],
    );

    final menuButton = _canEditRecording
        ? RecordingActionMenu(
            colors: colors,
            isUnclassified: isUnclassified,
            onTrim: _handleTrim,
            onExport: _handleExportAudio,
            onReplace: _handleReplaceAudio,
            onMove: _moveCategory,
            onClassify: _classifyRecording,
            onDelete: _deleteRecording,
          )
        : null;

    return Scaffold(
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 700) {
                return Column(
                  children: [
                    AppBar(leading: const BackButton(), actions: [?menuButton]),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(SpacingScale.s24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleAndGenre,
                            const SizedBox(height: SpacingScale.s24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      infoGrid,
                                      const SizedBox(height: SpacingScale.s24),
                                      quickActions,
                                    ],
                                  ),
                                ),
                                const SizedBox(width: SpacingScale.s24),
                                Expanded(child: statusSection),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    Container(
                      decoration: BoxDecoration(
                        color: colors.card,
                        border: Border(
                          top: BorderSide(
                            color: colors.border.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                      child: RecordingHeroPlayer(
                        recording: recording,
                        colors: colors,
                        theme: theme,
                      ),
                    ),
                  ],
                );
              }

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 260,
                    pinned: true,
                    leading: Padding(
                      padding: const EdgeInsets.all(SpacingScale.s8),
                      child: Material(
                        color: colors.card.withValues(alpha: 0.6),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: BackButton(color: colors.foreground),
                      ),
                    ),
                    actions: [
                      if (menuButton != null)
                        Padding(
                          padding: const EdgeInsets.only(
                            right: SpacingScale.s8,
                          ),
                          child: Material(
                            color: colors.card.withValues(alpha: 0.6),
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: menuButton,
                          ),
                        ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: RecordingHeroPlayer(
                        recording: recording,
                        colors: colors,
                        theme: theme,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        SpacingScale.s20,
                        SpacingScale.s20,
                        SpacingScale.s20,
                        // Clears the floating "complete details" pill: it
                        // lives outside this scrollable, so without the
                        // reserve it covers the last card.
                        CompleteFichaOverlay.scrollReserve(context),
                      ),
                      child: detailContent,
                    ),
                  ),
                ],
              );
            },
          ),
          if (_canEditRecording) _completeFichaOverlay(recording),
        ],
      ),
    );
  }
}

class _SecondaryEditDialog extends StatefulWidget {
  final String primaryGenreId;
  final String? primarySubcategoryId;
  final String? primaryRegisterId;
  final SecondaryValues? initial;

  const _SecondaryEditDialog({
    required this.primaryGenreId,
    this.primarySubcategoryId,
    this.primaryRegisterId,
    this.initial,
  });

  @override
  State<_SecondaryEditDialog> createState() => _SecondaryEditDialogState();
}

class _SecondaryEditDialogState extends State<_SecondaryEditDialog> {
  SecondaryValues? _values;

  @override
  void initState() {
    super.initState();
    _values = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final hadInitial = widget.initial != null;
    final isValid =
        _values == null ||
        (_values!.isValid &&
            !secondaryEqualsPrimary(
              primaryRegisterId: widget.primaryRegisterId,
              primaryGenreId: widget.primaryGenreId,
              primarySubcategoryId: widget.primarySubcategoryId,
              secondaryRegisterId: _values!.registerId,
              secondaryGenreId: _values!.genreId,
              secondarySubcategoryId: _values!.subcategoryId,
            ));
    final hasChanged =
        (_values?.genreId != widget.initial?.genreId) ||
        (_values?.subcategoryId != widget.initial?.subcategoryId) ||
        (_values?.registerId != widget.initial?.registerId);

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.layers, size: 20, color: colors.secondary),
          const SizedBox(width: SpacingScale.s8),
          Expanded(child: Text(l10n.classify_addAlternativeTitle)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: SecondaryClassificationFields(
            primaryGenreId: widget.primaryGenreId,
            primarySubcategoryId: widget.primarySubcategoryId,
            primaryRegisterId: widget.primaryRegisterId,
            initial: widget.initial,
            onChanged: (v) => setState(() => _values = v),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.common_cancel),
        ),
        TextButton(
          onPressed: isValid && hasChanged
              ? () => Navigator.of(
                  context,
                ).pop(_values ?? const SecondaryValues())
              : null,
          child: Text(
            hadInitial && _values == null
                ? l10n.recording_removeSecondary
                : l10n.classify_action,
          ),
        ),
      ],
    );
  }
}
