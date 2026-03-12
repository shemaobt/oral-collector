import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../domain/entities/project_member.dart';

class MemberTile extends StatelessWidget {
  const MemberTile({super.key, required this.member, this.onRemove});

  final ProjectMember member;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final name = member.displayName ?? member.email;

    return ListTile(
      leading: UserAvatar(
        radius: 20,
        avatarUrl: member.avatarUrl,
        displayName: member.displayName,
        email: member.email,
      ),
      title: Text(
        name,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: member.displayName != null
          ? Text(
              member.email,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.secondary,
              ),
            )
          : null,
      trailing: onRemove != null
          ? IconButton(
              icon: Icon(LucideIcons.userMinus, size: 18, color: colors.error),
              onPressed: onRemove,
              tooltip: 'Remove member',
            )
          : null,
    );
  }
}
