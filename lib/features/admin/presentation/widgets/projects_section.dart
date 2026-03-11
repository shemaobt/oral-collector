import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/format.dart';
import 'admin_mini_stat.dart';

class ProjectsSection extends StatelessWidget {
  const ProjectsSection({super.key, required this.projects});

  final List projects;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No projects found')),
        ),
      );
    }

    final isWide = MediaQuery.of(context).size.width >= 800;

    if (isWide) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Language')),
              DataColumn(label: Text('Members'), numeric: true),
              DataColumn(label: Text('Recordings'), numeric: true),
              DataColumn(label: Text('Duration')),
              DataColumn(label: Text('Created')),
            ],
            rows: projects.map((p) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      p.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  DataCell(Text(p.languageName ?? '\u2014')),
                  DataCell(Text('${p.memberCount}')),
                  DataCell(Text('${p.recordingCount}')),
                  DataCell(Text(formatDurationCompact(p.totalDurationSeconds))),
                  DataCell(Text(formatDateISO(p.createdAt))),
                ],
              );
            }).toList(),
          ),
        ),
      );
    }

    return Column(
      children: projects.map<Widget>((p) {
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.languageName ?? 'Unknown language',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.of(context).secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    AdminMiniStat(
                      icon: LucideIcons.users,
                      value: '${p.memberCount}',
                    ),
                    const SizedBox(width: 16),
                    AdminMiniStat(
                      icon: LucideIcons.mic,
                      value: '${p.recordingCount}',
                    ),
                    const SizedBox(width: 16),
                    AdminMiniStat(
                      icon: LucideIcons.clock,
                      value: formatDurationCompact(p.totalDurationSeconds),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
