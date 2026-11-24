import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import 'app_tile.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.hot = false,
  });

  final String value;
  final String label;
  final bool hot;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    return AppTile(
      radius: RadiusScale.r16,
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingScale.s12,
        vertical: SpacingScale.s12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: text.displaySmall?.copyWith(
              color: hot ? colors.accent : colors.foreground,
            ),
          ),
          Text(label, style: text.bodySmall?.copyWith(color: colors.secondary)),
        ],
      ),
    );
  }
}
