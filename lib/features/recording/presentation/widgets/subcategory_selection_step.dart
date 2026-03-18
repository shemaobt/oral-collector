import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/l10n/content_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/genre_helpers.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../genre/domain/entities/genre.dart';

class SubcategorySelectionStep extends StatelessWidget {
  const SubcategorySelectionStep({
    super.key,
    required this.genre,
    required this.selectedSubcategoryId,
    required this.onSelect,
    required this.onNext,
  });

  final Genre genre;
  final String? selectedSubcategoryId;
  final ValueChanged<Subcategory> onSelect;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final color = parseHexColor(genre.color);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.category, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  localizedGenreName(l10n, genre.name),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: genre.subcategories.isEmpty
              ? Center(
                  child: Text(
                    l10n.recording_noSubcategories,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: genre.subcategories.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final subcategory = genre.subcategories[index];
                    final isSelected = subcategory.id == selectedSubcategoryId;

                    return Card(
                      color: isSelected ? color.withValues(alpha: 0.1) : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isSelected
                            ? BorderSide(color: color, width: 2)
                            : BorderSide.none,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => onSelect(subcategory),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      localizedSubcategoryName(
                                        l10n,
                                        subcategory.name,
                                      ),
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    if (localizedSubcategoryDescription(
                                          l10n,
                                          subcategory.name,
                                        )
                                        case final desc?) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        desc,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  LucideIcons.checkCircle,
                                  color: color,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            AppShell.scrollBottomPadding,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: selectedSubcategoryId != null ? onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: theme.colorScheme.outline.withValues(
                  alpha: 0.3,
                ),
                disabledForegroundColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.4,
                ),
              ),
              child: Text(l10n.common_continue),
            ),
          ),
        ),
      ],
    );
  }
}
