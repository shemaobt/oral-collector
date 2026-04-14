import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/l10n/content_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../genre/presentation/notifiers/genre_notifier.dart';
import '../../../project/presentation/notifiers/member_notifier.dart';
import '../../../project/presentation/widgets/project_member_picker_sheet.dart';
import '../../../storyteller/presentation/notifiers/project_storytellers_notifier.dart';
import '../../../storyteller/presentation/widgets/storyteller_picker.dart';
import '../notifiers/recordings_list_notifier.dart';
import '../notifiers/recordings_list_state.dart';

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
  String? _storytellerId;
  String? _userId;

  @override
  void initState() {
    super.initState();
    final state = ref.read(recordingsListNotifierProvider);
    _status = state.selectedFilter;
    _genreId = state.selectedGenreId;
    _storytellerId = state.selectedStorytellerId;
    _userId = state.selectedUserId;

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
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  _sectionTitle(theme, l10n.filters_sectionStatus),
                  const SizedBox(height: 8),
                  _buildStatusChips(),
                  const SizedBox(height: 24),
                  _sectionTitle(theme, l10n.filters_sectionGenre),
                  const SizedBox(height: 8),
                  _buildGenreChips(l10n),
                  const SizedBox(height: 24),
                  _sectionTitle(theme, l10n.filters_sectionStoryteller),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 24),
                  _sectionTitle(theme, l10n.filters_sectionUser),
                  const SizedBox(height: 8),
                  _buildUserPicker(l10n, colors),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            _buildFooter(context, l10n, colors),
          ],
        );
      },
    );
  }

  Widget _sectionTitle(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
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

  Widget _buildGenreChips(AppLocalizations l10n) {
    final genres = ref.watch(genreNotifierProvider).genres;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(l10n.filter_genreAll),
          selected: _genreId == null,
          onSelected: (_) => setState(() => _genreId = null),
        ),
        ...genres.map(
          (g) => ChoiceChip(
            label: Text(localizedGenreName(l10n, g.name)),
            selected: _genreId == g.id,
            onSelected: (_) => setState(() => _genreId = g.id),
          ),
        ),
      ],
    );
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
      borderRadius: BorderRadius.circular(12),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.mic, size: 18, color: colors.secondary),
            const SizedBox(width: 12),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _status = StatusFilter.all;
                    _genreId = null;
                    _storytellerId = null;
                    _userId = null;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.foreground,
                  disabledForegroundColor: colors.foreground.withValues(
                    alpha: 0.4,
                  ),
                  side: BorderSide(color: colors.border.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                child: Text(l10n.filter_reset),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  final notifier = ref.read(
                    recordingsListNotifierProvider.notifier,
                  );
                  notifier.setStatusFilter(_status);
                  notifier.setGenreFilter(_genreId);
                  await notifier.setStorytellerFilter(_storytellerId);
                  await notifier.setUserFilter(_userId);
                  if (context.mounted) Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: colors.accent.withValues(alpha: 0.3),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
