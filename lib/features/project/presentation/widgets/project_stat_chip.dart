import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';

class ProjectSettingsStatChip extends StatelessWidget {
  const ProjectSettingsStatChip({
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
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: SpacingScale.s16,
          horizontal: SpacingScale.s8,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(RadiusScale.r16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: SpacingScale.s8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.foreground,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.secondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
