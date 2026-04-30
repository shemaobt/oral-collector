import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../genre/domain/entities/genre.dart';
import '../../../storyteller/domain/entities/storyteller.dart';
import 'classification_field.dart';

class BulkMetadataBar extends StatelessWidget {
  const BulkMetadataBar({
    super.key,
    required this.projectId,
    required this.genres,
    required this.bulkGenreId,
    required this.bulkSubcategoryId,
    required this.bulkRegisterId,
    required this.bulkStoryteller,
    required this.onGenreChanged,
    required this.onSubcategoryChanged,
    required this.onRegisterChanged,
    required this.onStorytellerChanged,
    required this.onApply,
    required this.isNarrow,
  });

  final String projectId;
  final List<Genre> genres;
  final String? bulkGenreId;
  final String? bulkSubcategoryId;
  final String? bulkRegisterId;
  final Storyteller? bulkStoryteller;
  final ValueChanged<String?> onGenreChanged;
  final ValueChanged<String?> onSubcategoryChanged;
  final ValueChanged<String?> onRegisterChanged;
  final ValueChanged<Storyteller?> onStorytellerChanged;
  final VoidCallback onApply;
  final bool isNarrow;

  bool get _hasAny =>
      bulkGenreId != null ||
      bulkSubcategoryId != null ||
      bulkRegisterId != null ||
      bulkStoryteller != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    final genre = genres.where((g) => g.id == bulkGenreId).firstOrNull;
    final showSubcategory = genre?.subcategories.isNotEmpty ?? false;

    if (isNarrow) {
      return Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: colors.surfaceAlt.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colors.border.withValues(alpha: 0.4)),
        ),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Icon(LucideIcons.copy, size: 18, color: colors.accent),
            title: Text(
              l10n.import_setForAll,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: _hasAny
                ? Text(
                    _bulkSummary(l10n),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.foreground.withValues(alpha: 0.6),
                    ),
                  )
                : null,
            children: [
              _buildFields(context, showSubcategory),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _hasAny ? onApply : null,
                  icon: const Icon(LucideIcons.check, size: 16),
                  label: Text(l10n.import_applyToAll),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceAlt.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.copy, size: 16, color: colors.accent),
              const SizedBox(width: 8),
              Text(
                l10n.import_setForAll,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFields(context, showSubcategory),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _hasAny ? onApply : null,
              icon: const Icon(LucideIcons.check, size: 16),
              label: Text(l10n.import_applyToAll),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFields(BuildContext context, bool showSubcategory) {
    final columns = <Widget>[
      _FieldSlot(
        child: ClassificationField.genre(
          value: bulkGenreId,
          onChanged: onGenreChanged,
          genres: genres,
        ),
      ),
      if (showSubcategory)
        _FieldSlot(
          child: ClassificationField.subcategory(
            value: bulkSubcategoryId,
            onChanged: onSubcategoryChanged,
            genres: genres,
            genreId: bulkGenreId,
          ),
        ),
      _FieldSlot(
        child: ClassificationField.register(
          value: bulkRegisterId,
          onChanged: onRegisterChanged,
        ),
      ),
      _FieldSlot(
        child: StorytellerFieldCell(
          projectId: projectId,
          selected: bulkStoryteller,
          onChanged: onStorytellerChanged,
          compact: true,
        ),
      ),
    ];

    if (isNarrow) {
      return Column(
        children: [
          for (int i = 0; i < columns.length; i++) ...[
            columns[i],
            if (i < columns.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Wrap(spacing: 12, runSpacing: 12, children: columns);
  }

  String _bulkSummary(AppLocalizations l10n) {
    final parts = <String>[];
    if (bulkGenreId != null) parts.add(l10n.moveCategory_genre);
    if (bulkSubcategoryId != null) parts.add(l10n.moveCategory_subcategory);
    if (bulkRegisterId != null) parts.add(l10n.classify_register);
    if (bulkStoryteller != null) parts.add(bulkStoryteller!.name);
    return parts.join(' · ');
  }
}

class _FieldSlot extends StatelessWidget {
  const _FieldSlot({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        return SizedBox(width: isNarrow ? double.infinity : 210, child: child);
      },
    );
  }
}
