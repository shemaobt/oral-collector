import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class InfoBadge extends StatelessWidget {
  const InfoBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.colors,
    required this.theme,
    this.accentColor,
  });

  final IconData icon;
  final String label;
  final AppColorSet colors;
  final ThemeData theme;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? colors.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
