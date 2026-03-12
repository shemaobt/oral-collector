import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../shared/utils/genre_helpers.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../genre/domain/entities/genre.dart';

class GenreSelectionStep extends StatelessWidget {
  const GenreSelectionStep({
    super.key,
    required this.genres,
    required this.onSelect,
  });

  final List<Genre> genres;
  final ValueChanged<Genre> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (genres.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.layoutGrid,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No genres available',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth >= 900
        ? 4
        : screenWidth >= 600
        ? 3
        : 2;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        AppShell.scrollBottomPadding,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: genres.length,
      itemBuilder: (context, index) {
        final genre = genres[index];
        final color = parseHexColor(genre.color);
        final icon = mapGenreIcon(genre.icon);

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onSelect(genre),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 28, color: color),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    genre.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
