import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/l10n/content_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../genre/presentation/notifiers/genre_notifier.dart';
import '../../../project/presentation/notifiers/member_notifier.dart';
import '../../../project/presentation/widgets/project_member_picker_sheet.dart';
import '../../../storyteller/presentation/notifiers/project_storytellers_notifier.dart';
import '../../../storyteller/presentation/widgets/storyteller_picker.dart';
import '../../domain/entities/review_pendency.dart';
import '../notifiers/recordings_list_notifier.dart';
import '../notifiers/recordings_list_state.dart';
import '../pendency_label.dart';

/// One labelled group of controls in the filter sheet.
///
/// A real subtree rather than a header and its controls sitting as siblings,
/// because the sheet has two sections whose chips read the same. "Unclassified"
/// (status) and "No classification" (pendency) are word-for-word identical in
/// seven of the eleven languages, and so are their description counterparts, so
/// which section a chip belongs to is the only thing that says what it does —
/// on screen and to a test.
///
/// [hint] is the supporting line those two sections carry. The difference
/// between them is where the answer comes from: one sieves the recordings
/// already on screen and holds up with no network, the other is a question for
/// the server. Neither is redundant — the offline one is the one that still
/// works in the field.
class FilterSection extends StatelessWidget {
  const FilterSection({
    super.key,
    required this.title,
    required this.child,
    this.hint,
  });

  final String title;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final hintText = hint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        if (hintText != null) ...[
          const SizedBox(height: 2),
          Text(
            hintText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.foreground.withValues(alpha: 0.6),
            ),
          ),
        ],
        const SizedBox(height: SpacingScale.s8),
        child,
      ],
    );
  }
}

class RecordingsFilterSheet extends ConsumerStatefulWidget {
  const RecordingsFilterSheet({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<RecordingsFilterSheet> createState() =>
      _RecordingsFilterSheetState();
}

class _RecordingsFilterSheetState extends ConsumerState<RecordingsFilterSheet> {
  late StatusFilter _status;
  String? _genreId;

  /// Carried, not shown. A subcategory only ever arrives with the genre it
  /// belongs to (`/recordings?genreId=…&subcategoryId=…`), and it counts
  /// towards the badge, so the sheet has to be able to keep it across an Apply
  /// and drop it on a Reset — but a control of its own would ask the user to
  /// pick a refinement of a genre they may not have chosen.
  String? _subcategoryId;
  String? _storytellerId;
  String? _userId;
  PendencyKind? _reviewFlag;

  @override
  void initState() {
    super.initState();
    final state = ref.read(recordingsListNotifierProvider);
    _status = state.selectedFilter;
    _genreId = state.selectedGenreId;
    _subcategoryId = state.selectedSubcategoryId;
    _storytellerId = state.selectedStorytellerId;
    _userId = state.selectedUserId;
    _reviewFlag = state.selectedReviewFlag;

    Future.microtask(() {
      ref
          .read(projectStorytellersNotifierProvider.notifier)
          .fetch(widget.projectId);
      ref.read(memberNotifierProvider.notifier).fetchMembers(widget.projectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.45,
      maxChildSize: 0.9,
      builder: (context, controller) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SpacingScale.s20,
                SpacingScale.s16,
                SpacingScale.s8,
                SpacingScale.s4,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.filters_sheetTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(
                  SpacingScale.s20,
                  SpacingScale.s12,
                  SpacingScale.s20,
                  SpacingScale.s20,
                ),
                children: [
                  FilterSection(
                    title: l10n.filters_sectionStatus,
                    hint: l10n.filters_sectionStatusHint,
                    child: _buildStatusChips(),
                  ),
                  const SizedBox(height: SpacingScale.s24),
                  FilterSection(
                    title: l10n.filters_sectionPendency,
                    hint: l10n.filters_sectionPendencyHint,
                    child: _buildPendencyChips(l10n),
                  ),
                  const SizedBox(height: SpacingScale.s24),
                  FilterSection(
                    title: l10n.filters_sectionGenre,
                    child: _buildGenreChips(l10n),
                  ),
                  const SizedBox(height: SpacingScale.s24),
                  FilterSection(
                    title: l10n.filters_sectionStoryteller,
                    child: _buildStorytellerPicker(l10n),
                  ),
                  const SizedBox(height: SpacingScale.s24),
                  FilterSection(
                    title: l10n.filters_sectionUser,
                    child: _buildUserPicker(l10n, colors),
                  ),
                  const SizedBox(height: SpacingScale.s40),
                ],
              ),
            ),
            _buildFooter(context, l10n, colors),
          ],
        );
      },
    );
  }

  Widget _buildStorytellerPicker(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StorytellerPicker(
          projectId: widget.projectId,
          selected: ref
              .watch(projectStorytellersNotifierProvider)
              .storytellers
              .where((s) => s.id == _storytellerId)
              .firstOrNull,
          onChanged: (s) => setState(() => _storytellerId = s?.id),
          showAddNew: false,
        ),
        if (_storytellerId != null)
          TextButton.icon(
            onPressed: () => setState(() => _storytellerId = null),
            icon: const Icon(LucideIcons.x, size: 14),
            label: Text(l10n.filter_storytellerAll),
          ),
      ],
    );
  }

  Widget _buildStatusChips() {
    final l10n = AppLocalizations.of(context);
    final options = [
      (StatusFilter.all, l10n.filter_all),
      (StatusFilter.pending, l10n.filter_pending),
      (StatusFilter.uploaded, l10n.filter_uploaded),
      (StatusFilter.needsCleaning, l10n.filter_needsCleaning),
      (StatusFilter.unclassified, l10n.filter_unclassified),
      (StatusFilter.missingDescription, l10n.filter_missingDescription),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (opt) => ChoiceChip(
              label: Text(opt.$2),
              selected: _status == opt.$1,
              onSelected: (_) => setState(() => _status = opt.$1),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPendencyChips(AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(l10n.filter_pendencyAll),
          selected: _reviewFlag == null,
          onSelected: (_) => setState(() => _reviewFlag = null),
        ),
        ...PendencyKind.values.map(
          (kind) => ChoiceChip(
            label: Text(pendencyLabel(l10n, kind)),
            selected: _reviewFlag == kind,
            onSelected: (_) => setState(() => _reviewFlag = kind),
          ),
        ),
      ],
    );
  }

  Widget _buildGenreChips(AppLocalizations l10n) {
    final genres = ref.watch(genreNotifierProvider).genres;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(l10n.filter_genreAll),
          selected: _genreId == null,
          onSelected: (_) => _selectGenre(null),
        ),
        ...genres.map(
          (g) => ChoiceChip(
            label: Text(localizedGenreName(l10n, g.name, id: g.id)),
            selected: _genreId == g.id,
            onSelected: (_) => _selectGenre(g.id),
          ),
        ),
      ],
    );
  }

  /// Picking a genre discards the subcategory: it names a refinement of the
  /// genre it came with, and under a different genre it would narrow the list
  /// to nothing while the badge counted it.
  void _selectGenre(String? genreId) {
    setState(() {
      if (genreId != _genreId) _subcategoryId = null;
      _genreId = genreId;
    });
  }

  Widget _buildUserPicker(AppLocalizations l10n, AppColorSet colors) {
    final theme = Theme.of(context);
    final members = ref.watch(memberNotifierProvider).members;
    final selected = _userId == null
        ? null
        : members.where((m) => m.userId == _userId).firstOrNull;
    final label = selected == null
        ? l10n.filter_userAll
        : (selected.displayName ?? selected.email);

    return InkWell(
      borderRadius: BorderRadius.circular(RadiusScale.r12),
      onTap: () async {
        final picked = await showProjectMemberPickerSheet(
          context,
          projectId: widget.projectId,
          selected: selected,
        );
        if (picked == null) return;
        setState(() {
          _userId = picked.userId.isEmpty ? null : picked.userId;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(SpacingScale.s16),
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(RadiusScale.r12),
          border: Border.all(color: colors.border.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.mic, size: 18, color: colors.secondary),
            const SizedBox(width: SpacingScale.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.filters_sectionUser,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.foreground.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _userId == null
                          ? colors.foreground.withValues(alpha: 0.55)
                          : colors.foreground,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronDown,
              size: 18,
              color: colors.foreground.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    AppLocalizations l10n,
    AppColorSet colors,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        SpacingScale.s20,
        SpacingScale.s12,
        SpacingScale.s20,
        SpacingScale.s20,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: SpacingScale.s48,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _status = StatusFilter.all;
                    _genreId = null;
                    // Reset has to reach every filter the badge counts, and it
                    // counts the subcategory too.
                    _subcategoryId = null;
                    _storytellerId = null;
                    _userId = null;
                    _reviewFlag = null;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.foreground,
                  disabledForegroundColor: colors.foreground.withValues(
                    alpha: 0.4,
                  ),
                  side: BorderSide(color: colors.border.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RadiusScale.r12),
                  ),
                  textStyle: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                child: Text(l10n.filter_reset),
              ),
            ),
          ),
          const SizedBox(width: SpacingScale.s12),
          Expanded(
            child: SizedBox(
              height: SpacingScale.s48,
              child: ElevatedButton(
                onPressed: () async {
                  final notifier = ref.read(
                    recordingsListNotifierProvider.notifier,
                  );
                  notifier.setStatusFilter(_status);
                  notifier.setGenreFilter(_genreId);
                  notifier.setSubcategoryFilter(_subcategoryId);
                  // refresh: false — the pendency is a server-side filter, but
                  // it is in state before the two setters below, and each of
                  // those refetches. Letting it fetch too would ask three
                  // times for one Apply.
                  await notifier.setReviewFlagFilter(
                    _reviewFlag,
                    refresh: false,
                  );
                  await notifier.setStorytellerFilter(_storytellerId);
                  await notifier.setUserFilter(_userId);
                  if (context.mounted) Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: colors.accent.withValues(alpha: 0.3),
                  disabledForegroundColor: AppColors.white.withValues(
                    alpha: 0.8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RadiusScale.r12),
                  ),
                  elevation: 0,
                  textStyle: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                child: Text(l10n.filter_apply),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
