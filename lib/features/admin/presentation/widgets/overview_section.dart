import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/admin_stats.dart';
import 'stat_card.dart';

class OverviewSection extends StatelessWidget {
  const OverviewSection({super.key, this.stats});

  final AdminStats? stats;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final items = [
      StatCardData(
        icon: LucideIcons.folderOpen,
        label: 'Total Projects',
        value: '${stats?.totalProjects ?? 0}',
        color: colors.primary,
      ),
      StatCardData(
        icon: LucideIcons.globe,
        label: 'Languages',
        value: '${stats?.totalLanguages ?? 0}',
        color: colors.info,
      ),
      StatCardData(
        icon: LucideIcons.mic,
        label: 'Recordings',
        value: '${stats?.totalRecordings ?? 0}',
        color: colors.success,
      ),
      StatCardData(
        icon: LucideIcons.clock,
        label: 'Total Hours',
        value: (stats?.totalHours ?? 0).toStringAsFixed(1),
        color: colors.secondary,
      ),
      StatCardData(
        icon: LucideIcons.users,
        label: 'Active Users',
        value: '${stats?.activeUsers ?? 0}',
        color: colors.primary,
      ),
    ];

    final isWide = MediaQuery.of(context).size.width >= 800;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map(
            (item) => SizedBox(
              width: isWide ? 200 : double.infinity,
              child: StatCard(data: item),
            ),
          )
          .toList(),
    );
  }
}
