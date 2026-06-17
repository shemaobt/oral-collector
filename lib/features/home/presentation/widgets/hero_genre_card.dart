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

  static const _heroColor = AppPalettes.heroGenreAccent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icon = mapGenreIcon(genre.icon);
    final count = genreStat?.recordingCount ?? 0;
    final dur = genreStat?.totalDurationSeconds ?? 0;

    final bg = Color.lerp(
      isDark ? colors.card : AppColors.white,
      _heroColor,
      isDark ? 0.22 : 0.22,
    )!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingScale.s16,
        14,
        SpacingScale.s16,
        SpacingScale.s12,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: isDark
              ? null
              : Border.all(color: _heroColor.withValues(alpha: 0.18)),
        ),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(SpacingScale.s20),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: (isDark ? colors.card : AppColors.white)
                          .withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, size: 28, color: _heroColor),
                  ),
                  const SizedBox(width: 18),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizedGenreName(l10n, genre.name),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (genre.description != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            localizedGenreDescription(l10n, genre.description!),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.secondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            MiniStatBadge(
                              icon: LucideIcons.mic,
                              text: '$count',
                              color: _heroColor,
                              isDark: isDark,
                              bgBase: isDark ? colors.card : AppColors.white,
                            ),
                            const SizedBox(width: SpacingScale.s8),
                            MiniStatBadge(
                              icon: LucideIcons.clock,
                              text: formatDurationCompact(dur),
                              color: _heroColor,
                              isDark: isDark,
                              bgBase: isDark ? colors.card : AppColors.white,
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
