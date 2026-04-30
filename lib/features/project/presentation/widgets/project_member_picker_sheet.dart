import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/project_member.dart';
import '../notifiers/member_notifier.dart';

class _SelectAllSentinel extends ProjectMember {
  const _SelectAllSentinel()
    : super(id: '__all__', projectId: '', userId: '', email: '');
}

const selectAllMember = _SelectAllSentinel();

Future<ProjectMember?> showProjectMemberPickerSheet(
  BuildContext context, {
  required String projectId,
  ProjectMember? selected,
  bool includeAll = true,
}) {
  return showModalBottomSheet<ProjectMember?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ProjectMemberPickerSheet(
      projectId: projectId,
      selectedUserId: selected?.userId,
      includeAll: includeAll,
    ),
  );
}

class _ProjectMemberPickerSheet extends ConsumerStatefulWidget {
  const _ProjectMemberPickerSheet({
    required this.projectId,
    required this.selectedUserId,
    required this.includeAll,
  });

  final String projectId;
  final String? selectedUserId;
  final bool includeAll;

  @override
  ConsumerState<_ProjectMemberPickerSheet> createState() =>
      _ProjectMemberPickerSheetState();
}

class _ProjectMemberPickerSheetState
    extends ConsumerState<_ProjectMemberPickerSheet> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final state = ref.read(memberNotifierProvider);
      if (state.members.isEmpty) {
        ref
            .read(memberNotifierProvider.notifier)
            .fetchMembers(widget.projectId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(memberNotifierProvider);

    final q = _query.trim().toLowerCase();
    final members = q.isEmpty
        ? state.members
        : state.members.where((m) {
            return (m.displayName ?? '').toLowerCase().contains(q) ||
                m.email.toLowerCase().contains(q);
          }).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
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
                      l10n.filters_sectionUser,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                autofocus: false,
                decoration: InputDecoration(
                  hintText: l10n.storyteller_searchPlaceholder,
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 8),
            if (state.isLoading && state.members.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  itemCount:
                      members.length + (widget.includeAll && q.isEmpty ? 1 : 0),
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    if (widget.includeAll && q.isEmpty && index == 0) {
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                        ),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: colors.accent.withValues(
                            alpha: 0.15,
                          ),
                          foregroundColor: colors.accent,
                          child: const Icon(LucideIcons.users, size: 18),
                        ),
                        title: Text(
                          l10n.filter_userAll,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: widget.selectedUserId == null
                            ? Icon(LucideIcons.check, color: colors.accent)
                            : null,
                        onTap: () => Navigator.of(context).pop(selectAllMember),
                      );
                    }
                    final i = widget.includeAll && q.isEmpty
                        ? index - 1
                        : index;
                    final m = members[i];
                    final label = m.displayName ?? m.email;
                    final initial = label.isEmpty
                        ? '?'
                        : label.substring(0, 1).toUpperCase();
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: colors.info.withValues(alpha: 0.15),
                        foregroundColor: colors.info,
                        child: Text(
                          initial,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.info,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(
                        label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: m.displayName != null
                          ? Text(
                              m.email,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.foreground.withValues(alpha: 0.6),
                              ),
                            )
                          : null,
                      trailing: widget.selectedUserId == m.userId
                          ? Icon(LucideIcons.check, color: colors.accent)
                          : null,
                      onTap: () => Navigator.of(context).pop(m),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
