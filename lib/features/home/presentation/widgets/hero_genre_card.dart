import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/l10n/content_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/genre_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/utils/genre_helpers.dart';
import '../../../genre/domain/entities/genre.dart';
import '../../../project/domain/entities/stats.dart';
import 'genre_disc.dart';
import 'mini_stat_badge.dart';

class HeroGenreCard extends StatelessWidget {
  const HeroGenreCard({
    super.key,
    required this.genre,
    required this.onTap,
    this.genreStat,
  });

  final Genre genre;
  final GenreStat? genreStat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tone = GenreColors.of(context).forGenre(0, genre.id);
    final icon = mapGenreIcon(genre.icon);
    final count = genreStat?.recordingCount ?? 0;
    final dur = genreStat?.totalDurationSeconds ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingScale.s16,
        SpacingScale.s16,
        SpacingScale.s16,
        SpacingScale.s12,
      ),
      child: Container(
        decoration: genreCardDecoration(colors, tone, RadiusScale.r24),
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(RadiusScale.r24),
            child: Padding(
              padding: const EdgeInsets.all(SpacingScale.s20),
              child: Row(
                children: [
                  GenreDisc(tone: tone, icon: icon, size: 58, iconSize: 28),
                  const SizedBox(width: 18),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizedGenreName(l10n, genre.name, id: genre.id),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (genre.description != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            localizedGenreDescription(
                              l10n,
                              genre.description!,
                              id: genre.id,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.secondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: SpacingScale.s8),

                        Row(
                          children: [
                            MiniStatBadge(
                              icon: LucideIcons.mic,
                              text: '$count',
                              color: colors.secondary,
                              isDark: isDark,
                              bgBase: colors.card,
                            ),
                            const SizedBox(width: SpacingScale.s8),
                            MiniStatBadge(
                              icon: LucideIcons.clock,
                              text: formatDurationCompact(dur),
                              color: colors.secondary,
                              isDark: isDark,
                              bgBase: colors.card,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: colors.secondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
