import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../project/data/providers/stats_provider.dart';
import '../data/providers/genre_provider.dart';
import '../domain/entities/genre.dart';

class GenreDetailScreen extends ConsumerWidget {
  const GenreDetailScreen({super.key, required this.genreId});

  final String genreId;

  String _formatDuration(double totalSeconds) {
    final seconds = totalSeconds.round();
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genreState = ref.watch(genreNotifierProvider);
    final statsState = ref.watch(statsNotifierProvider);
    final genre =
        genreState.genres.where((g) => g.id == genreId).firstOrNull;
    final genreStat = statsState.genreStats[genreId];
    final theme = Theme.of(context);

    if (genre == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Genre'),
        ),
        body: const Center(child: Text('Genre not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(genre.name),
        actions: [
          // Total genre duration badge
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.clock, size: 14, color: AppColors.secondary),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(genreStat?.totalDurationSeconds ?? 0),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: genre.subcategories.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.layers,
                      size: 64,
                      color: AppColors.border,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No subcategories available',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.foreground.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: genre.subcategories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
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
    final color = _parseColor(genreColor);

    final recordingCount = subcategoryStat?.recordingCount ?? 0;
    final durationSeconds = (subcategoryStat?.totalDurationSeconds ?? 0).round();
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;

    // Target progress (ratio of recorded hours to target hours)
    final targetHours = subcategoryStat?.targetHours;
    final recordedHours = (subcategoryStat?.totalDurationSeconds ?? 0) / 3600.0;
    final progress = (targetHours != null && targetHours > 0)
        ? (recordedHours / targetHours).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to recordings list filtered by this subcategory
          context.go('/recordings?genreId=$genreId&subcategoryId=${subcategory.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name and record button row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subcategory.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Small record button
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      onPressed: () {
                        // Navigate to recording flow pre-assigned to genre/subcategory
                        context.go(
                          '/record?genreId=$genreId&subcategoryId=${subcategory.id}',
                        );
                      },
                      icon: Icon(LucideIcons.mic, color: color),
                      style: IconButton.styleFrom(
                        backgroundColor: color.withValues(alpha: 0.1),
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
                ],
              ),

              // Description / prompt
              if (subcategory.description != null &&
                  subcategory.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subcategory.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Stats row: duration + recording count
              Row(
                children: [
                  Icon(LucideIcons.clock, size: 14, color: AppColors.border),
                  const SizedBox(width: 4),
                  Text(
                    '${hours}h ${minutes}m',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.foreground.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(LucideIcons.mic, size: 14, color: AppColors.border),
                  const SizedBox(width: 4),
                  Text(
                    '$recordingCount recordings',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.foreground.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Target progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.border.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
