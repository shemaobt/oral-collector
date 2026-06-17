import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../invite/domain/entities/invite.dart';

class InviteTile extends StatelessWidget {
  const InviteTile({
    super.key,
    required this.invite,
    required this.onAccept,
    required this.onDecline,
  });

  final Invite invite;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingScale.s16,
        vertical: SpacingScale.s12,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.tertiary.withValues(alpha: 0.15),
            child: Icon(
              LucideIcons.folderOpen,
              size: 20,
              color: theme.colorScheme.tertiary,
            ),
          ),
          const SizedBox(width: SpacingScale.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.projectName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  invite.role == 'manager'
                      ? l10n.profile_roleManager
                      : l10n.profile_roleMember,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: SpacingScale.s8),
          SizedBox(
            height: 36,
            child: OutlinedButton(
              onPressed: onDecline,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.error,
                side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingScale.s12,
                ),
              ),
              child: Text(l10n.profile_decline),
            ),
          ),
          const SizedBox(width: SpacingScale.s8),
          SizedBox(
            height: 36,
            child: FilledButton(
              onPressed: onAccept,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingScale.s12,
                ),
              ),
              child: Text(l10n.profile_accept),
            ),
          ),
        ],
      ),
    );
  }
}
