import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/format.dart';
import '../../domain/entities/project.dart';

const projectAccentColors = [
  Color(0xFFD45200),
  Color(0xFF1A8A78),
  Color(0xFF477A12),
  Color(0xFF8B5CF6),
  Color(0xFFE0A526),
  Color(0xFF2563EB),
];

Color projectAccentForIndex(int index) =>
    projectAccentColors[index % projectAccentColors.length];

class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.isActive,
    required this.colorIndex,
  });

  final Project project;
  final VoidCallback onTap;
  final bool isActive;
  final int colorIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardAccent = projectAccentForIndex(colorIndex);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(20),
              border: isActive
                  ? Border.all(color: colors.accent, width: 2)
                  : Border.all(
                      color: colors.border.withValues(alpha: 0.2),
                      width: 1,
                    ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cardAccent, cardAccent.withValues(alpha: 0.3)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: cardAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                project.name.isNotEmpty
                                    ? project.name[0].toUpperCase()
                                    : '?',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: cardAccent,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                if (project.languageName != null)
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.globe,
                                        size: 13,
                                        color: colors.secondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        project.languageName!,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: colors.secondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                      if (project.languageCode != null) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.border.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            project.languageCode!.toUpperCase(),
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: colors.secondary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 20,
                            color: colors.secondary.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ProjectStatChip(
                            icon: LucideIcons.users,
                            value: '${project.memberCount}',
                            colors: colors,
                            theme: theme,
                          ),
                          const SizedBox(width: 12),
                          ProjectStatChip(
                            icon: LucideIcons.mic,
                            value: '${project.recordingCount}',
                            colors: colors,
                            theme: theme,
                          ),
                          const SizedBox(width: 12),
                          ProjectStatChip(
                            icon: LucideIcons.clock,
                            value: formatDurationCompact(
                              project.totalDurationSeconds,
                            ),
                            colors: colors,
                            theme: theme,
                          ),
                          if (isActive) ...[
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Active',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProjectStatChip extends StatelessWidget {
  const ProjectStatChip({
    super.key,
    required this.icon,
    required this.value,
    required this.colors,
    required this.theme,
  });

  final IconData icon;
  final String value;
  final AppColorSet colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceAlt.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.secondary),
          const SizedBox(width: 4),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
