import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../project/domain/entities/project.dart';

class ProjectSwitcherSheet extends StatelessWidget {
  const ProjectSwitcherSheet({
    super.key,
    required this.projects,
    required this.activeProjectId,
    required this.onProjectSelected,
    required this.colors,
    required this.theme,
  });

  final List<Project> projects;
  final String? activeProjectId;
  final ValueChanged<Project> onProjectSelected;
  final AppColorSet colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Text(
                l10n.project_switchTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...projects.map((project) {
              final isActive = project.id == activeProjectId;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isActive
                        ? colors.accent.withValues(alpha: 0.15)
                        : colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.folderOpen,
                    size: 20,
                    color: isActive ? colors.accent : colors.secondary,
                  ),
                ),
                title: Text(
                  project.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                subtitle: project.languageName != null
                    ? Text(project.languageName!)
                    : null,
                trailing: isActive
                    ? Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.check,
                          size: 16,
                          color: colors.accent,
                        ),
                      )
                    : null,
                onTap: () => onProjectSelected(project),
              );
            }),
          ],
        ),
      ),
    );
  }
}
