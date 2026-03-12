import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/preview_helpers.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/icon_box.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../auth/data/providers/role_provider.dart';
import '../../invite/presentation/notifiers/invite_notifier.dart';
import '../../project/presentation/notifiers/project_notifier.dart';
import '../../sync/presentation/notifiers/sync_notifier.dart';
import '../../sync/presentation/notifiers/sync_state.dart';
import 'notifiers/profile_notifier.dart';
import 'widgets/invitations_section.dart';
import 'widgets/profile_header.dart';
import 'widgets/quick_stats_row.dart';
import 'widgets/sync_settings_card.dart';

@Preview(name: 'Profile Screen', wrapper: previewWrapper)
Widget profileScreenPreview() => const ProfileScreen();

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(inviteNotifierProvider.notifier).fetchInvites();
      ref.read(profileNotifierProvider.notifier).loadStorageUsed();
    });
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final success = await ref
          .read(profileNotifierProvider.notifier)
          .pickAndUploadAvatar();
      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update photo: $e'),
            backgroundColor: AppColors.of(context).error,
          ),
        );
      }
    }
  }

  Future<void> _showEditNameDialog() async {
    final user = ref.read(authNotifierProvider).currentUser;
    final controller = TextEditingController(text: user?.displayName ?? '');
    final colors = AppColors.of(context);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit display name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Your name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(ctx).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: colors.accent),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && mounted) {
      await ref
          .read(profileNotifierProvider.notifier)
          .updateDisplayName(newName);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Name updated')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final syncState = ref.watch(syncNotifierProvider);
    final inviteState = ref.watch(inviteNotifierProvider);
    final profileState = ref.watch(profileNotifierProvider);

    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = authState.currentUser;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.top + 8),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                children: [
                  ProfileHeader(
                    user: user,
                    isUploadingAvatar: profileState.isUploadingAvatar,
                    colors: colors,
                    theme: theme,
                    onPickAvatar: _pickAndUploadAvatar,
                    onEditName: _showEditNameDialog,
                  ),

                  const SizedBox(height: 24),

                  QuickStatsRow(
                    storageLabel: formatFileSize(
                      ref.read(profileNotifierProvider).storageUsedBytes,
                    ),
                    isOnline: syncState.isOnline,
                    pendingCount: syncState.pendingCount,
                    colors: colors,
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              28,
              16,
              AppShell.scrollBottomPadding,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                InvitationsSection(
                  inviteState: inviteState,
                  onAccept: (invite) async {
                    final accepted = await ref
                        .read(inviteNotifierProvider.notifier)
                        .acceptInvite(invite.id);
                    if (accepted && context.mounted) {
                      ref
                          .read(projectNotifierProvider.notifier)
                          .fetchProjects();
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

                const SectionHeader(title: 'Sync & Storage'),
                const SizedBox(height: 8),
                SyncSettingsCard(
                  syncState: syncState,
                  theme: theme,
                  colors: colors,
                  onSyncNow: () {
                    ref.read(syncNotifierProvider.notifier).syncAll();
                  },
                  onWifiOnlyChanged: (value) {
                    ref
                        .read(syncNotifierProvider.notifier)
                        .updateSettings(
                          SyncSettings(
                            autoUploadWifiOnly: value,
                            autoRemoveAfterUpload:
                                syncState.autoRemoveAfterUpload,
                          ),
                        );
                  },
                  onAutoRemoveChanged: (value) {
                    ref
                        .read(syncNotifierProvider.notifier)
                        .updateSettings(
                          SyncSettings(
                            autoUploadWifiOnly: syncState.autoUploadWifiOnly,
                            autoRemoveAfterUpload: value,
                          ),
                        );
                  },
                  onClearCache: () => _showClearCacheConfirmation(context),
                ),
                const SizedBox(height: 24),

                const SectionHeader(title: 'About'),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: IconBox(
                          icon: LucideIcons.info,
                          color: colors.info,
                        ),
                        title: const Text('App version'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.foreground.withValues(
                              alpha: isDark ? 0.1 : 0.06,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '1.0.0',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: IconBox(
                          icon: LucideIcons.heart,
                          color: colors.accent,
                        ),
                        title: const Text('Oral Collector by Shema'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (kIsWeb &&
                    ref
                        .read(roleNotifierProvider.notifier)
                        .isPlatformAdmin) ...[
                  const SectionHeader(title: 'Administration'),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: IconBox(
                        icon: LucideIcons.layoutDashboard,
                        color: colors.primary,
                      ),
                      title: const Text('Admin Dashboard'),
                      subtitle: const Text(
                        'System stats, projects & genre management',
                      ),
                      trailing: Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: colors.secondary,
                      ),
                      onTap: () => context.push('/admin'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                const SectionHeader(title: 'Account'),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: IconBox(
                      icon: LucideIcons.logOut,
                      color: colors.error,
                      alpha: 0.1,
                    ),
                    title: Text(
                      'Log Out',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () async {
                      await ref.read(authNotifierProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearCacheConfirmation(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear local cache?'),
        content: const Text(
          'This will delete all locally stored recordings. '
          'Uploaded recordings on the server will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.of(context).error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(profileNotifierProvider.notifier).clearCacheAndRefresh();
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Local cache cleared')),
        );
      }
    }
  }
}
