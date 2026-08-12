import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/l10n/content_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palettes.dart';
import '../../../../core/theme/tokens.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icon = mapGenreIcon(genre.icon);
    final accent = AppPalettes.genreAccent(colorIndex);
    final count = genreStat?.recordingCount ?? 0;
    final dur = genreStat?.totalDurationSeconds ?? 0;

    final cardBg = Color.lerp(
      isDark ? colors.card : AppColors.white,
      accent,
      isDark ? 0.18 : 0.22,
    )!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RadiusScale.r20),
        border: isDark
            ? null
            : Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(RadiusScale.r20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(RadiusScale.r20),
          child: Padding(
            padding: const EdgeInsets.all(SpacingScale.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (isDark ? colors.card : AppColors.white).withValues(
                      alpha: 0.80,
                    ),
                    borderRadius: BorderRadius.circular(RadiusScale.r16),
                  ),
                  child: Icon(icon, size: 20, color: accent),
                ),
                const SizedBox(height: SpacingScale.s12),

                Text(
                  localizedGenreName(l10n, genre.name, id: genre.id),
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
                    const SizedBox(width: SpacingScale.s8),
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
      ),
    );
  }
}
