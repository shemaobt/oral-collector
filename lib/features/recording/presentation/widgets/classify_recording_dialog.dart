import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/l10n/content_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../genre/presentation/notifiers/genre_notifier.dart';
import '../../domain/entities/register.dart';
import 'secondary_classification_fields.dart';

class ClassifyResult {
  final String genreId;
  final String? subcategoryId;
  final String? registerId;
  final String? secondaryGenreId;
  final String? secondarySubcategoryId;
  final String? secondaryRegisterId;

  const ClassifyResult({
    required this.genreId,
    this.subcategoryId,
    this.registerId,
    this.secondaryGenreId,
    this.secondarySubcategoryId,
    this.secondaryRegisterId,
  });
}

class ClassifyRecordingDialog extends ConsumerStatefulWidget {
  const ClassifyRecordingDialog({super.key});

  @override
  ConsumerState<ClassifyRecordingDialog> createState() =>
      _ClassifyRecordingDialogState();
}

class _ClassifyRecordingDialogState
    extends ConsumerState<ClassifyRecordingDialog> {
  String? _selectedGenreId;
  String? _selectedSubcategoryId;
  String? _selectedRegisterId;
  bool _showSecondary = false;
  SecondaryValues? _secondary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final genreState = ref.watch(genreNotifierProvider);
    final genres = genreState.genres;

    final selectedGenre = genres
        .where((g) => g.id == _selectedGenreId)
        .firstOrNull;
    final subcategories = selectedGenre?.subcategories ?? [];

    final primaryValid =
        _selectedGenreId != null && _selectedRegisterId != null;
    final secondaryValid =
        !_showSecondary ||
        _secondary == null ||
        (_secondary!.isValid && _secondary!.genreId != _selectedGenreId);
    final isValid = primaryValid && secondaryValid;

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.tag, size: 20, color: colors.secondary),
          const SizedBox(width: SpacingScale.s8),
          Text(l10n.classify_title),
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
                l10n.classify_predominantHeader,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.foreground.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: SpacingScale.s8),
              Text(
                l10n.moveCategory_genre,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.foreground.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: SpacingScale.s4),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedGenreId,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: SpacingScale.s12,
                    vertical: SpacingScale.s8,
                  ),
                ),
                hint: Text(l10n.recording_selectGenre),
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
              const SizedBox(height: SpacingScale.s16),

              if (subcategories.isNotEmpty) ...[
                Text(
                  l10n.moveCategory_subcategory,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.foreground.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: SpacingScale.s4),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue:
                      subcategories.any((s) => s.id == _selectedSubcategoryId)
                      ? _selectedSubcategoryId
                      : null,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: SpacingScale.s12,
                      vertical: SpacingScale.s8,
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
                const SizedBox(height: SpacingScale.s16),
              ],

              Text(
                l10n.classify_register,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.foreground.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: SpacingScale.s4),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedRegisterId,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: SpacingScale.s12,
                    vertical: SpacingScale.s8,
                  ),
                ),
                hint: Text(l10n.classify_selectRegister),
                items: kRegisters
                    .map(
                      (r) => DropdownMenuItem(
                        value: r.id,
                        child: Text(localizedRegisterName(l10n, r.name)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRegisterId = value;
                  });
                },
              ),
              const SizedBox(height: SpacingScale.s12),
              Theme(
                data: theme.copyWith(dividerColor: AppColors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: SpacingScale.s8),
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
          onPressed: isValid
              ? () {
                  final secondary = _showSecondary ? _secondary : null;
                  Navigator.of(context).pop(
                    ClassifyResult(
                      genreId: _selectedGenreId!,
                      subcategoryId: _selectedSubcategoryId,
                      registerId: _selectedRegisterId,
                      secondaryGenreId: secondary?.genreId,
                      secondarySubcategoryId: secondary?.subcategoryId,
                      secondaryRegisterId: secondary?.registerId,
                    ),
                  );
                }
              : null,
          child: Text(l10n.classify_action),
        ),
      ],
    );
  }
}
