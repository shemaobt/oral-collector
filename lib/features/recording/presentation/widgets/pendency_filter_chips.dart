import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../project/presentation/notifiers/project_stats_provider.dart';
import '../../domain/entities/review_pendency.dart';
import '../notifiers/recordings_list_notifier.dart';
import '../pendency_label.dart';

/// A shortcut to the pendency filter the sheet already owns.
///
/// It writes the same field on the list notifier the sheet writes, and reads it
/// back to decide what is selected. That is the whole reason the two agree: a
/// pendency picked here is already selected when the sheet opens, and one
/// picked in the sheet lights the matching chip on the way out. A copy of the
/// selection living here would be a second answer to one question.
class PendencyFilterChips extends ConsumerWidget {
  const PendencyFilterChips({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(
      recordingsListNotifierProvider.select((s) => s.selectedReviewFlag),
    );
    final notifier = ref.read(recordingsListNotifierProvider.notifier);

    // Counts are the project's, not the visible list's: they come from the same
    // aggregate the project screen shows, so the two surfaces never quote
    // different numbers for the same question. Under another filter — a genre,
    // a narrower status — the chip therefore counts more recordings than the
    // list ends up showing. It answers "how much does this project still owe",
    // which is the question that sends someone to this row in the first place.
    final counts = ref
        .watch(projectStatsProvider(projectId))
        .valueOrNull
        ?.reviewFlagCounts;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        SpacingScale.s16,
        SpacingScale.s12,
        SpacingScale.s16,
        SpacingScale.s4,
      ),
      child: Row(
        children: [
          _PendencyChip(
            label: l10n.filter_pendencyAll,
            selected: selected == null,
            onSelected: () => notifier.setReviewFlagFilter(null),
          ),
          for (final kind in PendencyKind.values) ...[
            const SizedBox(width: SpacingScale.s8),
            _PendencyChip(
              label: pendencyLabel(l10n, kind),
              // Absent from the map means nobody carries the flag, which is a
              // zero the user can act on — unlike a missing aggregate, where
              // the honest answer is to say nothing.
              count: counts == null
                  ? null
                  : counts[reviewFlagCodeFor(kind)] ?? 0,
              selected: selected == kind,
              onSelected: () => notifier.setReviewFlagFilter(kind),
            ),
          ],
        ],
      ),
    );
  }
}

class _PendencyChip extends StatelessWidget {
  const _PendencyChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.count,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final badgeCount = count;

    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onSelected(),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (badgeCount != null) ...[
            const SizedBox(width: SpacingScale.s8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingScale.s8,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? colors.onPrimary.withValues(alpha: 0.25)
                    : colors.chipSurface,
                borderRadius: BorderRadius.circular(RadiusScale.r12),
              ),
              child: Text(
                '$badgeCount',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
