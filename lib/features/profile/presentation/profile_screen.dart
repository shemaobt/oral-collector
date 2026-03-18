import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/l10n/supported_locales.dart';
import '../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/preview_helpers.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/error_snack_bar.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/icon_box.dart';
import '../../../shared/widgets/locale_picker_sheet.dart';
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
      ref.read(profileNotifierProvider.notifier).loadStorageUsed();
      if (ref.read(syncNotifierProvider).isOnline) {
        ref.read(inviteNotifierProvider.notifier).fetchInvites();
      }
    });
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final success = await ref
          .read(profileNotifierProvider.notifier)
          .pickAndUploadAvatar();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).profile_photoUpdated),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Failed to update photo: $e');
      }
    }
  }

  Future<void> _showEditNameDialog() async {
    final user = ref.read(authNotifierProvider).currentUser;
    final controller = TextEditingController(text: user?.displayName ?? '');
    final colors = AppColors.of(context);

    final l10n = AppLocalizations.of(context);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profile_editName),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: l10n.profile_nameHint,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(ctx).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: colors.accent),
            child: Text(l10n.common_save),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && mounted) {
      await ref
          .read(profileNotifierProvider.notifier)
          .updateDisplayName(newName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).profile_nameUpdated),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final syncState = ref.watch(syncNotifierProvider);
    final inviteState = ref.watch(inviteNotifierProvider);
    final profileState = ref.watch(profileNotifierProvider);

    ref.listen(syncNotifierProvider.select((s) => s.isOnline), (prev, next) {
      if (next && prev == false) {
        ref.read(inviteNotifierProvider.notifier).fetchInvites();
      }
    });

    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = authState.currentUser;

    final invitationsWidget = InvitationsSection(
      inviteState: inviteState,
      onAccept: (invite) async {
        final accepted = await ref
            .read(inviteNotifierProvider.notifier)
            .acceptInvite(invite.id);
        if (accepted && context.mounted) {
          ref.read(projectNotifierProvider.notifier).fetchProjects();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.profile_joinedSuccess(invite.projectName)),
            ),
          );
        }
      },
      onDecline: (invite) async {
        final declined = await ref
            .read(inviteNotifierProvider.notifier)
            .declineInvite(invite.id);
        if (declined && context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.profile_inviteDeclined)));
        }
      },
      onRefresh: () {
        ref.read(inviteNotifierProvider.notifier).fetchInvites();
      },
    );

    final currentLocale = ref.watch(localeProvider);
    final currentCode = currentLocale?.languageCode ?? 'en';
    final currentLocaleName = localeNativeNames[currentCode] ?? currentCode;

    final languageSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.profile_language),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: IconBox(icon: LucideIcons.globe, color: colors.primary),
            title: Text(currentLocaleName),
            trailing: Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: colors.secondary,
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                constraints: const BoxConstraints(maxWidth: 600),
                builder: (_) => const LocalePickerSheet(),
              );
            },
          ),
        ),
      ],
    );

    final syncSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.profile_syncStorage),
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
                    autoRemoveAfterUpload: syncState.autoRemoveAfterUpload,
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
      ],
    );

    final aboutSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.profile_about),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ListTile(
                leading: IconBox(icon: LucideIcons.info, color: colors.info),
                title: Text(l10n.profile_appVersion),
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
                leading: IconBox(icon: LucideIcons.heart, color: colors.accent),
                title: Text(l10n.profile_byShema),
              ),
            ],
          ),
        ),
      ],
    );

    final adminSection =
        (kIsWeb && ref.read(roleNotifierProvider.notifier).isPlatformAdmin)
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: l10n.profile_administration),
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
                  title: Text(l10n.profile_adminDashboard),
                  subtitle: Text(l10n.profile_adminSubtitle),
                  trailing: Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: colors.secondary,
                  ),
                  onTap: () => context.push('/admin'),
                ),
              ),
            ],
          )
        : null;

    final accountSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.profile_account),
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
              l10n.profile_logOut,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ),
      ],
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 8,
              20,
              AppShell.scrollPaddingFor(context),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 1000 : 800),
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
                    const SizedBox(height: 28),
                    invitationsWidget,
                    const SizedBox(height: 24),
                    languageSection,
                    const SizedBox(height: 24),
                    if (isWide) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                syncSection,
                                const SizedBox(height: 24),
                                if (adminSection != null) ...[
                                  adminSection,
                                  const SizedBox(height: 24),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              children: [
                                aboutSection,
                                const SizedBox(height: 24),
                                accountSection,
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      syncSection,
                      const SizedBox(height: 24),
                      aboutSection,
                      const SizedBox(height: 24),
                      if (adminSection != null) ...[
                        adminSection,
                        const SizedBox(height: 24),
                      ],
                      accountSection,
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showClearCacheConfirmation(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profile_clearCacheTitle),
        content: Text(l10n.profile_clearCacheMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.of(context).error,
            ),
            child: Text(l10n.common_clear),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(profileNotifierProvider.notifier).clearCacheAndRefresh();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.profile_cacheCleared)),
        );
      }
    }
  }
}
