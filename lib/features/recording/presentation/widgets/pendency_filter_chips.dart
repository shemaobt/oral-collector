import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
        SpacingScale.s8,
        SpacingScale.s16,
        0,
      ),
      child: Row(
        children: [
          _PendencyChip(
            // No glyph: "all" names no field, and the design package gives it
            // none for that reason.
            label: l10n.filter_pendencyAll,
            selected: selected == null,
            onSelected: () => notifier.setReviewFlagFilter(null),
          ),
          for (final kind in PendencyKind.values) ...[
            const SizedBox(width: SpacingScale.s4),
            _PendencyChip(
              label: pendencyLabel(l10n, kind),
              icon: _glyphFor(kind),
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

/// The same glyphs the card's pendency chip uses, so one field is one shape
/// wherever the user meets it.
IconData _glyphFor(PendencyKind kind) => switch (kind) {
  PendencyKind.classification => LucideIcons.tag,
  PendencyKind.description => LucideIcons.fileText,
  PendencyKind.storyteller => LucideIcons.userMinus,
};

/// A pill the size the design package draws it.
///
/// Material's own `ChoiceChip` metrics are what made the row read as
/// oversized: a 32px label box inside a 48px tap target, plus a checkmark on
/// the selected one. Everything below overrides that down to the package's
/// `6px 10px` pill — snapped to the 4px scale the codebase keeps
/// (`lib/core/theme/app_spacing.dart`), which lands one step tighter.
///
/// **This costs the tap target.** A ~24px-tall chip is below the 44px both
/// platform guidelines ask for; `MaterialTapTargetSize.padded` would restore it
/// without changing how the chip looks, at the price of a row half again as
/// tall. The design is explicit about the density, so the density wins here and
/// the trade is written down rather than discovered later.
class _PendencyChip extends StatelessWidget {
  const _PendencyChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.count,
  });

  final String label;
  final IconData? icon;
  final int? count;
  final bool selected;
  final VoidCallback onSelected;

  static const double _iconSize = 12;
  static const double _fontSize = 11.5;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final glyph = icon;
    final badgeCount = count;
    final ink = selected ? colors.onPrimary : colors.secondary;

    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      shape: const StadiumBorder(),
      side: BorderSide.none,
      backgroundColor: colors.surfaceAlt,
      selectedColor: colors.primary,
      labelPadding: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingScale.s8,
        vertical: SpacingScale.s4,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelStyle: TextStyle(
        fontSize: _fontSize,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (glyph != null) ...[
            Icon(glyph, size: _iconSize, color: ink),
            const SizedBox(width: SpacingScale.s4),
          ],
          Text(label),
          if (badgeCount != null) ...[
            const SizedBox(width: SpacingScale.s4),
            Text(
              '$badgeCount',
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.w800,
                // The count is the one thing on the chip that outranks its
                // label, so it takes the stronger ink rather than a box.
                color: selected ? colors.onPrimary : colors.foreground,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
