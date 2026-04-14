import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_snack_bar.dart';
import '../../auth/data/providers/role_provider.dart';
import '../../sync/presentation/notifiers/sync_notifier.dart';
import '../domain/entities/storyteller.dart';
import 'notifiers/project_storytellers_notifier.dart';
import 'widgets/storyteller_tile.dart';

class StorytellersListScreen extends ConsumerStatefulWidget {
  const StorytellersListScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<StorytellersListScreen> createState() =>
      _StorytellersListScreenState();
}

class _StorytellersListScreenState
    extends ConsumerState<StorytellersListScreen> {
  bool get _isManager => ref
      .read(roleNotifierProvider.notifier)
      .canManageProject(widget.projectId);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(projectStorytellersNotifierProvider.notifier)
          .fetch(widget.projectId);
    });
  }

  Future<void> _confirmDelete(Storyteller st) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.storyteller_deleteTitle),
        content: Text(l10n.storyteller_deleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.common_remove),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(projectStorytellersNotifierProvider.notifier)
        .delete(st.id);

    if (!mounted) return;
    if (!success) {
      final error = ref.read(projectStorytellersNotifierProvider).error;
      showErrorSnackBar(context, error ?? l10n.error_generic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(projectStorytellersNotifierProvider);
    final isOnline = ref.watch(syncNotifierProvider).isOnline;
    final canManage = _isManager;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/projects');
            }
          },
        ),
        title: Text(l10n.storyteller_title),
        actions: [
          if (canManage)
            IconButton(
              tooltip: l10n.storyteller_addNew,
              onPressed: isOnline
                  ? () => context.push(
                      '/project/${widget.projectId}/storytellers/new',
                    )
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.storyteller_createRequiresConnection,
                          ),
                        ),
                      );
                    },
              icon: const Icon(LucideIcons.plus),
            ),
        ],
      ),
      body: _buildBody(context, state, l10n, canManage),
    );
  }

  Widget _buildBody(
    BuildContext context,
    dynamic state,
    AppLocalizations l10n,
    bool canManage,
  ) {
    if (state.isLoading && state.storytellers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.storytellers.isEmpty) {
      return EmptyState(
        icon: LucideIcons.users,
        title: l10n.storyteller_empty,
        description: l10n.storyteller_emptyDescription,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(projectStorytellersNotifierProvider.notifier)
          .fetch(widget.projectId),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: state.storytellers.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final st = state.storytellers[i] as Storyteller;
          final tile = StorytellerTile(
            storyteller: st,
            onTap: canManage
                ? () => context.push(
                    '/project/${widget.projectId}/storytellers/${st.id}/edit',
                  )
                : null,
          );
          if (!canManage) return tile;
          return Dismissible(
            key: ValueKey('storyteller-${st.id}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              await _confirmDelete(st);
              return false;
            },
            background: Container(
              color: Theme.of(context).colorScheme.error,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Icon(LucideIcons.trash2, color: Colors.white),
            ),
            child: tile,
          );
        },
      ),
    );
  }
}
