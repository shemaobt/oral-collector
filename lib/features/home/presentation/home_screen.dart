import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/preview_helpers.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/sync_status_indicator.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../genre/presentation/notifiers/genre_notifier.dart';
import '../../project/presentation/notifiers/project_notifier.dart';
import '../../project/presentation/notifiers/stats_notifier.dart';
import 'notifiers/home_notifier.dart';
import 'widgets/genre_card.dart';
import 'widgets/hero_genre_card.dart';
import 'widgets/no_project_card.dart';
import 'widgets/record_fab.dart';
import 'widgets/project_switcher_sheet.dart';
import 'widgets/stats_strip.dart';

@Preview(name: 'Home Screen', wrapper: previewWrapper)
Widget homeScreenPreview() => const HomeScreen();

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(projectNotifierProvider.notifier).fetchProjects();
      ref.read(genreNotifierProvider.notifier).fetchGenres();
      _fetchStatsIfNeeded();
      ref.read(homeNotifierProvider.notifier).refreshAll();
    });
  }

  void _fetchStatsIfNeeded() {
    final activeProject = ref.read(projectNotifierProvider).activeProject;
    if (activeProject != null) {
      ref
          .read(statsNotifierProvider.notifier)
          .fetchGenreStats(activeProject.id);
    }
  }

  Future<void> _refresh() async {
    ref.read(genreNotifierProvider.notifier).invalidate();
    await Future.wait([
      ref.read(projectNotifierProvider.notifier).fetchProjects(),
      ref.read(genreNotifierProvider.notifier).fetchGenres(),
      ref.read(homeNotifierProvider.notifier).refreshAll(),
    ]);
    _fetchStatsIfNeeded();
  }

  void _showProjectSwitcher(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final projectState = ref.read(projectNotifierProvider);
    final projects = projectState.projects;
    final activeId = projectState.activeProject?.id;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return ProjectSwitcherSheet(
          projects: projects,
          activeProjectId: activeId,
          onProjectSelected: (project) {
            Navigator.pop(ctx);
            if (project.id != activeId) {
              ref
                  .read(projectNotifierProvider.notifier)
                  .setActiveProject(project);
            }
          },
          colors: colors,
          theme: theme,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectNotifierProvider);
    final genreState = ref.watch(genreNotifierProvider);
    final statsState = ref.watch(statsNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final homeState = ref.watch(homeNotifierProvider);
    final activeProject = projectState.activeProject;
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(projectNotifierProvider.select((s) => s.activeProject?.id), (
      prev,
      next,
    ) {
      if (next != null && next != prev) {
        ref.read(statsNotifierProvider.notifier).fetchGenreStats(next);
        ref.read(homeNotifierProvider.notifier).refreshAll();
      }
    });

    ref.listen(statsNotifierProvider.select((s) => s.genreStats), (_, _) {
      ref.read(homeNotifierProvider.notifier).computeTotals();
    });

    final totalRecordings = homeState.totalRecordings;
    final totalDuration = homeState.totalDuration;

    final user = authState.currentUser;
    final homeNotifier = ref.read(homeNotifierProvider.notifier);
    final greeting = homeNotifier.greetingFor(user?.displayName);

    final fabOffset = AppShell.fabBottomOffset(context);

    return Scaffold(
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: fabOffset - 70),
        child: RecordFab(
          onPressed: () => context.go('/record'),
          colors: colors,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.top + 16),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    UserAvatar(
                      radius: 21,
                      avatarUrl: user?.avatarUrl,
                      displayName: user?.displayName,
                      email: user?.email,
                    ),
                    const Spacer(),
                    const SyncStatusIndicator(),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting, style: theme.textTheme.headlineLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Let\'s share your stories today',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (activeProject != null) ...[
              SliverToBoxAdapter(
                child: Semantics(
                  label: 'Switch project',
                  button: projectState.projects.length > 1,
                  child: InkWell(
                    onTap: projectState.projects.length > 1
                        ? () => _showProjectSwitcher(context)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.folderOpen,
                            size: 18,
                            color: colors.accent,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              activeProject.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (activeProject.languageName != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(
                                  alpha: isDark ? 0.2 : 0.1,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                activeProject.languageName!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          if (projectState.projects.length > 1) ...[
                            const SizedBox(width: 6),
                            Icon(
                              LucideIcons.chevronDown,
                              size: 16,
                              color: colors.secondary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: StatsStrip(
                  totalRecordings: totalRecordings,
                  totalDuration: totalDuration,
                  memberCount: activeProject.memberCount,
                  colors: colors,
                ),
              ),
            ] else if (!projectState.isLoading)
              SliverToBoxAdapter(
                child: NoProjectCard(onBrowse: () => context.go('/projects')),
              ),

            if (projectState.isLoading && activeProject == null)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading projects...'),
                    ],
                  ),
                ),
              )
            else if (activeProject != null && genreState.genres.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: Row(
                    children: [
                      Text(
                        'Genres',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.foreground.withValues(
                            alpha: isDark ? 0.12 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${genreState.genres.length}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: HeroGenreCard(
                  genre: genreState.genres.first,
                  genreStat: statsState.genreStats[genreState.genres.first.id],
                  onTap: () =>
                      context.push('/genre/${genreState.genres.first.id}'),
                ),
              ),

              if (genreState.genres.length > 1)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    AppShell.scrollBottomPadding,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width >= 600
                          ? 3
                          : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.88,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final realIndex = index + 1;
                      final genre = genreState.genres[realIndex];
                      final stat = statsState.genreStats[genre.id];
                      return GenreCard(
                        genre: genre,
                        genreStat: stat,
                        colorIndex: realIndex,
                        onTap: () => context.push('/genre/${genre.id}'),
                      );
                    }, childCount: genreState.genres.length - 1),
                  ),
                ),
            ] else if (activeProject != null &&
                genreState.genres.isEmpty &&
                !genreState.isLoading)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.layoutGrid,
                        size: 56,
                        color: colors.secondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No genres available yet',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (genreState.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading genres...'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
