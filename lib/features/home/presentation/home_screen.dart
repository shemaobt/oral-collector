import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../genre/data/providers/genre_provider.dart';
import '../../genre/domain/entities/genre.dart';
import '../../project/data/providers/project_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(projectNotifierProvider.notifier).fetchProjects();
      ref.read(genreNotifierProvider.notifier).fetchGenres();
    });
  }

  Future<void> _refresh() async {
    ref.read(genreNotifierProvider.notifier).invalidate();
    await Future.wait([
      ref.read(projectNotifierProvider.notifier).fetchProjects(),
      ref.read(genreNotifierProvider.notifier).fetchGenres(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectNotifierProvider);
    final genreState = ref.watch(genreNotifierProvider);
    final activeProject = projectState.activeProject;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/record'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(LucideIcons.mic),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            // Project header
            SliverToBoxAdapter(
              child: _ProjectHeader(
                projectName: activeProject?.name,
                languageName: activeProject?.languageName,
              ),
            ),

            // Genre grid
            if (genreState.isLoading && genreState.genres.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (activeProject == null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.folderOpen,
                          size: 64,
                          color: AppColors.border,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a project to get started',
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
                ),
              )
            else if (genreState.genres.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.layoutGrid,
                          size: 64,
                          color: AppColors.border,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No genres available',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.foreground.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width >= 900
                            ? 4
                            : MediaQuery.of(context).size.width >= 600
                                ? 3
                                : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final genre = genreState.genres[index];
                      return _GenreCard(
                        genre: genre,
                        onTap: () => context.go('/genre/${genre.id}'),
                      );
                    },
                    childCount: genreState.genres.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Header showing active project name, language badge, and sync status.
class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({
    this.projectName,
    this.languageName,
  });

  final String? projectName;
  final String? languageName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (projectName == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              projectName!,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (languageName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                languageName!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
          // Sync status indicator (placeholder — will be wired to sync provider)
          Icon(
            LucideIcons.cloudOff,
            size: 18,
            color: AppColors.border,
          ),
        ],
      ),
    );
  }
}

/// A card displaying a genre with icon, name, duration, and recording count.
class _GenreCard extends StatelessWidget {
  const _GenreCard({
    required this.genre,
    required this.onTap,
  });

  final Genre genre;
  final VoidCallback onTap;

  /// Map genre icon name strings to LucideIcons.
  IconData _mapIcon(String? iconName) {
    switch (iconName) {
      case 'book-open':
        return LucideIcons.bookOpen;
      case 'message-circle':
        return LucideIcons.messageCircle;
      case 'music':
        return LucideIcons.music;
      case 'users':
        return LucideIcons.users;
      case 'list-ordered':
        return LucideIcons.listOrdered;
      case 'heart':
        return LucideIcons.heart;
      case 'file-text':
        return LucideIcons.fileText;
      case 'megaphone':
        return LucideIcons.megaphone;
      case 'mic':
        return LucideIcons.mic;
      default:
        return LucideIcons.layoutGrid;
    }
  }

  /// Parse a hex color string like "#BE4A01" into a Color.
  Color _parseColor(String? hex) {
    if (hex == null || hex.length < 7) return AppColors.primary;
    try {
      final hexValue = hex.replaceFirst('#', '');
      return Color(int.parse('FF$hexValue', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _parseColor(genre.color);
    final icon = _mapIcon(genre.icon);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon in colored circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 10),

              // Genre name
              Text(
                genre.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),

              // Duration (placeholder until StatsProvider in US-030)
              Row(
                children: [
                  Icon(LucideIcons.clock, size: 14, color: AppColors.border),
                  const SizedBox(width: 4),
                  Text(
                    '0h 0m',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.foreground.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Recording count (placeholder until StatsProvider in US-030)
              Row(
                children: [
                  Icon(LucideIcons.mic, size: 14, color: AppColors.border),
                  const SizedBox(width: 4),
                  Text(
                    '0 recordings',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.foreground.withValues(alpha: 0.6),
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
