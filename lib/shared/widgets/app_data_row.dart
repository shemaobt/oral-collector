import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppDataRow extends StatelessWidget {
  const AppDataRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final base = Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 46),
      child: Row(
        spacing: 16,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label, style: base?.copyWith(color: colors.secondary)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: base?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
