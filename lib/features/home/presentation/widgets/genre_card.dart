import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/utils/genre_helpers.dart';
import '../../../genre/domain/entities/genre.dart';
import '../../../project/domain/entities/stats.dart';

class GenreCard extends StatelessWidget {
  const GenreCard({
    super.key,
    required this.genre,
    required this.onTap,
    required this.colorIndex,
    this.genreStat,
  });

  final Genre genre;
  final GenreStat? genreStat;
  final int colorIndex;
  final VoidCallback onTap;

  static const _accents = [
    Color(0xFF3D8E80),
    Color(0xFFC25010),
    Color(0xFF5E7A2B),
    Color(0xFF9B7040),
    Color(0xFF4A7FA3),
    Color(0xFFD06835),
    Color(0xFF4E8A4A),
    Color(0xFF8B5E9B),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icon = mapGenreIcon(genre.icon);
    final accent = _accents[colorIndex % _accents.length];
    final count = genreStat?.recordingCount ?? 0;
    final dur = genreStat?.totalDurationSeconds ?? 0;

    final cardBg = Color.lerp(
      isDark ? colors.card : Colors.white,
      accent,
      isDark ? 0.18 : 0.11,
    )!;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isDark ? colors.card : Colors.white).withValues(
                    alpha: 0.80,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(height: 12),

              Text(
                genre.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),

              Row(
                children: [
                  Icon(LucideIcons.mic, size: 11, color: colors.secondary),
                  const SizedBox(width: 3),
                  Text(
                    '$count',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(LucideIcons.clock, size: 11, color: colors.secondary),
                  const SizedBox(width: 3),
                  Text(
                    formatDurationCompact(dur),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.secondary,
                      fontWeight: FontWeight.w600,
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
