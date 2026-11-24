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
    final icon = mapGenreIcon(genre.icon);
    final tone = GenreColors.of(context).forGenre(colorIndex, genre.id);
    final count = genreStat?.recordingCount ?? 0;
    final dur = genreStat?.totalDurationSeconds ?? 0;

    return Container(
      decoration: genreCardDecoration(colors, tone, RadiusScale.r20),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(RadiusScale.r20),
          child: Padding(
            padding: const EdgeInsets.all(SpacingScale.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GenreDisc(tone: tone, icon: icon, size: 44, iconSize: 20),
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
