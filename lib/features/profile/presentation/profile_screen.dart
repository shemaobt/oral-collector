import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/data/providers/auth_provider.dart';
import '../../invite/data/providers/invite_provider.dart';
import '../../invite/domain/entities/invite.dart';
import '../../project/data/providers/project_provider.dart';
import '../../sync/data/providers/sync_provider.dart';

/// Profile screen with sync settings section, manual sync trigger, and logout.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final syncState = ref.watch(syncNotifierProvider);
    final inviteState = ref.watch(inviteNotifierProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // User info card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(
                    LucideIcons.user,
                    size: 28,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authState.currentUser?.displayName ?? 'User',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (authState.currentUser?.email != null)
                        Text(
                          authState.currentUser!.email,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.secondary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Invitations section
        _InvitationsSection(
          inviteState: inviteState,
          onAccept: (invite) async {
            final accepted = await ref
                .read(inviteNotifierProvider.notifier)
                .acceptInvite(invite.id);
            if (accepted && context.mounted) {
              ref.read(projectNotifierProvider.notifier).fetchProjects();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Joined "${invite.projectName}" successfully',
                  ),
                ),
              );
            }
          },
          onDecline: (invite) async {
            final declined = await ref
                .read(inviteNotifierProvider.notifier)
                .declineInvite(invite.id);
            if (declined && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invite declined')),
              );
            }
          },
          onRefresh: () {
            ref.read(inviteNotifierProvider.notifier).fetchInvites();
          },
        ),

        // Sync settings section
        _SectionHeader(title: 'Sync Settings'),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Sync status row
              ListTile(
                leading: Icon(
                  syncState.isOnline
                      ? LucideIcons.wifi
                      : LucideIcons.wifiOff,
                  color: syncState.isOnline
                      ? AppColors.success
                      : AppColors.error,
                ),
                title: Text(
                  syncState.isOnline ? 'Online' : 'Offline',
                ),
                subtitle: syncState.lastSyncAt != null
                    ? Text(
                        'Last sync: ${_formatTime(syncState.lastSyncAt!)}',
                      )
                    : const Text('Never synced'),
                trailing: syncState.pendingCount > 0
                    ? Chip(
                        label: Text('${syncState.pendingCount} pending'),
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const Divider(height: 1),

              // Sync Now button
              ListTile(
                leading: syncState.uploadingId != null
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Icon(
                        LucideIcons.refreshCw,
                        color: AppColors.primary,
                      ),
                title: Text(
                  syncState.uploadingId != null
                      ? 'Syncing... ${syncState.syncProgress}%'
                      : 'Sync Now',
                ),
                subtitle: syncState.uploadingId != null
                    ? LinearProgressIndicator(
                        value: syncState.syncProgress / 100,
                        backgroundColor:
                            AppColors.border.withValues(alpha: 0.3),
                        color: AppColors.primary,
                      )
                    : null,
                enabled: syncState.isOnline &&
                    syncState.uploadingId == null &&
                    syncState.pendingCount > 0,
                onTap: () {
                  ref.read(syncNotifierProvider.notifier).syncAll();
                },
              ),
              const Divider(height: 1),

              // Wi-Fi only toggle
              SwitchListTile(
                secondary: Icon(
                  LucideIcons.signal,
                  color: AppColors.secondary,
                ),
                title: const Text('Upload on Wi-Fi only'),
                subtitle: const Text(
                  'Prevent uploads over cellular data',
                ),
                value: syncState.autoUploadWifiOnly,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  ref.read(syncNotifierProvider.notifier).updateSettings(
                        SyncSettings(
                          autoUploadWifiOnly: value,
                          autoRemoveAfterUpload:
                              syncState.autoRemoveAfterUpload,
                        ),
                      );
                },
              ),
              const Divider(height: 1),

              // Auto-remove after upload toggle
              SwitchListTile(
                secondary: Icon(
                  LucideIcons.trash2,
                  color: AppColors.secondary,
                ),
                title: const Text('Auto-remove after upload'),
                subtitle: const Text(
                  'Delete local files after successful upload',
                ),
                value: syncState.autoRemoveAfterUpload,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  ref.read(syncNotifierProvider.notifier).updateSettings(
                        SyncSettings(
                          autoUploadWifiOnly: syncState.autoUploadWifiOnly,
                          autoRemoveAfterUpload: value,
                        ),
                      );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Account section
        _SectionHeader(title: 'Account'),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Icon(
              LucideIcons.logOut,
              color: AppColors.error,
            ),
            title: Text(
              'Log Out',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _InvitationsSection extends StatelessWidget {
  const _InvitationsSection({
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
    // Always show the section header with refresh button
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionHeader(title: 'Invitations')),
            IconButton(
              icon: Icon(
                LucideIcons.refreshCw,
                size: 16,
                color: AppColors.secondary,
              ),
              onPressed: onRefresh,
              tooltip: 'Refresh invitations',
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
          Card(
            child: ListTile(
              leading: Icon(LucideIcons.alertCircle, color: AppColors.error),
              title: Text(
                inviteState.error!,
                style: TextStyle(color: AppColors.error),
              ),
              trailing: TextButton(
                onPressed: onRefresh,
                child: const Text('Retry'),
              ),
            ),
          )
        else if (inviteState.invites.isEmpty)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No pending invitations',
                  style: TextStyle(color: Colors.grey),
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
                  _InviteTile(
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

class _InviteTile extends StatelessWidget {
  const _InviteTile({
    required this.invite,
    required this.onAccept,
    required this.onDecline,
  });

  final Invite invite;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.info.withValues(alpha: 0.15),
            child: Icon(
              LucideIcons.folderOpen,
              size: 20,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.projectName,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Role: ${invite.role == 'project_manager' ? 'Project Manager' : 'User'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: OutlinedButton(
              onPressed: onDecline,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Decline'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: FilledButton(
              onPressed: onAccept,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Accept'),
            ),
          ),
        ],
      ),
    );
  }
}
