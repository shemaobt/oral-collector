import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../notifiers/recordings_list_state.dart';

class StatusFilterBar extends StatelessWidget {
  const StatusFilterBar({
    super.key,
    required this.colors,
    required this.theme,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  final AppColorSet colors;
  final ThemeData theme;
  final StatusFilter currentFilter;
  final ValueChanged<StatusFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filters = [
      (StatusFilter.all, l10n.filter_all, LucideIcons.list),
      (StatusFilter.pending, l10n.filter_pending, LucideIcons.clock),
      (StatusFilter.uploaded, l10n.filter_uploaded, LucideIcons.checkCircle2),
      (
        StatusFilter.needsCleaning,
        l10n.filter_needsCleaning,
        LucideIcons.sparkles,
      ),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (filter, label, icon) = filters[index];
          final isSelected = currentFilter == filter;

          return GestureDetector(
            onTap: () => onFilterChanged(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.accent
                    : colors.surfaceAlt.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? colors.accent
                      : colors.border.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected ? Colors.white : colors.secondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isSelected ? Colors.white : colors.secondary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
