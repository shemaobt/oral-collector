import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../invite/presentation/notifiers/invite_state.dart';
import '../../../invite/domain/entities/invite.dart';
import 'invite_tile.dart';

class InvitationsSection extends StatelessWidget {
  const InvitationsSection({
    super.key,
    required this.inviteState,
    required this.onAccept,
    required this.onDecline,
    required this.onRefresh,
  });

  final InviteState inviteState;
  final Future<void> Function(Invite invite) onAccept;
  final Future<void> Function(Invite invite) onDecline;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: SectionHeader(title: l10n.profile_invitations)),
            IconButton(
              icon: Icon(
                LucideIcons.refreshCw,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: onRefresh,
              tooltip: l10n.profile_refreshInvitations,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (inviteState.isLoading)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (inviteState.error != null)
          _ErrorCard(
            message: friendlyErrorMessage(inviteState.error!),
            onRetry: onRefresh,
          )
        else if (inviteState.invites.isEmpty)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  l10n.profile_noInvitations,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
          )
        else
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (var i = 0; i < inviteState.invites.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  InviteTile(
                    invite: inviteState.invites[i],
                    onAccept: () => onAccept(inviteState.invites[i]),
                    onDecline: () => onDecline(inviteState.invites[i]),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: errorColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: errorColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(LucideIcons.wifiOff, size: 18, color: errorColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: errorColor,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
