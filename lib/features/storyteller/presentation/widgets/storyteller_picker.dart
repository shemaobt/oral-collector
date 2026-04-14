import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../sync/presentation/notifiers/sync_notifier.dart';
import '../../domain/entities/storyteller.dart';
import '../notifiers/project_storytellers_notifier.dart';
import 'storyteller_tile.dart';

Future<Storyteller?> showStorytellerPickerSheet(
  BuildContext context, {
  required String projectId,
  bool showAddNew = false,
}) {
  return showModalBottomSheet<Storyteller?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) =>
        _StorytellerPickerSheet(projectId: projectId, showAddNew: showAddNew),
  );
}

class StorytellerPicker extends ConsumerWidget {
  final String projectId;
  final Storyteller? selected;
  final ValueChanged<Storyteller?> onChanged;
  final bool showAddNew;

  const StorytellerPicker({
    super.key,
    required this.projectId,
    required this.selected,
    required this.onChanged,
    this.showAddNew = false,
  });

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final result = await showStorytellerPickerSheet(
      context,
      projectId: projectId,
      showAddNew: showAddNew,
    );
    if (result != null) {
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return InkWell(
      onTap: () => _open(context, ref),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.user, size: 18, color: colors.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.detail_storyteller,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.foreground.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selected?.name ?? l10n.storyteller_selectHint,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected == null
                          ? colors.foreground.withValues(alpha: 0.45)
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
}

class _StorytellerPickerSheet extends ConsumerStatefulWidget {
  const _StorytellerPickerSheet({
    required this.projectId,
    required this.showAddNew,
  });

  final String projectId;
  final bool showAddNew;

  @override
  ConsumerState<_StorytellerPickerSheet> createState() =>
      _StorytellerPickerSheetState();
}

class _StorytellerPickerSheetState
    extends ConsumerState<_StorytellerPickerSheet> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final state = ref.read(projectStorytellersNotifierProvider);
      if (state.projectId != widget.projectId || state.storytellers.isEmpty) {
        ref
            .read(projectStorytellersNotifierProvider.notifier)
            .fetch(widget.projectId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(projectStorytellersNotifierProvider);
    final isOnline = ref.watch(syncNotifierProvider).isOnline;
    final colors = AppColors.of(context);

    final q = _query.toLowerCase().trim();
    final list = q.isEmpty
        ? state.storytellers
        : state.storytellers.where((s) {
            return s.name.toLowerCase().contains(q) ||
                (s.location ?? '').toLowerCase().contains(q) ||
                (s.dialect ?? '').toLowerCase().contains(q);
          }).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, controller) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.storyteller_title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                decoration: InputDecoration(
                  hintText: l10n.storyteller_searchPlaceholder,
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            if (state.storytellers.isEmpty && !isOnline)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.storyteller_offlineNoCache,
                  style: TextStyle(color: colors.error),
                ),
              ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: EdgeInsets.zero,
                children: [
                  if (widget.showAddNew && isOnline)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: colors.accent.withValues(alpha: 0.15),
                        foregroundColor: colors.accent,
                        child: const Icon(LucideIcons.plus, size: 18),
                      ),
                      title: Text(l10n.storyteller_addNew),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push(
                          '/project/${widget.projectId}/storytellers/new',
                        );
                      },
                    ),
                  if (state.isLoading && list.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ...list.map(
                    (s) => StorytellerTile(
                      storyteller: s,
                      onTap: () => Navigator.of(context).pop(s),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
