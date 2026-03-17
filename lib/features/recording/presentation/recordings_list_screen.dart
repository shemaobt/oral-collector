import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/preview_helpers.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/sync_status_indicator.dart';
import '../../genre/presentation/notifiers/genre_notifier.dart';
import '../../project/presentation/notifiers/project_notifier.dart';
import '../../sync/presentation/notifiers/sync_notifier.dart';
import 'notifiers/recordings_list_notifier.dart';
import 'widgets/genre_filter_bar.dart';
import 'widgets/recording_card.dart';
import 'widgets/status_filter_bar.dart';

@Preview(name: 'Recordings List', wrapper: previewWrapper)
Widget recordingsListPreview() => const RecordingsListScreen();

class RecordingsListScreen extends ConsumerStatefulWidget {
  const RecordingsListScreen({super.key});

  @override
  ConsumerState<RecordingsListScreen> createState() =>
      _RecordingsListScreenState();
}

class _RecordingsListScreenState extends ConsumerState<RecordingsListScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_refreshAll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAll();
    }
  }

  void _refreshAll() {
    ref.read(genreNotifierProvider.notifier).fetchGenres();
    ref.read(recordingsListNotifierProvider.notifier).fetchRecordings();
    ref.read(syncNotifierProvider.notifier).processQueue();
  }

  @override
  Widget build(BuildContext context) {
    // Refresh list when sync completes (lastSyncAt changes)
    ref.listen(syncNotifierProvider.select((s) => s.lastSyncAt), (_, _) {
      ref.read(recordingsListNotifierProvider.notifier).fetchRecordings();
    });

    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final genreState = ref.watch(genreNotifierProvider);
    final listState = ref.watch(recordingsListNotifierProvider);
    final filtered = listState.filteredRecordings;
    final activeProject = ref.watch(
      projectNotifierProvider.select((s) => s.activeProject),
    );

    final fabOffset = AppShell.fabBottomOffset(context);

    return Scaffold(
      floatingActionButton: activeProject != null
          ? Padding(
              padding: EdgeInsets.only(bottom: fabOffset - 70),
              child: Semantics(
                label: 'Import audio file',
                button: true,
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () => context.push('/import-file'),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.accent,
                            colors.accent.withValues(alpha: 0.85),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.accent.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: colors.accent.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.filePlus,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: activeProject == null
          ? EmptyState(
              icon: LucideIcons.folderOpen,
              title: 'Select a project',
              description: 'Choose a project to view its recordings',
              action: FilledButton.icon(
                onPressed: () => context.go('/projects'),
                icon: const Icon(LucideIcons.folderOpen, size: 18),
                label: const Text('Browse Projects'),
              ),
            )
          : CustomScrollView(
              slivers: [
                ScreenHeaderSliver(
                  title: 'Recordings',
                  subtitle: 'Your collected stories',
                  icon: LucideIcons.mic,
                  actions: const [SyncStatusIndicator()],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: StatusFilterBar(
                      colors: colors,
                      theme: theme,
                      currentFilter: ref.watch(
                        recordingsListNotifierProvider.select(
                          (s) => s.selectedFilter,
                        ),
                      ),
                      onFilterChanged: (filter) => ref
                          .read(recordingsListNotifierProvider.notifier)
                          .setStatusFilter(filter),
                    ),
                  ),
                ),

                if (genreState.genres.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: GenreFilterBar(
                        colors: colors,
                        theme: theme,
                        genres: genreState.genres,
                        selectedGenreId: ref.watch(
                          recordingsListNotifierProvider.select(
                            (s) => s.selectedGenreId,
                          ),
                        ),
                        onGenreSelected: (id) => ref
                            .read(recordingsListNotifierProvider.notifier)
                            .setGenreFilter(id),
                      ),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '${filtered.length} recording${filtered.length == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.secondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),

                listState.isLoading
                    ? const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : filtered.isEmpty
                    ? const SliverFillRemaining(
                        child: EmptyState(
                          icon: LucideIcons.mic,
                          title: 'No recordings yet',
                          description:
                              'Tap the microphone to record your first story, or import an audio file.',
                        ),
                      )
                    : SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          AppShell.scrollBottomPadding,
                        ),
                        sliver: SliverList.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final recording = filtered[index];
                            return RecordingCard(
                              recording: recording,
                              genreName: ref
                                  .read(genreNotifierProvider.notifier)
                                  .getGenreName(recording.genreId),
                              subcategoryName: recording.subcategoryId != null
                                  ? ref
                                        .read(genreNotifierProvider.notifier)
                                        .getSubcategoryName(
                                          recording.subcategoryId!,
                                        )
                                  : null,
                              relativeDate: formatTimeAgo(recording.recordedAt),
                              formattedDuration: formatDurationHMS(
                                recording.durationSeconds,
                              ),
                              onTap: () async {
                                await context.push(
                                  '/recording/${recording.id}',
                                );
                                ref
                                    .read(
                                      recordingsListNotifierProvider.notifier,
                                    )
                                    .fetchRecordings();
                              },
                            );
                          },
                        ),
                      ),
              ],
            ),
    );
  }
}
