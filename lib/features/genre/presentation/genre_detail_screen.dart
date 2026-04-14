import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/l10n/content_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/genre_helpers.dart';
import '../../../shared/widgets/status_banner.dart';
import '../../project/domain/entities/stats.dart';
import '../../project/presentation/notifiers/stats_notifier.dart';
import '../../sync/presentation/notifiers/sync_notifier.dart';
import 'notifiers/genre_notifier.dart';
import '../domain/entities/genre.dart';

class GenreDetailScreen extends ConsumerWidget {
  const GenreDetailScreen({super.key, required this.genreId});

  final String genreId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final genreState = ref.watch(genreNotifierProvider);
    final statsState = ref.watch(statsNotifierProvider);
    final genre = genreState.genres.where((g) => g.id == genreId).firstOrNull;
    final genreStat = statsState.genreStats[genreId];
    final syncState = ref.watch(syncNotifierProvider);
    final isOffline = !syncState.isOnline;
    final theme = Theme.of(context);

    if (genre == null) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.pop()),
          title: Text(l10n.genre_title),
        ),
        body: Center(child: Text(l10n.genre_notFound)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(localizedGenreName(l10n, genre.name)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.info.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.clock, size: 14, color: colors.secondary),
                const SizedBox(width: 4),
                Text(
                  formatDurationCompact(genreStat?.totalDurationSeconds ?? 0),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (isOffline) const StatusBanner.offline(),
          Expanded(
            child: genre.subcategories.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.layers,
                            size: 64,
                            color: colors.border,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No subcategories available',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colors.foreground.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: genre.subcategories.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final subcategory = genre.subcategories[index];
                      final subcatStat =
                          genreStat?.subcategories[subcategory.id];
                      return _SubcategoryCard(
                        subcategory: subcategory,
                        genreId: genreId,
                        genreColor: genre.color,
                        subcategoryStat: subcatStat,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SubcategoryCard extends StatelessWidget {
  const _SubcategoryCard({
    required this.subcategory,
    required this.genreId,
    this.genreColor,
    this.subcategoryStat,
  });

  final Subcategory subcategory;
  final String genreId;
  final String? genreColor;
  final SubcategoryStat? subcategoryStat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final color = parseHexColor(genreColor, colors.primary);

    final description = localizedSubcategoryDescription(l10n, subcategory.name);
    final recordingCount = subcategoryStat?.recordingCount ?? 0;
    final totalDurationSeconds = (subcategoryStat?.totalDurationSeconds ?? 0)
        .toDouble();

    final targetHours = subcategoryStat?.targetHours;
    final recordedHours = (subcategoryStat?.totalDurationSeconds ?? 0) / 3600.0;
    final progress = (targetHours != null && targetHours > 0)
        ? (recordedHours / targetHours).clamp(0.0, 1.0)
        : 0.0;

    final percentLabel = (progress * 100).round();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push(
            '/record-flow?genreId=$genreId&subcategoryId=${subcategory.id}',
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      backgroundColor: colors.border.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                    Text(
                      '$percentLabel%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            localizedSubcategoryName(l10n, subcategory.name),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        SizedBox(
                          width: 40,
                          height: 40,
                          child: IconButton(
                            onPressed: () {
                              context.push(
                                '/record-flow?genreId=$genreId&subcategoryId=${subcategory.id}',
                              );
                            },
                            icon: Icon(LucideIcons.mic, size: 18, color: color),
                            style: IconButton.styleFrom(
                              backgroundColor: color.withValues(alpha: 0.1),
                              shape: const CircleBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.secondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Icon(LucideIcons.clock, size: 14, color: colors.border),
                        const SizedBox(width: 4),
                        Text(
                          formatDurationCompact(totalDurationSeconds),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.foreground.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(LucideIcons.mic, size: 14, color: colors.border),
                        const SizedBox(width: 4),
                        Text(
                          l10n.genre_recordingCount(recordingCount),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.foreground.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
