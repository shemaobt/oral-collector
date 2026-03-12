import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/format.dart';

class StatsStrip extends StatelessWidget {
  const StatsStrip({
    super.key,
    required this.totalRecordings,
    required this.totalDuration,
    required this.memberCount,
    required this.colors,
  });

  final int totalRecordings;
  final double totalDuration;
  final int memberCount;
  final AppColorSet colors;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark
              ? colors.foreground.withValues(alpha: 0.05)
              : colors.surfaceAlt,
          borderRadius: BorderRadius.circular(18),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              StatTile(
                value: '$totalRecordings',
                label: 'recordings',
                icon: LucideIcons.mic,
                color: colors.accent,
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: colors.border.withValues(alpha: 0.4),
              ),
              StatTile(
                value: formatDurationCompact(totalDuration),
                label: 'recorded',
                icon: LucideIcons.clock,
                color: colors.success,
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: colors.border.withValues(alpha: 0.4),
              ),
              StatTile(
                value: '$memberCount',
                label: 'members',
                icon: LucideIcons.users,
                color: colors.info,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.secondary,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
