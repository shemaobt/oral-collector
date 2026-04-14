import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/l10n/content_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../genre/presentation/notifiers/genre_notifier.dart';
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
    this.initialGenreId,
    this.initialSubcategoryId,
    this.initialRegisterId,
  });

  final String parentGenreId;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final genreState = ref.watch(genreNotifierProvider);
    final allGenres = genreState.genres;
    final activeGenreId = _genreId ?? widget.parentGenreId;
    final activeGenre = allGenres
        .where((g) => g.id == activeGenreId)
        .firstOrNull;
    final subcategories = activeGenre?.subcategories ?? [];

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
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: colors.border.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(LucideIcons.tag, size: 18, color: colors.accent),
                        const SizedBox(width: 8),
                        Text(
                          l10n.trim_classifySegment,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.moveCategory_genre,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.foreground.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _InheritTile(
                        selected: _genreId == null,
                        label: l10n.trim_inheritLabel,
                        onTap: () => setState(() {
                          _genreId = null;
                          _subcategoryId = null;
                        }),
                      ),
                      const SizedBox(height: 6),
                      ...allGenres.map(
                        (g) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _OptionTile(
                            selected: _genreId == g.id,
                            label: localizedGenreName(l10n, g.name),
                            onTap: () => setState(() {
                              if (_genreId != g.id) {
                                _subcategoryId = null;
                              }
                              _genreId = g.id;
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (subcategories.isNotEmpty) ...[
                        Text(
                          l10n.moveCategory_subcategory,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.foreground.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _InheritTile(
                          selected: _subcategoryId == null,
                          label: l10n.trim_inheritLabel,
                          onTap: () => setState(() => _subcategoryId = null),
                        ),
                        const SizedBox(height: 6),
                        ...subcategories.map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _OptionTile(
                              selected: _subcategoryId == s.id,
                              label: localizedSubcategoryName(l10n, s.name),
                              onTap: () =>
                                  setState(() => _subcategoryId = s.id),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        l10n.classify_register,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.foreground.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _InheritTile(
                        selected: _registerId == null,
                        label: l10n.trim_inheritLabel,
                        onTap: () => setState(() => _registerId = null),
                      ),
                      const SizedBox(height: 6),
                      ...kRegisters.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _OptionTile(
                            selected: _registerId == r.id,
                            label: localizedRegisterName(l10n, r.name),
                            onTap: () => setState(() => _registerId = r.id),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(l10n.common_cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? colors.accent.withValues(alpha: 0.12) : colors.card,
          borderRadius: BorderRadius.circular(10),
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? colors.secondary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
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
            const SizedBox(width: 8),
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
