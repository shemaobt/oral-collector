import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/audio_player_widget.dart';
import '../../genre/data/providers/genre_provider.dart';
import '../../project/data/providers/project_provider.dart';
import '../data/providers/local_recording_repository_provider.dart';

/// Filter tabs for recording list.
enum _StatusFilter { all, pending, uploaded, needsCleaning }

class RecordingsListScreen extends ConsumerStatefulWidget {
  const RecordingsListScreen({super.key});

  @override
  ConsumerState<RecordingsListScreen> createState() =>
      _RecordingsListScreenState();
}

class _RecordingsListScreenState extends ConsumerState<RecordingsListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<LocalRecording> _recordings = [];
  bool _isLoading = true;
  String? _selectedGenreId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    Future.microtask(() {
      ref.read(genreNotifierProvider.notifier).fetchGenres();
      _loadRecordings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecordings() async {
    final projectState = ref.read(projectNotifierProvider);
    final projectId = projectState.activeProject?.id;
    if (projectId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(localRecordingRepositoryProvider);
      final recordings = await repo.getAllRecordings(projectId);
      if (mounted) {
        setState(() {
          _recordings = recordings;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<LocalRecording> get _filteredRecordings {
    var list = _recordings;

    // Apply genre filter
    if (_selectedGenreId != null) {
      list = list.where((r) => r.genreId == _selectedGenreId).toList();
    }

    // Apply status filter based on tab
    final filter = _StatusFilter.values[_tabController.index];
    switch (filter) {
      case _StatusFilter.all:
        break;
      case _StatusFilter.pending:
        list =
            list
                .where(
                  (r) =>
                      r.uploadStatus == 'local' ||
                      r.uploadStatus == 'failed' ||
                      r.uploadStatus == 'uploading',
                )
                .toList();
        break;
      case _StatusFilter.uploaded:
        list = list.where((r) => r.uploadStatus == 'uploaded').toList();
        break;
      case _StatusFilter.needsCleaning:
        list =
            list
                .where(
                  (r) =>
                      r.cleaningStatus == 'none' ||
                      r.cleaningStatus == 'failed',
                )
                .toList();
        break;
    }

    return list;
  }

  String _relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}w ago';
    return '${diff.inDays ~/ 30}mo ago';
  }

  String _formatDuration(double totalSeconds) {
    final seconds = totalSeconds.round();
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final genreState = ref.watch(genreNotifierProvider);
    final activeProject = ref.watch(
      projectNotifierProvider.select((s) => s.activeProject),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordings'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.foreground.withValues(alpha: 0.5),
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Uploaded'),
            Tab(text: 'Needs Cleaning'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Genre filter dropdown
          if (genreState.genres.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: DropdownButtonFormField<String>(
                value: _selectedGenreId,
                decoration: InputDecoration(
                  labelText: 'Filter by genre',
                  prefixIcon: const Icon(LucideIcons.filter, size: 18),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All genres'),
                  ),
                  ...genreState.genres.map(
                    (g) => DropdownMenuItem(value: g.id, child: Text(g.name)),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedGenreId = value);
                },
              ),
            ),

          // Recordings list
          Expanded(
            child:
                activeProject == null
                    ? _buildNoProject(theme)
                    : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                      onRefresh: _loadRecordings,
                      child: _buildList(theme),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoProject(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.folderOpen, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              'Select a project to view recordings',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.foreground.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/projects'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Browse Projects'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(ThemeData theme) {
    final filtered = _filteredRecordings;

    if (filtered.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: 400,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.mic, size: 64, color: AppColors.border),
                  const SizedBox(height: 16),
                  Text(
                    'No recordings yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.foreground.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start recording to see them here',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.foreground.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final recording = filtered[index];
        return _RecordingCard(
          recording: recording,
          genreName: ref
              .read(genreNotifierProvider.notifier)
              .getGenreName(recording.genreId),
          subcategoryName:
              recording.subcategoryId != null
                  ? ref
                      .read(genreNotifierProvider.notifier)
                      .getSubcategoryName(recording.subcategoryId!)
                  : null,
          relativeDate: _relativeDate(recording.recordedAt),
          formattedDuration: _formatDuration(recording.durationSeconds),
          onTap: () => context.go('/recording/${recording.id}'),
        );
      },
    );
  }
}

/// A card displaying a single recording with playback, genre breadcrumb, and status.
class _RecordingCard extends StatelessWidget {
  const _RecordingCard({
    required this.recording,
    required this.genreName,
    required this.relativeDate,
    required this.formattedDuration,
    required this.onTap,
    this.subcategoryName,
  });

  final LocalRecording recording;
  final String? genreName;
  final String? subcategoryName;
  final String relativeDate;
  final String formattedDuration;
  final VoidCallback onTap;

  Widget _buildUploadStatusBadge() {
    final IconData icon;
    final Color color;
    final String label;

    switch (recording.uploadStatus) {
      case 'uploaded':
        icon = LucideIcons.checkCircle;
        color = AppColors.success;
        label = 'Uploaded';
        break;
      case 'uploading':
        icon = LucideIcons.upload;
        color = AppColors.info;
        label = 'Uploading';
        break;
      case 'failed':
        icon = LucideIcons.cloudOff;
        color = AppColors.error;
        label = 'Failed';
        break;
      default: // 'local'
        icon = LucideIcons.smartphone;
        color = AppColors.border;
        label = 'Local';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final breadcrumb =
        genreName != null
            ? subcategoryName != null
                ? '$genreName > $subcategoryName'
                : genreName!
            : 'Unknown genre';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: title/breadcrumb + date
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recording.title ?? 'Untitled',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    relativeDate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.foreground.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Genre > Subcategory breadcrumb badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      breadcrumb,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildUploadStatusBadge(),
                ],
              ),
              const SizedBox(height: 8),

              // Compact audio player
              AudioPlayerWidget(
                filePath: recording.localFilePath,
                compact: true,
              ),

              const SizedBox(height: 4),

              // Bottom row: duration + file size
              Row(
                children: [
                  Icon(LucideIcons.clock, size: 12, color: AppColors.border),
                  const SizedBox(width: 4),
                  Text(
                    formattedDuration,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.foreground.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
