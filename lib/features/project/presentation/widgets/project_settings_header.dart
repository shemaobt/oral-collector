import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/utils/format.dart';
import '../../../recording/domain/entities/review_pendency.dart';
import '../../../recording/presentation/pendency_label.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/project_stats.dart';
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
          padding: const EdgeInsets.all(SpacingScale.s8),
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
                    const SizedBox(height: SpacingScale.s8),
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

/// The project's counters, in two rows rather than one (ENG-374).
///
/// The split is the point: "how much audio is here" and "who takes part" are
/// different questions, and a single row of four chips invited the reader to
/// scan them as one list.
class ProjectSettingsStatsSection extends StatelessWidget {
  const ProjectSettingsStatsSection({
    super.key,
    required this.project,
    required this.memberCount,
    this.storytellerCount = 0,
    this.stats,
    required this.onPendencyTap,
  });

  final Project project;
  final int memberCount;
  final int storytellerCount;

  /// Null when the best-effort stats fetch failed. The audio row then leaves
  /// the pendency counter out rather than inventing one.
  final ProjectStats? stats;

  /// Opens the recordings list narrowed to one pendency (ENG-381).
  ///
  /// The headline counter above the breakdown stays untappable: the server
  /// filters by one code at a time and has no "anything outstanding" filter, so
  /// a target on that number would have to stitch three paged queries together
  /// and would disagree with the number itself past the first page.
  final void Function(PendencyKind kind) onPendencyTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AudioStatsRow(
          project: project,
          stats: stats,
          onPendencyTap: onPendencyTap,
        ),
        const SizedBox(height: SpacingScale.s16),
        _TeamStatsRow(
          memberCount: memberCount,
          storytellerCount: storytellerCount,
        ),
      ],
    );
  }
}

class _AudioStatsRow extends StatelessWidget {
  const _AudioStatsRow({
    required this.project,
    required this.stats,
    required this.onPendencyTap,
  });

  final Project project;
  final ProjectStats? stats;
  final void Function(PendencyKind kind) onPendencyTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final needingDetails = stats?.recordingsWithReviewFlags;
    // The breakdown only reads as a breakdown of something. A server that sent
    // the per-code map without the distinct count would otherwise put labelled
    // numbers on screen with no counter above them to belong to.
    final byKind = needingDetails == null
        ? const <PendencyKind, int>{}
        : _breakdownByKind(stats?.reviewFlagCounts ?? const {});

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ProjectSettingsStatChip(
              icon: LucideIcons.mic,
              value: '${project.recordingCount}',
              label: l10n.projectStats_recordings,
              color: colors.accent,
              colors: colors,
              theme: theme,
            ),
            const SizedBox(width: SpacingScale.s8),
            ProjectSettingsStatChip(
              icon: LucideIcons.clock,
              value: formatDurationCompact(project.totalDurationSeconds),
              label: l10n.projectStats_duration,
              color: colors.info,
              colors: colors,
              theme: theme,
            ),
            if (needingDetails != null) ...[
              const SizedBox(width: SpacingScale.s8),
              ProjectSettingsStatChip(
                icon: LucideIcons.clipboardList,
                // The server's count of distinct recordings. Adding up
                // reviewFlagCounts instead would over-report: a recording with
                // three open fields appears under three codes.
                value: '$needingDetails',
                label: l10n.projectStats_needsDetails,
                color: colors.primary,
                colors: colors,
                theme: theme,
              ),
            ],
          ],
        ),
        if (byKind.isNotEmpty) ...[
          const SizedBox(height: SpacingScale.s4),
          _PendencyBreakdown(byKind: byKind, onTap: onPendencyTap),
        ],
      ],
    );
  }
}

/// The per-pendency lines under the review counter.
///
/// Right-aligned, under the counter chip they explain. Across the full width
/// they read as a partition of the counter, and these labels do not partition
/// anything: a recording missing both a classification and a storyteller is
/// counted under both, so three such recordings show "3", "3" and a headline of
/// 3. Sitting under the chip, they read as notes on that number instead.
///
/// One per line rather than flowed: each is a tap target now, and two 48dp
/// targets side by side are hard to tell apart and easy to miss.
class _PendencyBreakdown extends StatelessWidget {
  const _PendencyBreakdown({required this.byKind, required this.onTap});

  final Map<PendencyKind, int> byKind;
  final void Function(PendencyKind kind) onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final entry in byKind.entries)
            _PendencyBreakdownLine(
              label: pendencyLabel(l10n, entry.key),
              count: entry.value,
              onTap: () => onTap(entry.key),
            ),
        ],
      ),
    );
  }
}

class _PendencyBreakdownLine extends StatelessWidget {
  const _PendencyBreakdownLine({
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    final text = Text(
      '$label: $count',
      textAlign: TextAlign.end,
      style: theme.textTheme.labelSmall?.copyWith(color: colors.secondary),
    );

    // The label has to land on the node that carries the tap action, which is
    // the InkWell's. `excludeSemantics` would throw that node away and leave a
    // node that says "button" and does nothing when double-tapped; merging
    // keeps the action and replaces only the visible text.
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: l10n.projectStats_showPendency(label, count),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(RadiusScale.r8),
          child: ConstrainedBox(
            // A tap target has to be reachable by a thumb, not just by a mouse.
            constraints: const BoxConstraints(minHeight: 48),
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingScale.s4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: text),
                    const SizedBox(width: SpacingScale.s4),
                    // Colour alone must not be what says "this does something"
                    // (WCAG 1.4.1): the chevron carries it without depending on
                    // hue, and reads as a way in rather than a decoration.
                    Icon(
                      LucideIcons.chevronRight,
                      size: 14,
                      color: colors.secondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamStatsRow extends StatelessWidget {
  const _TeamStatsRow({
    required this.memberCount,
    required this.storytellerCount,
  });

  final int memberCount;
  final int storytellerCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return Row(
      children: [
        ProjectSettingsStatChip(
          icon: LucideIcons.users,
          value: '$memberCount',
          label: l10n.projectStats_members,
          color: colors.success,
          colors: colors,
          theme: theme,
        ),
        const SizedBox(width: SpacingScale.s8),
        ProjectSettingsStatChip(
          icon: LucideIcons.userCheck,
          value: '$storytellerCount',
          label: l10n.storyteller_title,
          color: colors.secondary,
          colors: colors,
          theme: theme,
        ),
      ],
    );
  }
}

/// The per-code counters this build can name, in a fixed order.
///
/// A code [pendencyKindForCode] does not know is dropped: the raw wire string
/// is not something to put in front of a field worker. It is dropped from the
/// breakdown only — the headline counter comes from the server's distinct
/// count, so a recording held up by an unknown code still shows up there.
Map<PendencyKind, int> _breakdownByKind(Map<String, int> counts) {
  final byKind = <PendencyKind, int>{};
  counts.forEach((code, count) {
    final kind = pendencyKindForCode(code);
    if (kind != null) byKind[kind] = (byKind[kind] ?? 0) + count;
  });
  return {
    for (final kind in PendencyKind.values)
      if (byKind.containsKey(kind)) kind: byKind[kind]!,
  };
}
