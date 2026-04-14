import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/content_l10n.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
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
import '../data/providers.dart';
import '../domain/entities/register.dart';
import '../domain/entities/server_recording.dart';
import '../domain/entities/classification.dart';
import 'widgets/classify_recording_dialog.dart';
import 'widgets/move_category_dialog.dart';
import 'widgets/recording_hero_player.dart';
import 'widgets/recording_info_grid.dart';
import 'widgets/recording_quick_actions.dart';
import 'widgets/recording_status_section.dart';
import 'widgets/recording_description_section.dart';
import 'widgets/recording_storyteller_section.dart';

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
  Storyteller? _resolvedStoryteller;
  late TextEditingController _descriptionController;

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
    Future.microtask(_loadRecording);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
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

        if (isOnline &&
            recording != null &&
            (recording.gcsUrl == null || recording.gcsUrl!.isEmpty) &&
            (recording.uploadStatus == 'uploaded' ||
                recording.uploadStatus == 'verified') &&
            recording.serverId != null &&
            recording.serverId!.isNotEmpty) {
          try {
            final apiRepo = ref.read(recordingApiRepositoryProvider);
            final server = await apiRepo.getRecording(recording.serverId!);
            if (server.gcsUrl != null && server.gcsUrl!.isNotEmpty) {
              await localRepo.updateRecording(
                recording.id,
                LocalRecordingsCompanion(
                  gcsUrl: Value(server.gcsUrl!),
                  uploadStatus: Value(server.uploadStatus),
                ),
              );
              recording = await localRepo.getRecordingById(recording.id);
            }
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

  Future<void> _handleTrim() async {
    final recording = _recording;
    if (recording == null) return;

    bool hasLocalFile =
        !kIsWeb &&
        recording.localFilePath.isNotEmpty &&
        await file_ops.fileExists(recording.localFilePath);

    if (!mounted) return;

    if (kIsWeb && recording.serverId != null) {
      if (!mounted) return;
      context.push('/recording/${recording.serverId ?? recording.id}/trim');
      return;
    }

    if (!hasLocalFile && recording.gcsUrl != null) {
      final l10n = AppLocalizations.of(context);
      final shouldDownload = await showDialog<bool>(
        context: context,
        builder: (context) {
          final colors = AppColors.of(context);
          return AlertDialog(
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
          );
        },
      );

      if (shouldDownload != true || !mounted) return;

      if (!mounted) return;
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
        hasLocalFile = true;
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop();
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.recording_downloadFailed(e.toString())),
            ),
          );
        }
        return;
      }

      if (mounted) Navigator.of(context).pop();
    }

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

  Future<void> _moveCategory() async {
    final recording = _recording;
    if (recording == null) return;

    final result = await showDialog<MoveCategoryResult>(
      context: context,
      builder: (context) => MoveCategoryDialog(
        currentGenreId: recording.genreId,
        currentSubcategoryId: recording.subcategoryId,
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
        widget.recordingId,
        LocalRecordingsCompanion(
          genreId: Value(result.genreId),
          subcategoryId: Value(result.subcategoryId),
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

    if (!kIsWeb) {
      final repo = ref.read(localRecordingRepositoryProvider);
      await repo.updateRecording(
        widget.recordingId,
        LocalRecordingsCompanion(
          genreId: Value(result.genreId),
          subcategoryId: Value(result.subcategoryId),
          registerId: result.registerId != null
              ? Value(result.registerId)
              : const Value.absent(),
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
      ).showSnackBar(SnackBar(content: Text(l10n.classify_success)));
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
