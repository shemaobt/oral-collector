import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class GenreFilterChip extends StatelessWidget {
  const GenreFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.colors,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final AppColorSet colors;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.4)
                : colors.border.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected ? colors.primary : colors.secondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
