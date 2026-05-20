import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/l10n/content_l10n.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/platform/file_ops.dart' as file_ops;

import '../../../../l10n/app_localizations.dart';
import '../../../core/database/app_database.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../auth/data/providers/role_provider.dart';
import '../../genre/presentation/notifiers/genre_notifier.dart';
import '../../project/presentation/notifiers/member_notifier.dart';
import '../../project/presentation/notifiers/stats_notifier.dart';
import '../../storyteller/data/providers.dart' as storyteller_providers;
import '../../storyteller/domain/entities/storyteller.dart';
import '../../sync/presentation/notifiers/sync_notifier.dart';
import '../../../shared/utils/format.dart';
import 'notifiers/recordings_list_notifier.dart';
import '../data/providers.dart';
import '../data/services/audio_exporter.dart';
import '../data/services/recording_trash.dart';
import '../data/services/waveform_extractor.dart';
import '../data/supported_audio_formats.dart';
import '../domain/entities/register.dart';
import '../domain/entities/server_recording.dart';
import '../domain/entities/classification.dart';
import 'widgets/classify_recording_dialog.dart';
import 'widgets/move_category_dialog.dart';
import 'widgets/secondary_classification_fields.dart';
import 'widgets/recording_hero_player.dart';
import 'widgets/recording_info_grid.dart';
import 'widgets/recording_quick_actions.dart';
import 'widgets/recording_status_section.dart';
import 'widgets/recording_description_section.dart';
import 'widgets/recording_storyteller_section.dart';
import 'widgets/recording_title_section.dart';
import '../data/use_cases/save_recording_title.dart';
import 'widgets/replace_audio_dialog.dart';

class RecordingDetailScreen extends ConsumerStatefulWidget {
  const RecordingDetailScreen({super.key, required this.recordingId});

  final String recordingId;

  @override
  ConsumerState<RecordingDetailScreen> createState() =>
      _RecordingDetailScreenState();
}

class _RecordingDetailScreenState extends ConsumerState<RecordingDetailScreen> {
  LocalRecording? _recording;
  bool _isLoading = true;
  bool _isEditingDescription = false;
  bool _isEditingTitle = false;
  Storyteller? _resolvedStoryteller;
  late TextEditingController _descriptionController;
  late TextEditingController _titleController;

  bool get _canEditRecording {
    final user = ref.read(authNotifierProvider).currentUser;
    if (user == null) return false;
    final recording = _recording;
    if (recording == null) return false;
    if (ref
        .read(roleNotifierProvider.notifier)
        .canManageProject(recording.projectId)) {
      return true;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _titleController = TextEditingController();
    Future.microtask(_loadRecording);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadRecording() async {
    setState(() => _isLoading = true);
    try {
      LocalRecording? recording;

      final isOnline = ref.read(syncNotifierProvider).isOnline;

      if (kIsWeb) {
        final apiRepo = ref.read(recordingApiRepositoryProvider);
        final server = await apiRepo.getRecording(widget.recordingId);
        recording = _serverToLocal(server);
      } else {
        final localRepo = ref.read(localRecordingRepositoryProvider);

        recording = await localRepo.getRecordingById(widget.recordingId);
        recording ??= await localRepo.getRecordingByServerId(
          widget.recordingId,
        );

        final localHasServerId =
            recording != null &&
            recording.serverId != null &&
            recording.serverId!.isNotEmpty;
        final needsGcsRefresh =
            recording != null &&
            (recording.gcsUrl == null || recording.gcsUrl!.isEmpty) &&
            (recording.uploadStatus == 'uploaded' ||
                recording.uploadStatus == 'verified');
        final needsUserRefresh =
            recording != null &&
            (recording.userId == null || recording.userId!.isEmpty);

        if (isOnline &&
            localHasServerId &&
            (needsGcsRefresh || needsUserRefresh)) {
          try {
            final apiRepo = ref.read(recordingApiRepositoryProvider);
            final server = await apiRepo.getRecording(recording.serverId!);
            final updates = LocalRecordingsCompanion(
              gcsUrl: server.gcsUrl != null && server.gcsUrl!.isNotEmpty
                  ? Value(server.gcsUrl!)
                  : const Value.absent(),
              uploadStatus: server.gcsUrl != null && server.gcsUrl!.isNotEmpty
                  ? Value(server.uploadStatus)
                  : const Value.absent(),
              userId: server.userId != null && server.userId!.isNotEmpty
                  ? Value(server.userId)
                  : const Value.absent(),
            );
            await localRepo.updateRecording(recording.id, updates);
            recording = await localRepo.getRecordingById(recording.id);
          } catch (_) {}
        }

        if (isOnline && recording == null) {
          try {
            final apiRepo = ref.read(recordingApiRepositoryProvider);
            final server = await apiRepo.getRecording(widget.recordingId);
            recording = _serverToLocal(server);
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _recording = recording;
          _descriptionController.text = recording?.description ?? '';
          _titleController.text = recording?.title ?? '';
          _isLoading = false;
        });
        if (isOnline && recording != null) {
          await ref
              .read(roleNotifierProvider.notifier)
              .fetchRoleForProject(recording.projectId);
          if (mounted) setState(() {});
        }
        if (recording != null) {
          await _resolveStoryteller(recording);
          await _ensureMembersLoaded(recording.projectId);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resolveStoryteller(LocalRecording recording) async {
    final id = recording.storytellerId;
    if (id == null || id.isEmpty) {
      if (mounted) setState(() => _resolvedStoryteller = null);
      return;
    }
    final localRepo = ref.read(
      storyteller_providers.localStorytellerRepositoryProvider,
    );
    final cached = await localRepo.getById(id);
    if (mounted && cached != null) {
      setState(() => _resolvedStoryteller = cached);
    }
    if (!ref.read(syncNotifierProvider).isOnline) return;
    try {
      final apiRepo = ref.read(
        storyteller_providers.storytellerApiRepositoryProvider,
      );
      final remote = await apiRepo.get(id);
      if (mounted) setState(() => _resolvedStoryteller = remote);
    } catch (_) {
      if (mounted && cached == null) {
        setState(() => _resolvedStoryteller = null);
      }
    }
  }

  Future<void> _ensureMembersLoaded(String projectId) async {
    if (ref.read(memberNotifierProvider).members.isEmpty &&
        ref.read(syncNotifierProvider).isOnline) {
      await ref.read(memberNotifierProvider.notifier).fetchMembers(projectId);
      if (mounted) setState(() {});
    }
  }

  Future<void> _onStorytellerChanged(Storyteller? storyteller) async {
    final recording = _recording;
    if (recording == null) return;
    final serverId = recording.serverId ?? recording.id;
    try {
      await ref
          .read(recordingApiRepositoryProvider)
          .updateRecording(serverId, storytellerId: storyteller?.id ?? '');
    } on Exception catch (_) {}
    if (!kIsWeb) {
      final repo = ref.read(localRecordingRepositoryProvider);
      await repo.updateRecording(
        recording.id,
        LocalRecordingsCompanion(
          storytellerId: storyteller == null
              ? const Value(null)
              : Value(storyteller.id),
        ),
      );
    }
    await _loadRecording();
  }

  static LocalRecording _serverToLocal(ServerRecording server) {
    return LocalRecording(
      id: server.id,
      projectId: server.projectId,
      genreId: server.genreId,
      subcategoryId: server.subcategoryId,
      registerId: server.registerId,
      secondaryGenreId: server.secondaryGenreId,
      secondarySubcategoryId: server.secondarySubcategoryId,
      secondaryRegisterId: server.secondaryRegisterId,
      storytellerId: server.storytellerId,
      userId: server.userId,
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
      splitFromId: server.splitFromId,
      splitIndex: server.splitIndex,
      splitSegmentCount: server.splitSegmentCount,
    );
  }

  Future<void> _saveDescription(String newDescription) async {
    final trimmed = newDescription.trim();
    if (trimmed == (_recording?.description ?? '')) {
      setState(() => _isEditingDescription = false);
      return;
    }

    if (kIsWeb) {
      final serverId = _recording?.serverId ?? widget.recordingId;
      await ref
          .read(recordingApiRepositoryProvider)
          .updateRecording(serverId, description: trimmed);
    } else {
      final repo = ref.read(localRecordingRepositoryProvider);
      await repo.updateRecording(
        widget.recordingId,
        LocalRecordingsCompanion(description: Value(trimmed)),
      );
    }
    await _loadRecording();
    setState(() => _isEditingDescription = false);
  }

  Future<void> _saveTitle(String newTitle) async {
    final l10n = AppLocalizations.of(context);
    final apiRepo = ref.read(recordingApiRepositoryProvider);
    final localRepo = kIsWeb
        ? null
        : ref.read(localRecordingRepositoryProvider);
    final isOnline = ref.read(syncNotifierProvider).isOnline;

    SaveTitleResult result;
    try {
      result = await saveRecordingTitle(
        recordingId: widget.recordingId,
        currentTitle: _recording?.title,
        serverId: _recording?.serverId,
        newTitle: newTitle,
        isWeb: kIsWeb,
        isOnline: isOnline,
        apiRepo: apiRepo,
        localRepo: localRepo,
      );
    } on ForbiddenException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.recording_updateNoPermission),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!mounted) return;

    switch (result) {
      case SaveTitleResult.emptyRejected:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.recording_titleRequired)));
        return;
      case SaveTitleResult.noChange:
        setState(() => _isEditingTitle = false);
        return;
      case SaveTitleResult.saved:
      case SaveTitleResult.savedLocallyOnly:
        await _loadRecording();
        ref
            .read(recordingsListNotifierProvider.notifier)
            .patchRecordingTitle(widget.recordingId, newTitle.trim());
        if (!mounted) return;
        setState(() => _isEditingTitle = false);
    }
  }

  Future<void> _toggleCleaningStatus() async {
    final recording = _recording;
    if (recording == null) return;

    final newStatus = recording.cleaningStatus == 'none'
        ? 'needs_cleaning'
        : 'none';

    final serverId = recording.serverId ?? recording.id;
    if (recording.uploadStatus == 'uploaded' || kIsWeb) {
      try {
        final apiRepo = ref.read(recordingApiRepositoryProvider);
        final success = await apiRepo.updateRecording(
          serverId,
          cleaningStatus: newStatus,
        );
        if (!success && mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.recording_cleaningStatusFailed)),
          );
          return;
        }
      } on ForbiddenException {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.recording_updateNoPermission),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      } catch (_) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.recording_cleaningStatusFailed)),
          );
        }
        return;
      }
    }

    if (!kIsWeb) {
      final repo = ref.read(localRecordingRepositoryProvider);
      await repo.updateRecording(
        widget.recordingId,
        LocalRecordingsCompanion(cleaningStatus: Value(newStatus)),
      );
    }
    await _loadRecording();
  }

  Future<void> _deleteRecording() async {
    final recording = _recording;
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

    final serverId = recording.serverId ?? recording.id;
    try {
      final apiRepo = ref.read(recordingApiRepositoryProvider);
      await apiRepo.deleteRecording(serverId);
    } on ForbiddenException {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.recording_deleteNoPermission),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    } catch (_) {
      if (kIsWeb) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.recording_deleteFailed)));
        }
        return;
      }
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.recording_deleteFailedLocal)),
        );
      }
    }

    if (!kIsWeb) {
      final repo = ref.read(localRecordingRepositoryProvider);
      await repo.deleteRecording(widget.recordingId);
    }

    if (ref.read(syncNotifierProvider).isOnline) {
      ref
          .read(statsNotifierProvider.notifier)
          .fetchGenreStats(recording.projectId);
    }

    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/recordings');
      }
    }
  }

  Future<bool> _ensureLocalFile(LocalRecording recording) async {
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      final response = await http.get(Uri.parse(recording.gcsUrl!));
      if (response.statusCode != 200) {
        throw Exception('Download failed (${response.statusCode})');
      }

      final docsDir = await getApplicationDocumentsDirectory();
      final ext = recording.format.isNotEmpty ? recording.format : 'm4a';
      final fileName =
          'recording_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final filePath = '${docsDir.path}/$fileName';
      await file_ops.writeFileBytes(filePath, response.bodyBytes);

      final repo = ref.read(localRecordingRepositoryProvider);
      final updated = await repo.updateRecording(
        recording.id,
        LocalRecordingsCompanion(localFilePath: Value(filePath)),
      );
      if (!updated) {
        await repo.insertRecording(
          LocalRecordingsCompanion(
            id: Value(recording.id),
            projectId: Value(recording.projectId),
            genreId: Value(recording.genreId),
            subcategoryId: recording.subcategoryId != null
                ? Value(recording.subcategoryId!)
                : const Value.absent(),
            registerId: recording.registerId != null
                ? Value(recording.registerId!)
                : const Value.absent(),
            title: Value(recording.title),
            durationSeconds: Value(recording.durationSeconds),
            fileSizeBytes: Value(recording.fileSizeBytes),
            format: Value(recording.format),
            localFilePath: Value(filePath),
            uploadStatus: Value(recording.uploadStatus),
            serverId: Value(recording.serverId ?? recording.id),
            gcsUrl: Value(recording.gcsUrl),
            cleaningStatus: Value(recording.cleaningStatus),
            recordedAt: Value(recording.recordedAt),
          ),
        );
      }

      await _loadRecording();
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.recording_downloadFailed(e.toString()))),
        );
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
    final recording = _recording;
    if (recording == null) return;

    if (kIsWeb && recording.serverId != null) {
      if (!mounted) return;
      context.push('/recording/${recording.serverId ?? recording.id}/trim');
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
    final recording = _recording;
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
      try {
        final response = await http.get(Uri.parse(gcsUrl));
        if (response.statusCode != 200) {
          throw Exception('Download failed (${response.statusCode})');
        }
        final tempPath =
            'export_${recording.id}_${DateTime.now().millisecondsSinceEpoch}'
            '.${recording.format}';
        await file_ops.writeFileBytes(tempPath, response.bodyBytes);
        final result = await AudioExporter.shareAudio(
          localFilePath: tempPath,
          suggestedName: suggestedName,
          sharePositionOrigin: _shareAnchorRect(),
        );
        if (mounted) Navigator.of(context).pop();
        if (!result.success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.error != null
                    ? '${l10n.recording_exportShareFailed}: ${result.error}'
                    : l10n.recording_exportShareFailed,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.recording_exportShareFailed}: $e')),
          );
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

    final fresh = _recording;
    if (fresh == null) return;
    final result = await AudioExporter.shareAudio(
      localFilePath: fresh.localFilePath,
      suggestedName: suggestedName,
      sharePositionOrigin: _shareAnchorRect(),
    );
    if (!result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.error != null
                ? '${l10n.recording_exportShareFailed}: ${result.error}'
                : l10n.recording_exportShareFailed,
          ),
        ),
      );
    }
  }

  Future<void> _handleReplaceAudio() async {
    final recording = _recording;
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${docsDir.path}/recordings');
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }
      final newName =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(pickedFile.name)}';
      final newPath = '${recordingsDir.path}/$newName';
      await file_ops.copyFile(pickedPath, newPath);
      final newSize = await file_ops.fileLength(newPath);

      final oldPath = fresh.localFilePath;
      if (oldPath.isNotEmpty) {
        await RecordingTrash.putInTrash(
          sourcePath: oldPath,
          metadata: {
            'recordingId': fresh.id,
            'format': fresh.format,
            'reason': 'replaced',
          },
        );
        WaveformExtractor.invalidate(oldPath);
      }

      final localRepo = ref.read(localRecordingRepositoryProvider);
      await localRepo.replaceAudio(
        recordingId: fresh.id,
        newFilePath: newPath,
        newDurationSeconds: duration,
        newFileSizeBytes: newSize,
      );

      if (wasUploaded) {
        final serverId = fresh.serverId ?? fresh.id;
        try {
          await ref
              .read(recordingApiRepositoryProvider)
              .updateRecording(
                serverId,
                durationSeconds: duration,
                fileSizeBytes: newSize,
              );
        } on Exception catch (e) {
          debugPrint('Replace: failed to sync new metadata to server: $e');
        }
        await ref.read(syncNotifierProvider.notifier).resetAndRetry(fresh.id);
      }

      await _loadRecording();
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.recording_replaceSuccess)));
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.recording_replaceFailed)));
      }
    }
  }

  Future<void> _moveCategory() async {
    final recording = _recording;
    if (recording == null) return;

    final result = await showDialog<MoveCategoryResult>(
      context: context,
      builder: (context) => MoveCategoryDialog(
        currentGenreId: recording.genreId,
        currentSubcategoryId: recording.subcategoryId,
        currentSecondaryGenreId: recording.secondaryGenreId,
        currentSecondarySubcategoryId: recording.secondarySubcategoryId,
        currentSecondaryRegisterId: recording.secondaryRegisterId,
      ),
    );

    if (result == null) return;

    final serverId = recording.serverId ?? recording.id;
    try {
      final apiRepo = ref.read(recordingApiRepositoryProvider);
      final success = await apiRepo.updateRecording(
        serverId,
        genreId: result.genreId,
        subcategoryId: result.subcategoryId,
        secondaryGenreId: result.secondaryGenreId,
        secondarySubcategoryId: result.secondarySubcategoryId,
        secondaryRegisterId: result.secondaryRegisterId,
        clearSecondary: result.clearSecondary,
      );
      if (!success && mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.recording_updateFailed)));
        return;
      }
    } on ForbiddenException {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.recording_moveNoPermission),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.recording_updateFailed)));
      }
      return;
    }

    if (!kIsWeb) {
      final repo = ref.read(localRecordingRepositoryProvider);
      await repo.updateRecording(
        recording.id,
        LocalRecordingsCompanion(
          genreId: Value(result.genreId),
          subcategoryId: Value(result.subcategoryId),
          secondaryGenreId: result.clearSecondary
              ? const Value(null)
              : Value(result.secondaryGenreId),
          secondarySubcategoryId: result.clearSecondary
              ? const Value(null)
              : Value(result.secondarySubcategoryId),
          secondaryRegisterId: result.clearSecondary
              ? const Value(null)
              : Value(result.secondaryRegisterId),
        ),
      );
    }

    if (ref.read(syncNotifierProvider).isOnline) {
      ref
          .read(statsNotifierProvider.notifier)
          .fetchGenreStats(recording.projectId);
    }

    await _loadRecording();

    if (mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.recording_movedSuccess)));
    }
  }

  Future<void> _classifyRecording() async {
    final recording = _recording;
    if (recording == null) return;

    final result = await showDialog<ClassifyResult>(
      context: context,
      builder: (context) => const ClassifyRecordingDialog(),
    );

    if (result == null) return;

    final hasServerId =
        recording.serverId != null && recording.serverId!.isNotEmpty;

    final clearSecondary =
        result.secondaryGenreId == null &&
        result.secondaryRegisterId == null &&
        (recording.secondaryGenreId != null ||
            recording.secondaryRegisterId != null);

    if (hasServerId) {
      try {
        final apiRepo = ref.read(recordingApiRepositoryProvider);
        final success = await apiRepo.updateRecording(
          recording.serverId!,
          genreId: result.genreId,
          subcategoryId: result.subcategoryId,
          registerId: result.registerId,
          secondaryGenreId: result.secondaryGenreId,
          secondarySubcategoryId: result.secondarySubcategoryId,
          secondaryRegisterId: result.secondaryRegisterId,
          clearSecondary: clearSecondary,
        );
        if (!success && mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.recording_updateFailed)));
          return;
        }
      } on ForbiddenException {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.recording_moveNoPermission),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      } catch (_) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.recording_updateFailed)));
        }
        return;
      }
    }

    if (!kIsWeb) {
      final repo = ref.read(localRecordingRepositoryProvider);
      await repo.updateRecording(
        recording.id,
        LocalRecordingsCompanion(
          genreId: Value(result.genreId),
          subcategoryId: Value(result.subcategoryId),
          registerId: result.registerId != null
              ? Value(result.registerId)
              : const Value.absent(),
          secondaryGenreId: Value(result.secondaryGenreId),
          secondarySubcategoryId: Value(result.secondarySubcategoryId),
          secondaryRegisterId: Value(result.secondaryRegisterId),
        ),
      );

      if (!hasServerId && ref.read(syncNotifierProvider).isOnline) {
        unawaited(ref.read(syncNotifierProvider.notifier).processQueue());
      }
    }

    if (ref.read(syncNotifierProvider).isOnline) {
      ref
          .read(statsNotifierProvider.notifier)
          .fetchGenreStats(recording.projectId);
    }

    await _loadRecording();

    if (mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.classify_success)));
    }
  }

  Future<void> _editSecondaryClassification() async {
    final recording = _recording;
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
    final recording = _recording;
    if (recording == null) return;
    final l10n = AppLocalizations.of(context);
    await _persistSecondary(
      recording: recording,
      values: null,
      successMessage: l10n.recording_secondaryRemoved,
    );
  }

  Future<void> _persistSecondary({
    required LocalRecording recording,
    required SecondaryValues? values,
    required String successMessage,
  }) async {
    final hasServerId =
        recording.serverId != null && recording.serverId!.isNotEmpty;
    final clearSecondary = values == null;

    if (hasServerId) {
      try {
        final apiRepo = ref.read(recordingApiRepositoryProvider);
        final success = await apiRepo.updateRecording(
          recording.serverId!,
          secondaryGenreId: values?.genreId,
          secondarySubcategoryId: values?.subcategoryId,
          secondaryRegisterId: values?.registerId,
          clearSecondary: clearSecondary,
        );
        if (!success && mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.recording_updateFailed)));
          return;
        }
      } on ForbiddenException {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.recording_moveNoPermission),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      } catch (_) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.recording_updateFailed)));
        }
        return;
      }
    }

    if (!kIsWeb) {
      final repo = ref.read(localRecordingRepositoryProvider);
      await repo.updateRecording(
        recording.id,
        LocalRecordingsCompanion(
          secondaryGenreId: Value(values?.genreId),
          secondarySubcategoryId: Value(values?.subcategoryId),
          secondaryRegisterId: Value(values?.registerId),
        ),
      );
    }

    await _loadRecording();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final recording = _recording;
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

    final titleAndGenre = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RecordingTitleSection(
          theme: theme,
          colors: colors,
          title: recording.title,
          isEditing: _isEditingTitle,
          controller: _titleController,
          onSave: _saveTitle,
          onCancel: () => setState(() {
            _isEditingTitle = false;
            _titleController.text = recording.title ?? '';
          }),
          onStartEdit: () {
            _titleController.text = recording.title ?? '';
            setState(() => _isEditingTitle = true);
          },
        ),
        const SizedBox(height: 8),
        RecordingDescriptionSection(
          theme: theme,
          colors: colors,
          description: recording.description,
          isEditing: _isEditingDescription,
          controller: _descriptionController,
          onSave: _saveDescription,
          onCancel: () => setState(() {
            _isEditingDescription = false;
            _descriptionController.text = recording.description ?? '';
          }),
          onStartEdit: () => setState(() => _isEditingDescription = true),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              isUnclassified ? LucideIcons.tag : LucideIcons.layers,
              size: 14,
              color: isUnclassified ? Colors.amber.shade700 : colors.accent,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                genreBreadcrumb,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isUnclassified ? Colors.amber.shade700 : colors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (registerName != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(LucideIcons.volume2, size: 14, color: colors.secondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  registerName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (!isUnclassified && hasSecondary) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colors.foreground.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.layers,
                  size: 13,
                  color: colors.foreground.withValues(alpha: 0.55),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.recording_alsoClassifiedAs,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.foreground.withValues(alpha: 0.55),
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (secondaryBreadcrumb.isNotEmpty)
                        Text(
                          secondaryBreadcrumb,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.foreground.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (secondaryRegisterName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.volume2,
                                size: 11,
                                color: colors.foreground.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  secondaryRegisterName,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colors.foreground.withValues(
                                      alpha: 0.65,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (_canEditRecording) ...[
                  IconButton(
                    icon: const Icon(LucideIcons.pencil, size: 14),
                    tooltip: l10n.classify_addAlternativeTitle,
                    color: colors.foreground.withValues(alpha: 0.6),
                    onPressed: _editSecondaryClassification,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 14),
                    tooltip: l10n.recording_removeSecondary,
                    color: colors.foreground.withValues(alpha: 0.6),
                    onPressed: _clearSecondaryClassification,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (!isUnclassified && !hasSecondary && _canEditRecording) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _editSecondaryClassification,
              icon: const Icon(LucideIcons.plus, size: 14),
              label: Text(l10n.recording_addAlternative),
              style: TextButton.styleFrom(
                foregroundColor: colors.foreground.withValues(alpha: 0.65),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: theme.textTheme.labelSmall,
              ),
            ),
          ),
        ],
        if (recording.splitFromId != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                LucideIcons.scissors,
                size: 13,
                color: colors.foreground.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  (recording.splitIndex != null &&
                          recording.splitSegmentCount != null)
                      ? l10n.recording_partOf(
                          recording.splitIndex! + 1,
                          recording.splitSegmentCount!,
                        )
                      : l10n.recording_splitFrom(recording.splitFromId ?? ''),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.foreground.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
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
              recording.uploadStatus == 'uploading' ||
              (recording.uploadStatus == 'local' && recording.retryCount > 0)
          ? () async {
              await ref
                  .read(syncNotifierProvider.notifier)
                  .resetAndRetry(recording.id);
              await _loadRecording();
            }
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

    final classifyBanner = isUnclassified
        ? Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.amber.shade700.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.alertCircle,
                  size: 18,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.classify_banner,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.amber.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: _classifyRecording,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber.shade700.withValues(
                      alpha: 0.15,
                    ),
                    foregroundColor: Colors.amber.shade700,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.classify_action,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          )
        : null;

    final storytellerSection = RecordingStorytellerSection(
      projectId: recording.projectId,
      storytellerId: recording.storytellerId,
      userId: recording.userId,
      resolvedStoryteller: _resolvedStoryteller,
      canEdit: _canEditRecording,
      onStorytellerChanged: _canEditRecording ? _onStorytellerChanged : null,
    );

    final detailContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (classifyBanner != null) ...[
          classifyBanner,
          const SizedBox(height: 16),
        ],
        titleAndGenre,
        const SizedBox(height: 20),
        storytellerSection,
        const SizedBox(height: 24),
        infoGrid,
        const SizedBox(height: 24),
        statusSection,
        const SizedBox(height: 24),
        quickActions,
      ],
    );

    final menuButton = _canEditRecording
        ? PopupMenuButton<String>(
            icon: Icon(LucideIcons.moreVertical, color: colors.foreground),
            onSelected: (value) {
              switch (value) {
                case 'trim':
                  _handleTrim();
                case 'export':
                  _handleExportAudio();
                case 'replace':
                  _handleReplaceAudio();
                case 'move':
                  _moveCategory();
                case 'classify':
                  _classifyRecording();
                case 'delete':
                  _deleteRecording();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'trim',
                child: Row(
                  children: [
                    const Icon(LucideIcons.scissors, size: 18),
                    const SizedBox(width: 12),
                    Text(l10n.recording_splitRecording),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(LucideIcons.share2, size: 18),
                    const SizedBox(width: 12),
                    Text(l10n.recording_exportAudio),
                  ],
                ),
              ),
              if (isUnclassified)
                PopupMenuItem(
                  value: 'classify',
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.tag,
                        size: 18,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(width: 12),
                      Text(l10n.classify_action),
                    ],
                  ),
                )
              else
                PopupMenuItem(
                  value: 'move',
                  child: Row(
                    children: [
                      const Icon(LucideIcons.folderInput, size: 18),
                      const SizedBox(width: 12),
                      Text(l10n.recording_moveCategory),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'replace',
                child: Row(
                  children: [
                    Icon(LucideIcons.refreshCw, size: 18, color: colors.error),
                    const SizedBox(width: 12),
                    Text(
                      l10n.recording_replaceAudio,
                      style: TextStyle(color: colors.error),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(LucideIcons.trash2, size: 18, color: colors.error),
                    const SizedBox(width: 12),
                    Text(
                      l10n.common_delete,
                      style: TextStyle(color: colors.error),
                    ),
                  ],
                ),
              ),
            ],
          )
        : null;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 700) {
            return Column(
              children: [
                AppBar(leading: const BackButton(), actions: [?menuButton]),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleAndGenre,
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  infoGrid,
                                  const SizedBox(height: 24),
                                  quickActions,
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
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
                  padding: const EdgeInsets.all(6),
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
                      padding: const EdgeInsets.only(right: 6),
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
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                  child: detailContent,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SecondaryEditDialog extends StatefulWidget {
  final String primaryGenreId;
  final SecondaryValues? initial;

  const _SecondaryEditDialog({required this.primaryGenreId, this.initial});

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
        (_values!.isValid && _values!.genreId != widget.primaryGenreId);
    final hasChanged =
        (_values?.genreId != widget.initial?.genreId) ||
        (_values?.subcategoryId != widget.initial?.subcategoryId) ||
        (_values?.registerId != widget.initial?.registerId);

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.layers, size: 20, color: colors.secondary),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.classify_addAlternativeTitle)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: SecondaryClassificationFields(
            primaryGenreId: widget.primaryGenreId,
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
