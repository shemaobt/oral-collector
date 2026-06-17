import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/utils/format.dart';
import '../../domain/entities/project.dart';
import 'language_chip_row.dart';
import 'project_stat_chip.dart';

class ProjectSettingsHeader extends StatelessWidget {
  const ProjectSettingsHeader({
    super.key,
    required this.project,
    required this.memberCount,
    required this.onBack,
  });

  final Project project;
  final int memberCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // The expanded header has fixed top/bottom padding (52 + 16); only the text
    // content grows with the system font, so scale that portion to avoid
    // clipping the title/language row at large text sizes (ENG-180).
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    const fixedPadding = 52.0 + 16.0;
    final expandedHeight = fixedPadding + (140 - fixedPadding) * textScale;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.8),
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.arrowLeft,
            size: 18,
            color: colors.foreground,
          ),
        ),
        onPressed: onBack,
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.accent.withValues(alpha: 0.18),
                colors.primary.withValues(alpha: isDark ? 0.25 : 0.06),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                SpacingScale.s20,
                52,
                SpacingScale.s20,
                SpacingScale.s16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    project.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (project.languageName != null) ...[
                    const SizedBox(height: 6),
                    LanguageChipRow.header(
                      languageName: project.languageName!,
                      languageCode: project.languageCode,
                      colors: colors,
                      theme: theme,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProjectSettingsStatsRow extends StatelessWidget {
  const ProjectSettingsStatsRow({
    super.key,
    required this.project,
    required this.memberCount,
    this.storytellerCount = 0,
  });

  final Project project;
  final int memberCount;
  final int storytellerCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    final chips = [
      ProjectSettingsStatChip(
        icon: LucideIcons.mic,
        value: '${project.recordingCount}',
        label: l10n.projectStats_recordings,
        color: colors.accent,
        colors: colors,
        theme: theme,
      ),
      ProjectSettingsStatChip(
        icon: LucideIcons.clock,
        value: formatDurationCompact(project.totalDurationSeconds),
        label: l10n.projectStats_duration,
        color: colors.info,
        colors: colors,
        theme: theme,
      ),
      ProjectSettingsStatChip(
        icon: LucideIcons.users,
        value: '$memberCount',
        label: l10n.projectStats_members,
        color: colors.success,
        colors: colors,
        theme: theme,
      ),
      ProjectSettingsStatChip(
        icon: LucideIcons.userCheck,
        value: '$storytellerCount',
        label: l10n.storyteller_title,
        color: colors.secondary,
        colors: colors,
        theme: theme,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < chips.length; i++) ...[
          if (i > 0) const SizedBox(width: SpacingScale.s8),
          chips[i],
        ],
      ],
    );
  }
}
