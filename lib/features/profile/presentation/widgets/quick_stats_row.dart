import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import 'stat_item.dart';

class QuickStatsRow extends StatelessWidget {
  const QuickStatsRow({
    super.key,
    required this.storageLabel,
    required this.isOnline,
    required this.pendingCount,
    required this.colors,
    required this.theme,
  });

  final String storageLabel;
  final bool isOnline;
  final int pendingCount;
  final AppColorSet colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          StatItem(
            icon: LucideIcons.hardDrive,
            value: storageLabel,
            label: 'Storage',
            color: colors.info,
            colors: colors,
            theme: theme,
          ),
          _buildStatDivider(),
          StatItem(
            icon: isOnline ? LucideIcons.wifi : LucideIcons.wifiOff,
            value: isOnline ? 'Online' : 'Offline',
            label: 'Status',
            color: isOnline ? colors.success : colors.error,
            colors: colors,
            theme: theme,
          ),
          _buildStatDivider(),
          StatItem(
            icon: LucideIcons.upload,
            value: '$pendingCount',
            label: 'Pending',
            color: pendingCount > 0 ? colors.accent : colors.secondary,
            colors: colors,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 32,
      color: colors.border.withValues(alpha: 0.2),
    );
  }
}
