import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class StatCardData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const StatCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.data});

  final StatCardData data;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: data.color.withValues(alpha: 0.1),
              child: Icon(data.icon, color: data.color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    data.label,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.secondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
