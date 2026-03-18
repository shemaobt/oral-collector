import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/platform/file_ops.dart' as file_ops;

import '../../../core/database/app_database.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../auth/data/providers/role_provider.dart';
import '../../genre/presentation/notifiers/genre_notifier.dart';
import '../../project/presentation/notifiers/stats_notifier.dart';
import '../../sync/presentation/notifiers/sync_notifier.dart';
import '../../../shared/utils/format.dart';
import '../data/providers.dart';
import 'widgets/move_category_dialog.dart';
import 'widgets/recording_hero_player.dart';
import 'widgets/recording_info_grid.dart';
import 'widgets/recording_quick_actions.dart';
import 'widgets/recording_status_section.dart';
import 'widgets/recording_title_section.dart';

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
  bool _isEditingTitle = false;
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
    _titleController = TextEditingController();
    Future.microtask(_loadRecording);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadRecording() async {
    setState(() => _isLoading = true);
    try {
      final localRepo = ref.read(localRecordingRepositoryProvider);

      var recording = await localRepo.getRecordingById(widget.recordingId);
      recording ??= await localRepo.getRecordingByServerId(widget.recordingId);

      final isOnline = ref.read(syncNotifierProvider).isOnline;

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
          recording = LocalRecording(
            id: server.id,
            projectId: server.projectId,
            genreId: server.genreId,
            subcategoryId: server.subcategoryId,
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
          );
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _recording = recording;
          _titleController.text = recording?.title ?? '';
          _isLoading = false;
        });
        if (isOnline && recording != null) {
          await ref
              .read(roleNotifierProvider.notifier)
              .fetchRoleForProject(recording.projectId);
          if (mounted) setState(() {});
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTitle(String newTitle) async {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty || trimmed == _recording?.title) {
      setState(() => _isEditingTitle = false);
      return;
    }

    final repo = ref.read(localRecordingRepositoryProvider);
    await repo.updateRecording(
      widget.recordingId,
      LocalRecordingsCompanion(title: Value(trimmed)),
    );
    await _loadRecording();
    setState(() => _isEditingTitle = false);
  }

  Future<void> _toggleCleaningStatus() async {
    final recording = _recording;
    if (recording == null) return;

    final newStatus = recording.cleaningStatus == 'none'
        ? 'needs_cleaning'
        : 'none';

    if (recording.uploadStatus == 'uploaded' && recording.serverId != null) {
      try {
        final apiRepo = ref.read(recordingApiRepositoryProvider);
        final success = await apiRepo.updateRecording(
          recording.serverId!,
          cleaningStatus: newStatus,
        );
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update cleaning status on server'),
            ),
          );
          return;
        }
      } on ForbiddenException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You do not have permission to update this recording',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update cleaning status on server'),
            ),
          );
        }
        return;
      }
    }

    final repo = ref.read(localRecordingRepositoryProvider);
    await repo.updateRecording(
      widget.recordingId,
      LocalRecordingsCompanion(cleaningStatus: Value(newStatus)),
    );
    await _loadRecording();
  }

  Future<void> _deleteRecording() async {
    final recording = _recording;
    if (recording == null) return;

    final colors = AppColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording'),
        content: const Text(
          'This will permanently delete this recording from your device. '
          'If it has been uploaded, it will also be removed from the server. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: colors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (recording.uploadStatus == 'uploaded' && recording.serverId != null) {
      try {
        final apiRepo = ref.read(recordingApiRepositoryProvider);
        await apiRepo.deleteRecording(recording.serverId!);
      } on ForbiddenException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You do not have permission to delete this recording',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete from server. Removing locally.'),
            ),
          );
        }
      }
    }

    final repo = ref.read(localRecordingRepositoryProvider);
    await repo.deleteRecording(widget.recordingId);

    if (ref.read(syncNotifierProvider).isOnline) {
      ref
          .read(statsNotifierProvider.notifier)
          .fetchGenreStats(recording.projectId);
    }

    if (mounted) {
      context.pop();
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
      final shouldDownload = await showDialog<bool>(
        context: context,
        builder: (context) {
          final colors = AppColors.of(context);
          return AlertDialog(
            title: const Text('Download Audio'),
            content: const Text(
              'The audio file is not stored on this device. '
              'Would you like to download it to trim?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(backgroundColor: colors.accent),
                child: const Text('Download'),
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
          // Server-only recording — insert into local DB so the file path persists
          await repo.insertRecording(
            LocalRecordingsCompanion(
              id: Value(recording.id),
              projectId: Value(recording.projectId),
              genreId: Value(recording.genreId),
              subcategoryId: recording.subcategoryId != null
                  ? Value(recording.subcategoryId!)
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to download: $e')));
        }
        return;
      }

      if (mounted) Navigator.of(context).pop();
    }

    if (!hasLocalFile) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio file not available')),
        );
      }
      return;
    }

    if (!mounted) return;
    final result = await context.push<bool>(
      '/recording/${widget.recordingId}/trim',
    );
    if (result == true) {
      if (mounted) context.pop(true);
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

    if (recording.uploadStatus == 'uploaded' && recording.serverId != null) {
      try {
        final apiRepo = ref.read(recordingApiRepositoryProvider);
        final success = await apiRepo.updateRecording(
          recording.serverId!,
          genreId: result.genreId,
          subcategoryId: result.subcategoryId,
        );
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update on server')),
          );
          return;
        }
      } on ForbiddenException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You do not have permission to move this recording',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update on server')),
          );
        }
        return;
      }
    }

    final repo = ref.read(localRecordingRepositoryProvider);
    await repo.updateRecording(
      widget.recordingId,
      LocalRecordingsCompanion(
        genreId: Value(result.genreId),
        subcategoryId: Value(result.subcategoryId),
      ),
    );

    if (ref.read(syncNotifierProvider).isOnline) {
      ref
          .read(statsNotifierProvider.notifier)
          .fetchGenreStats(recording.projectId);
    }

    await _loadRecording();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording moved successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

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
        body: const Center(child: Text('Recording not found')),
      );
    }

    final genreNotifier = ref.read(genreNotifierProvider.notifier);
    final genreName = genreNotifier.getGenreName(recording.genreId);
    final subcategoryName = recording.subcategoryId != null
        ? genreNotifier.getSubcategoryName(recording.subcategoryId!)
        : null;

    return Scaffold(
      body: CustomScrollView(
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
              if (_canEditRecording)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Material(
                    color: colors.card.withValues(alpha: 0.6),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        LucideIcons.moreVertical,
                        color: colors.foreground,
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'trim':
                            _handleTrim();
                            break;
                          case 'move':
                            _moveCategory();
                            break;
                          case 'delete':
                            _deleteRecording();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'trim',
                          child: Row(
                            children: [
                              Icon(LucideIcons.scissors, size: 18),
                              SizedBox(width: 12),
                              Text('Split Recording'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'move',
                          child: Row(
                            children: [
                              Icon(LucideIcons.folderInput, size: 18),
                              SizedBox(width: 12),
                              Text('Move Category'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.trash2,
                                size: 18,
                                color: colors.error,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Delete',
                                style: TextStyle(color: colors.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RecordingTitleSection(
                    theme: theme,
                    colors: colors,
                    recording: recording,
                    isEditingTitle: _isEditingTitle,
                    titleController: _titleController,
                    onSave: _saveTitle,
                    onCancel: () => setState(() {
                      _isEditingTitle = false;
                      _titleController.text = recording.title ?? '';
                    }),
                    onStartEdit: () => setState(() => _isEditingTitle = true),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Icon(LucideIcons.layers, size: 14, color: colors.accent),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          genreName != null
                              ? subcategoryName != null
                                    ? '$genreName > $subcategoryName'
                                    : genreName
                              : 'Unknown genre',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  RecordingInfoGrid(
                    recording: recording,
                    colors: colors,
                    theme: theme,
                    formattedDuration: formatDurationLong(
                      recording.durationSeconds,
                    ),
                    formattedDate: formatDateFull(recording.recordedAt),
                    formattedSize: formatFileSize(recording.fileSizeBytes),
                  ),
                  const SizedBox(height: 24),

                  RecordingStatusSection(
                    recording: recording,
                    colors: colors,
                    theme: theme,
                    onToggleCleaning: _toggleCleaningStatus,
                    onRetryUpload:
                        recording.uploadStatus == 'failed' ||
                            recording.uploadStatus == 'uploading' ||
                            (recording.uploadStatus == 'local' &&
                                recording.retryCount > 0)
                        ? () async {
                            await ref
                                .read(syncNotifierProvider.notifier)
                                .resetAndRetry(recording.id);
                            await _loadRecording();
                          }
                        : null,
                  ),
                  const SizedBox(height: 24),

                  RecordingQuickActions(
                    recording: recording,
                    colors: colors,
                    theme: theme,
                    canEdit: _canEditRecording,
                    onTrim: _handleTrim,
                    onToggleCleaning: _toggleCleaningStatus,
                    onMoveCategory: _moveCategory,
                    onDelete: _deleteRecording,
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
