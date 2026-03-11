import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class StatItem extends StatelessWidget {
  const StatItem({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.colors,
    required this.theme,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final AppColorSet colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
