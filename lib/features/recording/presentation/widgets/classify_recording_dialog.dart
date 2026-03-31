import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/l10n/content_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../genre/presentation/notifiers/genre_notifier.dart';
import '../../domain/entities/register.dart';

class ClassifyResult {
  final String genreId;
  final String? subcategoryId;
  final String? registerId;

  const ClassifyResult({
    required this.genreId,
    this.subcategoryId,
    this.registerId,
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

    final isValid = _selectedGenreId != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.tag, size: 20, color: colors.secondary),
          const SizedBox(width: 8),
          Text(l10n.classify_title),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
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
              initialValue: _selectedGenreId,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
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
              const SizedBox(height: 16),
            ],

            Text(
              l10n.classify_register,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.foreground.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _selectedRegisterId,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.common_cancel),
        ),
        TextButton(
          onPressed: isValid
              ? () => Navigator.of(context).pop(
                  ClassifyResult(
                    genreId: _selectedGenreId!,
                    subcategoryId: _selectedSubcategoryId,
                    registerId: _selectedRegisterId,
                  ),
                )
              : null,
          child: Text(l10n.classify_action),
        ),
      ],
    );
  }
}
