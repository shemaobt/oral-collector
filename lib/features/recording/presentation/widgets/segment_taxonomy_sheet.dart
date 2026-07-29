import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/l10n/content_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../genre/presentation/notifiers/genre_notifier.dart';
import '../../domain/entities/classification.dart';
import '../../domain/entities/register.dart';

class SegmentTaxonomyResult {
  final String? genreId;
  final String? subcategoryId;
  final String? registerId;
  final bool applyToAll;

  const SegmentTaxonomyResult({
    this.genreId,
    this.subcategoryId,
    this.registerId,
    this.applyToAll = false,
  });
}

class SegmentTaxonomySheet extends ConsumerStatefulWidget {
  const SegmentTaxonomySheet({
    super.key,
    required this.parentGenreId,
    required this.parentSubcategoryId,
    required this.parentRegisterId,
    this.parentSecondaryGenreId,
    this.parentSecondarySubcategoryId,
    this.parentSecondaryRegisterId,
    this.initialGenreId,
    this.initialSubcategoryId,
    this.initialRegisterId,
  });

  final String parentGenreId;
  final String? parentSubcategoryId;
  final String? parentRegisterId;
  final String? parentSecondaryGenreId;
  final String? parentSecondarySubcategoryId;
  final String? parentSecondaryRegisterId;
  final String? initialGenreId;
  final String? initialSubcategoryId;
  final String? initialRegisterId;

  @override
  ConsumerState<SegmentTaxonomySheet> createState() =>
      _SegmentTaxonomySheetState();
}

class _SegmentTaxonomySheetState extends ConsumerState<SegmentTaxonomySheet> {
  String? _genreId;
  String? _subcategoryId;
  String? _registerId;
  bool _applyToAll = false;

  @override
  void initState() {
    super.initState();
    _genreId = widget.initialGenreId;
    _subcategoryId = widget.initialSubcategoryId;
    _registerId = widget.initialRegisterId;
  }

  static bool _same(String? a, String? b) => blankToNull(a) == blankToNull(b);

  /// A segment's effective classification is its override falling back to the
  /// parent's value, which is what the split guard compares.
  String get _effectiveGenreId => _genreId ?? widget.parentGenreId;
  String? get _effectiveRegisterId => _registerId ?? widget.parentRegisterId;

  // Only an effective triple identical to the secondary triple inherited from
  // the parent collides (ENG-72), so each field hides the single option that
  // would complete it. The genre test uses the parent's subcategory rather
  // than the current one because picking a genre always drops the subcategory
  // override.
  String? get _hiddenGenreId =>
      _same(widget.parentSubcategoryId, widget.parentSecondarySubcategoryId) &&
          _same(_effectiveRegisterId, widget.parentSecondaryRegisterId)
      ? blankToNull(widget.parentSecondaryGenreId)
      : null;

  String? get _hiddenSubcategoryId =>
      _same(_effectiveGenreId, widget.parentSecondaryGenreId) &&
          _same(_effectiveRegisterId, widget.parentSecondaryRegisterId)
      ? blankToNull(widget.parentSecondarySubcategoryId)
      : null;

  String? get _hiddenRegisterId =>
      _same(_effectiveGenreId, widget.parentSecondaryGenreId) &&
          _same(
            _subcategoryId ?? widget.parentSubcategoryId,
            widget.parentSecondarySubcategoryId,
          )
      ? blankToNull(widget.parentSecondaryRegisterId)
      : null;

  /// The inherit option is withheld when the value it would apply is the
  /// hidden one.
  static bool _inheritAllowed(String? parentValue, String? hiddenValue) =>
      hiddenValue == null || blankToNull(parentValue) != hiddenValue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final genreState = ref.watch(genreNotifierProvider);
    final hiddenGenreId = _hiddenGenreId;
    final hiddenSubcategoryId = _hiddenSubcategoryId;
    final hiddenRegisterId = _hiddenRegisterId;
    final activeGenre = genreState.genres
        .where((g) => g.id == _effectiveGenreId)
        .firstOrNull;
    final subcategories = (activeGenre?.subcategories ?? [])
        .where((s) => s.id != hiddenSubcategoryId)
        .toList();

    final screenHeight = MediaQuery.of(context).size.height;
    final maxSheetHeight = screenHeight * 0.85;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SpacingScale.s20,
                  SpacingScale.s16,
                  SpacingScale.s20,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: SpacingScale.s16),
                        decoration: BoxDecoration(
                          color: colors.border.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(LucideIcons.tag, size: 18, color: colors.accent),
                        const SizedBox(width: SpacingScale.s8),
                        Expanded(
                          child: Text(
                            l10n.trim_classifySegment,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SpacingScale.s16),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingScale.s20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TaxonomySection(
                        label: l10n.moveCategory_genre,
                        showInherit: _inheritAllowed(
                          widget.parentGenreId,
                          hiddenGenreId,
                        ),
                        inheritSelected: _genreId == null,
                        onInherit: () => setState(() {
                          _genreId = null;
                          _subcategoryId = null;
                        }),
                        options: [
                          for (final g in genreState.genres)
                            if (g.id != hiddenGenreId)
                              (
                                selected: _genreId == g.id,
                                label: localizedGenreName(l10n, g.name),
                                onTap: () => setState(() {
                                  if (_genreId != g.id) _subcategoryId = null;
                                  _genreId = g.id;
                                }),
                              ),
                        ],
                      ),
                      if (subcategories.isNotEmpty)
                        _TaxonomySection(
                          label: l10n.moveCategory_subcategory,
                          showInherit: _inheritAllowed(
                            widget.parentSubcategoryId,
                            hiddenSubcategoryId,
                          ),
                          inheritSelected: _subcategoryId == null,
                          onInherit: () =>
                              setState(() => _subcategoryId = null),
                          options: [
                            for (final s in subcategories)
                              (
                                selected: _subcategoryId == s.id,
                                label: localizedSubcategoryName(l10n, s.name),
                                onTap: () =>
                                    setState(() => _subcategoryId = s.id),
                              ),
                          ],
                        ),
                      _TaxonomySection(
                        label: l10n.classify_register,
                        showInherit: _inheritAllowed(
                          widget.parentRegisterId,
                          hiddenRegisterId,
                        ),
                        inheritSelected: _registerId == null,
                        onInherit: () => setState(() => _registerId = null),
                        options: [
                          for (final r in kRegisters)
                            if (r.id != hiddenRegisterId)
                              (
                                selected: _registerId == r.id,
                                label: localizedRegisterName(l10n, r.name),
                                onTap: () => setState(() => _registerId = r.id),
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SpacingScale.s20,
                  SpacingScale.s8,
                  SpacingScale.s20,
                  SpacingScale.s20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _applyToAll,
                      onChanged: (v) =>
                          setState(() => _applyToAll = v ?? false),
                      title: Text(
                        l10n.trim_applyToAll,
                        style: theme.textTheme.bodyMedium,
                      ),
                      dense: true,
                    ),
                    const SizedBox(height: SpacingScale.s8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(l10n.common_cancel),
                          ),
                        ),
                        const SizedBox(width: SpacingScale.s12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(
                              SegmentTaxonomyResult(
                                genreId: _genreId,
                                subcategoryId: _subcategoryId,
                                registerId: _registerId,
                                applyToAll: _applyToAll,
                              ),
                            ),
                            child: Text(l10n.common_save),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _TaxonomyOption = ({bool selected, String label, VoidCallback onTap});

/// One labelled block of the sheet: the inherit option followed by the
/// selectable values for that field.
class _TaxonomySection extends StatelessWidget {
  const _TaxonomySection({
    required this.label,
    required this.showInherit,
    required this.inheritSelected,
    required this.onInherit,
    required this.options,
  });

  final String label;
  final bool showInherit;
  final bool inheritSelected;
  final VoidCallback onInherit;
  final List<_TaxonomyOption> options;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colors.foreground.withValues(alpha: 0.65),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: SpacingScale.s8),
        if (showInherit) ...[
          _InheritTile(
            selected: inheritSelected,
            label: l10n.trim_inheritLabel,
            onTap: onInherit,
          ),
          const SizedBox(height: SpacingScale.s8),
        ],
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: SpacingScale.s8),
            child: _OptionTile(
              selected: option.selected,
              label: option.label,
              onTap: option.onTap,
            ),
          ),
        const SizedBox(height: SpacingScale.s8),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RadiusScale.r8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingScale.s16,
          vertical: SpacingScale.s12,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.accent.withValues(alpha: 0.12) : colors.card,
          borderRadius: BorderRadius.circular(RadiusScale.r8),
          border: Border.all(
            color: selected
                ? colors.accent.withValues(alpha: 0.5)
                : colors.border.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? colors.accent : colors.foreground,
                ),
              ),
            ),
            if (selected)
              Icon(LucideIcons.check, size: 16, color: colors.accent),
          ],
        ),
      ),
    );
  }
}

class _InheritTile extends StatelessWidget {
  const _InheritTile({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RadiusScale.r8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingScale.s16,
          vertical: SpacingScale.s12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? colors.secondary.withValues(alpha: 0.08)
              : AppColors.transparent,
          borderRadius: BorderRadius.circular(RadiusScale.r8),
          border: Border.all(
            color: selected
                ? colors.secondary.withValues(alpha: 0.4)
                : colors.border.withValues(alpha: 0.25),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.arrowUp,
              size: 14,
              color: colors.foreground.withValues(alpha: 0.5),
            ),
            const SizedBox(width: SpacingScale.s8),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colors.foreground.withValues(alpha: 0.7),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              Icon(LucideIcons.check, size: 16, color: colors.secondary),
          ],
        ),
      ),
    );
  }
}
