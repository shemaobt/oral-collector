import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/l10n/content_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../genre/presentation/notifiers/genre_notifier.dart';
import 'secondary_classification_fields.dart';

class MoveCategoryResult {
  final String genreId;
  final String? subcategoryId;
  final String? secondaryGenreId;
  final String? secondarySubcategoryId;
  final String? secondaryRegisterId;
  final bool clearSecondary;

  const MoveCategoryResult({
    required this.genreId,
    this.subcategoryId,
    this.secondaryGenreId,
    this.secondarySubcategoryId,
    this.secondaryRegisterId,
    this.clearSecondary = false,
  });
}

class MoveCategoryDialog extends ConsumerStatefulWidget {
  final String currentGenreId;
  final String? currentSubcategoryId;
  final String? currentSecondaryGenreId;
  final String? currentSecondarySubcategoryId;
  final String? currentSecondaryRegisterId;

  const MoveCategoryDialog({
    super.key,
    required this.currentGenreId,
    this.currentSubcategoryId,
    this.currentSecondaryGenreId,
    this.currentSecondarySubcategoryId,
    this.currentSecondaryRegisterId,
  });

  @override
  ConsumerState<MoveCategoryDialog> createState() => _MoveCategoryDialogState();
}

class _MoveCategoryDialogState extends ConsumerState<MoveCategoryDialog> {
  late String _selectedGenreId;
  String? _selectedSubcategoryId;
  late bool _showSecondary;
  SecondaryValues? _secondary;

  @override
  void initState() {
    super.initState();
    _selectedGenreId = widget.currentGenreId;
    _selectedSubcategoryId = widget.currentSubcategoryId;
    final hasInitialSecondary =
        (widget.currentSecondaryGenreId != null &&
            widget.currentSecondaryGenreId!.isNotEmpty) ||
        (widget.currentSecondaryRegisterId != null &&
            widget.currentSecondaryRegisterId!.isNotEmpty);
    _showSecondary = hasInitialSecondary;
    _secondary = hasInitialSecondary
        ? SecondaryValues(
            genreId: widget.currentSecondaryGenreId,
            subcategoryId: widget.currentSecondarySubcategoryId,
            registerId: widget.currentSecondaryRegisterId,
          )
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final genreState = ref.watch(genreNotifierProvider);
    final genres = genreState.genres;

    final genreExists = genres.any((g) => g.id == _selectedGenreId);
    if (!genreExists && genres.isNotEmpty) {
      _selectedGenreId = genres.first.id;
      _selectedSubcategoryId = null;
    }

    final selectedGenre = genres
        .where((g) => g.id == _selectedGenreId)
        .firstOrNull;
    final subcategories = selectedGenre?.subcategories ?? [];

    final initialSecondaryGenre = widget.currentSecondaryGenreId;
    final initialSecondarySub = widget.currentSecondarySubcategoryId;
    final initialSecondaryReg = widget.currentSecondaryRegisterId;

    final secondaryChanged = _showSecondary
        ? (_secondary?.genreId != initialSecondaryGenre ||
              _secondary?.subcategoryId != initialSecondarySub ||
              _secondary?.registerId != initialSecondaryReg)
        : (initialSecondaryGenre != null || initialSecondaryReg != null);

    final hasChanged =
        _selectedGenreId != widget.currentGenreId ||
        _selectedSubcategoryId != widget.currentSubcategoryId ||
        secondaryChanged;

    final secondaryValid =
        !_showSecondary ||
        _secondary == null ||
        (_secondary!.isValid && _secondary!.genreId != _selectedGenreId);

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.folderInput, size: 20, color: colors.secondary),
          const SizedBox(width: 8),
          Text(l10n.moveCategory_title),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.moveCategory_genre,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.foreground.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: genreExists
                    ? _selectedGenreId
                    : (genres.isNotEmpty ? genres.first.id : null),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: genres
                    .map(
                      (g) => DropdownMenuItem(
                        value: g.id,
                        child: Text(localizedGenreName(l10n, g.name)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedGenreId = value;
                    _selectedSubcategoryId = null;
                    if (_secondary?.genreId == value) {
                      _secondary = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              if (subcategories.isNotEmpty) ...[
                Text(
                  l10n.moveCategory_subcategory,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.foreground.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  isExpanded: true,
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
                  hint: Text(l10n.moveCategory_selectSubcategory),
                  items: subcategories
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(localizedSubcategoryName(l10n, s.name)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubcategoryId = value;
                    });
                  },
                ),
              ],
              const SizedBox(height: 12),
              Theme(
                data: theme.copyWith(dividerColor: AppColors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: 8),
                  initiallyExpanded: _showSecondary,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _showSecondary = expanded;
                      if (!expanded) _secondary = null;
                    });
                  },
                  leading: Icon(
                    LucideIcons.layers,
                    size: 18,
                    color: colors.secondary,
                  ),
                  title: Text(
                    l10n.classify_addAlternativeTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: [
                    SecondaryClassificationFields(
                      primaryGenreId: _selectedGenreId,
                      initial: _secondary,
                      onChanged: (values) {
                        setState(() {
                          _secondary = values;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.common_cancel),
        ),
        TextButton(
          onPressed: hasChanged && secondaryValid
              ? () {
                  final secondary = _showSecondary ? _secondary : null;
                  final clearSecondary =
                      !_showSecondary &&
                      (initialSecondaryGenre != null ||
                          initialSecondaryReg != null);
                  Navigator.of(context).pop(
                    MoveCategoryResult(
                      genreId: _selectedGenreId,
                      subcategoryId: _selectedSubcategoryId,
                      secondaryGenreId: secondary?.genreId,
                      secondarySubcategoryId: secondary?.subcategoryId,
                      secondaryRegisterId: secondary?.registerId,
                      clearSecondary: clearSecondary,
                    ),
                  );
                }
              : null,
          child: Text(l10n.common_move),
        ),
      ],
    );
  }
}
