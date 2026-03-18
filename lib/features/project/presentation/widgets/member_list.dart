import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../presentation/notifiers/member_notifier.dart';
import '../../domain/entities/project_member.dart';
import 'member_tile.dart';

class MemberList extends ConsumerWidget {
  const MemberList({super.key, required this.projectId, this.onRemove});

  final String projectId;
  final void Function(ProjectMember member)? onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberState = ref.watch(memberNotifierProvider);

    if (memberState.isLoading && memberState.members.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (memberState.members.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text(l10n.projectSettings_noMembers)),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          for (int i = 0; i < memberState.members.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            MemberTile(
              member: memberState.members[i],
              onRemove: onRemove != null
                  ? () => onRemove!(memberState.members[i])
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}
