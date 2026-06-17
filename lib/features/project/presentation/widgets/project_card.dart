import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palettes.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/utils/format.dart';
import '../../domain/entities/project.dart';
import 'language_chip_row.dart';

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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardAccent = AppPalettes.projectAccent(colorIndex);

    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingScale.s16),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(RadiusScale.r20),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(RadiusScale.r20),
              border: isActive
                  ? Border.all(color: colors.accent, width: 2)
                  : Border.all(
                      color: colors.border.withValues(alpha: 0.2),
                      width: 1,
                    ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: isDark ? 0.3 : 0.06),
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
                  padding: const EdgeInsets.fromLTRB(
                    SpacingScale.s20,
                    SpacingScale.s16,
                    SpacingScale.s16,
                    SpacingScale.s20,
                  ),
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
                              borderRadius: BorderRadius.circular(
                                RadiusScale.r12,
                              ),
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
                          const SizedBox(width: SpacingScale.s16),
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
                                const SizedBox(height: SpacingScale.s4),
                                if (project.languageName != null)
                                  LanguageChipRow.card(
                                    languageName: project.languageName!,
                                    languageCode: project.languageCode,
                                    colors: colors,
                                    theme: theme,
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
                      const SizedBox(height: SpacingScale.s16),
                      Wrap(
                        spacing: SpacingScale.s8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ProjectStatChip(
                            icon: LucideIcons.users,
                            value: '${project.memberCount}',
                            colors: colors,
                            theme: theme,
                          ),
                          ProjectStatChip(
                            icon: LucideIcons.mic,
                            value: '${project.recordingCount}',
                            colors: colors,
                            theme: theme,
                          ),
                          ProjectStatChip(
                            icon: LucideIcons.clock,
                            value: formatDurationCompact(
                              project.totalDurationSeconds,
                            ),
                            colors: colors,
                            theme: theme,
                          ),
                          ProjectStatChip(
                            icon: LucideIcons.userCheck,
                            value: '${project.storytellerCount}',
                            colors: colors,
                            theme: theme,
                          ),
                          if (isActive) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SpacingScale.s8,
                                vertical: SpacingScale.s4,
                              ),
                              decoration: BoxDecoration(
                                color: colors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(
                                  RadiusScale.r8,
                                ),
                              ),
                              child: Text(
                                l10n.project_active,
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
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingScale.s8,
        vertical: SpacingScale.s4,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceAlt.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(RadiusScale.r8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.secondary),
          const SizedBox(width: SpacingScale.s4),
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
