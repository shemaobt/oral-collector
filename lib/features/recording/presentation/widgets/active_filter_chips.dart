import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/l10n/content_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../genre/presentation/notifiers/genre_notifier.dart';
import '../../../project/presentation/notifiers/member_notifier.dart';
import '../../../storyteller/presentation/notifiers/project_storytellers_notifier.dart';
import '../notifiers/recordings_list_notifier.dart';
import '../notifiers/recordings_list_state.dart';

class ActiveFilterChips extends ConsumerWidget {
  const ActiveFilterChips({super.key});

  String _statusLabel(AppLocalizations l10n, StatusFilter f) {
    switch (f) {
      case StatusFilter.all:
        return l10n.filter_all;
      case StatusFilter.pending:
        return l10n.filter_pending;
      case StatusFilter.uploaded:
        return l10n.filter_uploaded;
      case StatusFilter.needsCleaning:
        return l10n.filter_needsCleaning;
      case StatusFilter.unclassified:
        return l10n.filter_unclassified;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final state = ref.watch(recordingsListNotifierProvider);
    final notifier = ref.read(recordingsListNotifierProvider.notifier);

    if (state.activeFilterCount == 0) return const SizedBox.shrink();

    final chips = <Widget>[];

    if (state.selectedFilter != StatusFilter.all) {
      chips.add(
        _buildChip(
          context,
          label: _statusLabel(l10n, state.selectedFilter),
          onRemove: () => notifier.setStatusFilter(StatusFilter.all),
        ),
      );
    }

    if (state.selectedGenreId != null) {
      final genres = ref.watch(genreNotifierProvider).genres;
      final genre = genres
          .where((g) => g.id == state.selectedGenreId)
          .firstOrNull;
      final label = genre != null
          ? localizedGenreName(l10n, genre.name)
          : l10n.filters_sectionGenre;
      chips.add(
        _buildChip(
          context,
          label: label,
          onRemove: () => notifier.setGenreFilter(null),
        ),
      );
    }

    if (state.selectedStorytellerId != null) {
      final storytellers = ref
          .watch(projectStorytellersNotifierProvider)
          .storytellers;
      final st = storytellers
          .where((s) => s.id == state.selectedStorytellerId)
          .firstOrNull;
      final label = st != null ? st.name : l10n.filters_sectionStoryteller;
      chips.add(
        _buildChip(
          context,
          label: label,
          onRemove: () => notifier.setStorytellerFilter(null),
        ),
      );
    }

    if (state.selectedUserId != null) {
      final members = ref.watch(memberNotifierProvider).members;
      final m = members
          .where((x) => x.userId == state.selectedUserId)
          .firstOrNull;
      final label = m != null
          ? (m.displayName ?? m.email)
          : l10n.filters_sectionUser;
      chips.add(
        _buildChip(
          context,
          label: label,
          onRemove: () => notifier.setUserFilter(null),
        ),
      );
    }

    if (state.activeFilterCount >= 2) {
      chips.add(
        TextButton.icon(
          onPressed: notifier.clearAllFilters,
          icon: Icon(LucideIcons.x, size: 14, color: colors.error),
          label: Text(
            l10n.filter_clearAll,
            style: TextStyle(color: colors.error, fontSize: 12),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: chips,
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required VoidCallback onRemove,
  }) {
    final colors = AppColors.of(context);
    return InputChip(
      label: Text(label, overflow: TextOverflow.ellipsis),
      onDeleted: onRemove,
      deleteIcon: const Icon(LucideIcons.x, size: 14),
      backgroundColor: colors.accent.withValues(alpha: 0.1),
      side: BorderSide(color: colors.accent.withValues(alpha: 0.3)),
      labelStyle: TextStyle(
        color: colors.accent,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      deleteIconColor: colors.accent,
      visualDensity: VisualDensity.compact,
    );
  }
}
