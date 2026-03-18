import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/l10n/content_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../genre/domain/entities/genre.dart';
import 'genre_filter_chip.dart';

class GenreFilterBar extends StatelessWidget {
  const GenreFilterBar({
    super.key,
    required this.colors,
    required this.theme,
    required this.genres,
    required this.selectedGenreId,
    required this.onGenreSelected,
  });

  final AppColorSet colors;
  final ThemeData theme;
  final List<Genre> genres;
  final String? selectedGenreId;
  final ValueChanged<String?> onGenreSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          GenreFilterChip(
            label: l10n.filter_allGenres,
            isSelected: selectedGenreId == null,
            colors: colors,
            theme: theme,
            onTap: () => onGenreSelected(null),
          ),
          ...genres.map(
            (g) => Padding(
              padding: const EdgeInsets.only(left: 6),
              child: GenreFilterChip(
                label: localizedGenreName(l10n, g.name),
                isSelected: selectedGenreId == g.id,
                colors: colors,
                theme: theme,
                onTap: () => onGenreSelected(g.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
