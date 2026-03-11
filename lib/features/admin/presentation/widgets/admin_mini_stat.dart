import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AdminMiniStat extends StatelessWidget {
  const AdminMiniStat({super.key, required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.secondary),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.secondary),
        ),
      ],
    );
  }
}
