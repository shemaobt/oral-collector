import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/l10n/content_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../genre/domain/entities/genre.dart';
import '../../../genre/presentation/notifiers/genre_notifier.dart';
import '../../domain/entities/classification.dart';
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
  final String? currentPrimaryRegisterId;
  final String? currentSecondaryGenreId;
  final String? currentSecondarySubcategoryId;
  final String? currentSecondaryRegisterId;

  const MoveCategoryDialog({
    super.key,
    required this.currentGenreId,
    this.currentSubcategoryId,
    required this.currentPrimaryRegisterId,
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

  /// Falls back to the first available genre when the current selection no
  /// longer exists (e.g. the genre was deleted). Mutates selection state, so it
  /// must run before deriving the dropdown values.
  void _reconcileGenreSelection(List<Genre> genres) {
    final genreExists = genres.any((g) => g.id == _selectedGenreId);
    if (!genreExists && genres.isNotEmpty) {
      _selectedGenreId = genres.first.id;
      _selectedSubcategoryId = null;
    }
  }

  String? _resolveGenreValue(List<Genre> genres) {
    final genreExists = genres.any((g) => g.id == _selectedGenreId);
    return genreExists
        ? _selectedGenreId
        : (genres.isNotEmpty ? genres.first.id : null);
  }

  String? _resolveSubcategoryValue(List<Subcategory> subcategories) {
    return subcategories.any((s) => s.id == _selectedSubcategoryId)
        ? _selectedSubcategoryId
        : null;
  }

  bool get _secondaryChanged {
    final initialSecondaryGenre = widget.currentSecondaryGenreId;
    final initialSecondarySub = widget.currentSecondarySubcategoryId;
    final initialSecondaryReg = widget.currentSecondaryRegisterId;
    return _showSecondary
        ? (_secondary?.genreId != initialSecondaryGenre ||
              _secondary?.subcategoryId != initialSecondarySub ||
              _secondary?.registerId != initialSecondaryReg)
        : (initialSecondaryGenre != null || initialSecondaryReg != null);
  }

  bool get _hasChanged =>
      _selectedGenreId != widget.currentGenreId ||
      _selectedSubcategoryId != widget.currentSubcategoryId ||
      _secondaryChanged;

  bool get _secondaryValid =>
      !_showSecondary ||
      _secondary == null ||
      (_secondary!.isValid &&
          !secondaryEqualsPrimary(
            primaryRegisterId: widget.currentPrimaryRegisterId,
            primaryGenreId: _selectedGenreId,
            primarySubcategoryId: _selectedSubcategoryId,
            secondaryRegisterId: _secondary!.registerId,
            secondaryGenreId: _secondary!.genreId,
            secondarySubcategoryId: _secondary!.subcategoryId,
          ));

  bool get _shouldClearSecondary =>
      !_showSecondary &&
      (widget.currentSecondaryGenreId != null ||
          widget.currentSecondaryRegisterId != null);

  bool get _canMove => _hasChanged && _secondaryValid;

  void _onGenreChanged(String? value) {
    if (value == null) return;
    setState(() {
      _selectedGenreId = value;
      _selectedSubcategoryId = null;
    });
  }

  void _onSubcategoryChanged(String? value) {
    setState(() {
      _selectedSubcategoryId = value;
    });
  }

  void _onSecondaryExpansionChanged(bool expanded) {
    setState(() {
      _showSecondary = expanded;
      if (!expanded) _secondary = null;
    });
  }

  void _onSecondaryChanged(SecondaryValues? values) {
    setState(() {
      _secondary = values;
    });
  }

  void _onCancel() => Navigator.of(context).pop(null);

  void _onMove() {
    final secondary = _showSecondary ? _secondary : null;
    Navigator.of(context).pop(
      MoveCategoryResult(
        genreId: _selectedGenreId,
        subcategoryId: _selectedSubcategoryId,
        secondaryGenreId: secondary?.genreId,
        secondarySubcategoryId: secondary?.subcategoryId,
        secondaryRegisterId: secondary?.registerId,
        clearSecondary: _shouldClearSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final genres = ref.watch(genreNotifierProvider).genres;

    _reconcileGenreSelection(genres);

    final selectedGenre = genres
        .where((g) => g.id == _selectedGenreId)
        .firstOrNull;
    final List<Subcategory> subcategories =
        selectedGenre?.subcategories ?? const [];

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.folderInput, size: 20, color: colors.secondary),
          const SizedBox(width: SpacingScale.s8),
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
              _LabeledDropdownField(
                label: l10n.moveCategory_genre,
                value: _resolveGenreValue(genres),
                items: genres
                    .map(
                      (g) => DropdownMenuItem(
                        value: g.id,
                        child: Text(localizedGenreName(l10n, g.name)),
                      ),
                    )
                    .toList(),
                onChanged: _onGenreChanged,
              ),
              const SizedBox(height: SpacingScale.s16),

              if (subcategories.isNotEmpty) ...[
                _LabeledDropdownField(
                  label: l10n.moveCategory_subcategory,
                  isExpanded: true,
                  hint: l10n.moveCategory_selectSubcategory,
                  value: _resolveSubcategoryValue(subcategories),
                  items: subcategories
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(localizedSubcategoryName(l10n, s.name)),
                        ),
                      )
                      .toList(),
                  onChanged: _onSubcategoryChanged,
                ),
              ],
              const SizedBox(height: SpacingScale.s12),
              _SecondaryExpansion(
                expanded: _showSecondary,
                primaryGenreId: _selectedGenreId,
                primarySubcategoryId: _selectedSubcategoryId,
                primaryRegisterId: widget.currentPrimaryRegisterId,
                initial: _secondary,
                onExpansionChanged: _onSecondaryExpansionChanged,
                onChanged: _onSecondaryChanged,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _onCancel, child: Text(l10n.common_cancel)),
        TextButton(
          onPressed: _canMove ? _onMove : null,
          child: Text(l10n.common_move),
        ),
      ],
    );
  }
}

/// A label above a dense [DropdownButtonFormField], shared by the genre and
/// subcategory selectors.
class _LabeledDropdownField extends StatelessWidget {
  const _LabeledDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.isExpanded = false,
  });

  final String label;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;
  final String? hint;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.foreground.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingScale.s4),
        DropdownButtonFormField<String>(
          isExpanded: isExpanded,
          initialValue: value,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: SpacingScale.s12,
              vertical: SpacingScale.s8,
            ),
          ),
          hint: hint == null ? null : Text(hint!),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// The collapsible "add alternative" section wrapping
/// [SecondaryClassificationFields].
class _SecondaryExpansion extends StatelessWidget {
  const _SecondaryExpansion({
    required this.expanded,
    required this.primaryGenreId,
    required this.primarySubcategoryId,
    required this.primaryRegisterId,
    required this.initial,
    required this.onExpansionChanged,
    required this.onChanged,
  });

  final bool expanded;
  final String primaryGenreId;
  final String? primarySubcategoryId;
  final String? primaryRegisterId;
  final SecondaryValues? initial;
  final ValueChanged<bool> onExpansionChanged;
  final ValueChanged<SecondaryValues?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    return Theme(
      data: theme.copyWith(dividerColor: AppColors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: SpacingScale.s8),
        initiallyExpanded: expanded,
        onExpansionChanged: onExpansionChanged,
        leading: Icon(LucideIcons.layers, size: 18, color: colors.secondary),
        title: Text(
          l10n.classify_addAlternativeTitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          SecondaryClassificationFields(
            primaryGenreId: primaryGenreId,
            primarySubcategoryId: primarySubcategoryId,
            primaryRegisterId: primaryRegisterId,
            initial: initial,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
