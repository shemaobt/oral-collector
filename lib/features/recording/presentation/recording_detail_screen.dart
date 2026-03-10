import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/audio_player_widget.dart';
import '../../../shared/widgets/upload_status_badge.dart';
import '../../auth/data/providers/auth_provider.dart';
import '../../genre/data/providers/genre_provider.dart';
import '../../project/data/providers/stats_provider.dart';
import '../../sync/data/providers/sync_provider.dart';
import '../data/providers/local_recording_repository_provider.dart';
import '../data/providers/recording_api_repository_provider.dart';
import 'widgets/move_category_dialog.dart';

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

  /// All local recordings are owned by the current user.
  /// Project Managers (role == 'project_manager') can also edit/delete.
  bool get _isOwnerOrManager {
    final user = ref.read(authNotifierProvider).currentUser;
    if (user == null) return false;
    // Local recordings are always created by the current user
    if (user.role == 'project_manager' || user.role == 'admin') return true;
    return true; // owner — all local recordings belong to current user
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
      final repo = ref.read(localRecordingRepositoryProvider);
      final recording = await repo.getRecordingById(widget.recordingId);
      if (mounted) {
        setState(() {
          _recording = recording;
          _titleController.text = recording?.title ?? '';
          _isLoading = false;
        });
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

    final newStatus =
        recording.cleaningStatus == 'none' ? 'needs_cleaning' : 'none';
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
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Delete from server if uploaded
    if (recording.uploadStatus == 'uploaded' && recording.serverId != null) {
      try {
        final apiRepo = ref.read(recordingApiRepositoryProvider);
        await apiRepo.deleteRecording(recording.serverId!);
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

    // Delete from local DB
    final repo = ref.read(localRecordingRepositoryProvider);
    await repo.deleteRecording(widget.recordingId);

    // Refresh genre stats
    ref.read(statsNotifierProvider.notifier).fetchGenreStats(recording.projectId);

    if (mounted) {
      context.pop();
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

    // Update on server if uploaded
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
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update on server')),
          );
        }
        return;
      }
    }

    // Update local DB
    final repo = ref.read(localRecordingRepositoryProvider);
    await repo.updateRecording(
      widget.recordingId,
      LocalRecordingsCompanion(
        genreId: Value(result.genreId),
        subcategoryId: Value(result.subcategoryId),
      ),
    );

    // Refresh genre stats (covers both old and new categories)
    ref.read(statsNotifierProvider.notifier).fetchGenreStats(recording.projectId);

    await _loadRecording();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording moved successfully')),
      );
    }
  }

  String _formatDuration(double totalSeconds) {
    final seconds = totalSeconds.round();
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h}h ${m}m ${s}s';
    }
    return '${m}m ${s}s';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year} '
        'at ${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Recording'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final recording = _recording;
    if (recording == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Recording'),
        ),
        body: const Center(child: Text('Recording not found')),
      );
    }

    final genreNotifier = ref.read(genreNotifierProvider.notifier);
    final genreName = genreNotifier.getGenreName(recording.genreId);
    final subcategoryName = recording.subcategoryId != null
        ? genreNotifier.getSubcategoryName(recording.subcategoryId!)
        : null;
    final breadcrumb = genreName != null
        ? subcategoryName != null
            ? '$genreName > $subcategoryName'
            : genreName
        : 'Unknown genre';

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(recording.title ?? 'Untitled'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Audio player (full size)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AudioPlayerWidget(
                  filePath: recording.localFilePath,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Metadata card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title (editable inline)
                    _buildTitleRow(theme, recording),
                    const Divider(height: 24),

                    // Genre > Subcategory
                    _buildMetadataRow(
                      theme,
                      icon: LucideIcons.layers,
                      label: 'Category',
                      value: breadcrumb,
                    ),
                    const SizedBox(height: 12),

                    // Duration
                    _buildMetadataRow(
                      theme,
                      icon: LucideIcons.clock,
                      label: 'Duration',
                      value: _formatDuration(recording.durationSeconds),
                    ),
                    const SizedBox(height: 12),

                    // Recorded date
                    _buildMetadataRow(
                      theme,
                      icon: LucideIcons.calendar,
                      label: 'Recorded',
                      value: _formatDate(recording.recordedAt),
                    ),
                    const SizedBox(height: 12),

                    // Upload status
                    _buildUploadStatusRow(theme, recording),
                    const SizedBox(height: 12),

                    // Cleaning status
                    _buildCleaningStatusRow(theme, recording),
                    const SizedBox(height: 12),

                    // File size
                    _buildMetadataRow(
                      theme,
                      icon: LucideIcons.hardDrive,
                      label: 'File Size',
                      value: _formatFileSize(recording.fileSizeBytes),
                    ),
                    const SizedBox(height: 12),

                    // Format
                    _buildMetadataRow(
                      theme,
                      icon: LucideIcons.fileAudio,
                      label: 'Format',
                      value: recording.format.toUpperCase(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow(ThemeData theme, LocalRecording recording) {
    if (_isEditingTitle) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Title',
                isDense: true,
              ),
              onSubmitted: _saveTitle,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(LucideIcons.check, color: AppColors.success),
            onPressed: () => _saveTitle(_titleController.text),
          ),
          IconButton(
            icon: Icon(LucideIcons.x, color: AppColors.error),
            onPressed: () => setState(() {
              _isEditingTitle = false;
              _titleController.text = recording.title ?? '';
            }),
          ),
        ],
      );
    }

    return InkWell(
      onTap: () => setState(() => _isEditingTitle = true),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(LucideIcons.type, size: 18, color: AppColors.border),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Title',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.foreground.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    recording.title ?? 'Untitled',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.pencil,
              size: 16,
              color: AppColors.foreground.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.border),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.foreground.withValues(alpha: 0.5),
                ),
              ),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadStatusRow(ThemeData theme, LocalRecording recording) {
    return Row(
      children: [
        Icon(LucideIcons.cloud, size: 18, color: AppColors.border),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload Status',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.foreground.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 2),
              UploadStatusBadge(
                status: recording.uploadStatus,
                onRetry: recording.uploadStatus == 'failed'
                    ? () => ref
                        .read(syncNotifierProvider.notifier)
                        .syncOne(recording.id)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCleaningStatusRow(ThemeData theme, LocalRecording recording) {
    final bool needsCleaning = recording.cleaningStatus != 'none' &&
        recording.cleaningStatus != 'cleaned';
    final String label;
    final Color color;
    final IconData icon;

    switch (recording.cleaningStatus) {
      case 'cleaned':
        label = 'Cleaned';
        color = AppColors.success;
        icon = LucideIcons.sparkles;
        break;
      case 'cleaning':
        label = 'Cleaning...';
        color = AppColors.info;
        icon = LucideIcons.loader;
        break;
      case 'needs_cleaning':
        label = 'Needs Cleaning';
        color = AppColors.primary;
        icon = LucideIcons.alertCircle;
        break;
      case 'failed':
        label = 'Cleaning Failed';
        color = AppColors.error;
        icon = LucideIcons.alertTriangle;
        break;
      default: // 'none'
        label = 'Not flagged';
        color = AppColors.border;
        icon = LucideIcons.minus;
    }

    return Row(
      children: [
        Icon(LucideIcons.sparkles, size: 18, color: AppColors.border),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cleaning Status',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.foreground.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Actions',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.foreground.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),

        // Trim recording
        OutlinedButton.icon(
          onPressed: () async {
            final result = await context.push<bool>(
              '/recording/${widget.recordingId}/trim',
            );
            if (result == true) {
              await _loadRecording();
            }
          },
          icon: const Icon(LucideIcons.scissors, size: 18),
          label: const Text('Trim Recording'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 8),

        // Mark/Clear Needs Cleaning toggle
        OutlinedButton.icon(
          onPressed: _toggleCleaningStatus,
          icon: Icon(
            _recording?.cleaningStatus == 'none' ||
                    _recording?.cleaningStatus == 'cleaned'
                ? LucideIcons.alertCircle
                : LucideIcons.checkCircle,
            size: 18,
          ),
          label: Text(
            _recording?.cleaningStatus == 'none' ||
                    _recording?.cleaningStatus == 'cleaned'
                ? 'Mark as Needs Cleaning'
                : 'Clear Cleaning Flag',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 8),

        // Move Category button (owner-only)
        if (_isOwnerOrManager)
          OutlinedButton.icon(
            onPressed: _moveCategory,
            icon: const Icon(LucideIcons.folderInput, size: 18),
            label: const Text('Move Category'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: BorderSide(
                  color: AppColors.secondary.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        if (_isOwnerOrManager) const SizedBox(height: 8),

        // Delete button (owner-only, red)
        if (_isOwnerOrManager)
          OutlinedButton.icon(
            onPressed: _deleteRecording,
            icon: const Icon(LucideIcons.trash2, size: 18),
            label: const Text('Delete Recording'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
      ],
    );
  }
}
