import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../genre/presentation/notifiers/genre_notifier.dart';

class MoveCategoryResult {
  final String genreId;
  final String? subcategoryId;

  const MoveCategoryResult({required this.genreId, this.subcategoryId});
}

class MoveCategoryDialog extends ConsumerStatefulWidget {
  final String currentGenreId;
  final String? currentSubcategoryId;

  const MoveCategoryDialog({
    super.key,
    required this.currentGenreId,
    this.currentSubcategoryId,
  });

  @override
  ConsumerState<MoveCategoryDialog> createState() => _MoveCategoryDialogState();
}

class _MoveCategoryDialogState extends ConsumerState<MoveCategoryDialog> {
  late String _selectedGenreId;
  String? _selectedSubcategoryId;

  @override
  void initState() {
    super.initState();
    _selectedGenreId = widget.currentGenreId;
    _selectedSubcategoryId = widget.currentSubcategoryId;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final genreState = ref.watch(genreNotifierProvider);
    final genres = genreState.genres;

    final selectedGenre = genres
        .where((g) => g.id == _selectedGenreId)
        .firstOrNull;
    final subcategories = selectedGenre?.subcategories ?? [];

    final hasChanged =
        _selectedGenreId != widget.currentGenreId ||
        _selectedSubcategoryId != widget.currentSubcategoryId;

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.folderInput, size: 20, color: colors.secondary),
          const SizedBox(width: 8),
          const Text('Move Category'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Genre',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.foreground.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _selectedGenreId,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items: genres
                  .map(
                    (g) => DropdownMenuItem(value: g.id, child: Text(g.name)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedGenreId = value;

                  _selectedSubcategoryId = null;
                });
              },
            ),
            const SizedBox(height: 16),

            if (subcategories.isNotEmpty) ...[
              Text(
                'Subcategory',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.foreground.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue:
                    subcategories.any((s) => s.id == _selectedSubcategoryId)
                    ? _selectedSubcategoryId
                    : null,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                hint: const Text('Select subcategory'),
                items: subcategories
                    .map(
                      (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubcategoryId = value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: hasChanged
              ? () => Navigator.of(context).pop(
                  MoveCategoryResult(
                    genreId: _selectedGenreId,
                    subcategoryId: _selectedSubcategoryId,
                  ),
                )
              : null,
          child: const Text('Move'),
        ),
      ],
    );
  }
}
