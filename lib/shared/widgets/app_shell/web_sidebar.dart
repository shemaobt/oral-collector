import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/auth/auth_notifier.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../features/recording/presentation/widgets/recording_navigation_guard.dart';
import '../../../l10n/app_localizations.dart';
import '../user_avatar.dart';
import 'tab_item.dart';

class WebSidebar extends ConsumerWidget {
  const WebSidebar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabTapped,
    required this.pendingInvites,
  });

  final List<TabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabTapped;
  final int pendingInvites;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(authNotifierProvider).currentUser;

    return Container(
      width: 232,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 16),

          const _SidebarBrand(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SpacingScale.s12),
            child: Column(
              children: List.generate(tabs.length, (i) {
                final tab = tabs[i];
                final isSelected = i == selectedIndex;
                final hasBadge = tab.path == '/profile' && pendingInvites > 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: SpacingScale.s4),
                  child: _SidebarNavItem(
                    icon: tab.icon,
                    label: tab.label,
                    isSelected: isSelected,
                    hasBadge: hasBadge,
                    badgeCount: pendingInvites,
                    onTap: () => onTabTapped(i),
                    colors: colors,
                    theme: theme,
                  ),
                );
              }),
            ),
          ),

          const Spacer(),

          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SpacingScale.s12),
              child: _SidebarUserRow(
                avatarUrl: user.avatarUrl,
                displayName: user.displayName,
                email: user.email,
                colors: colors,
                theme: theme,
                onLogout: () async {
                  final canGo = await confirmRecordingNavigationFromTab(
                    context,
                    ref,
                  );
                  if (!canGo) return;
                  if (!context.mounted) return;
                  await ref.read(authNotifierProvider.notifier).logout();
                  if (!context.mounted) return;
                  context.go('/login');
                },
              ),
            ),
          const SizedBox(height: SpacingScale.s12),
        ],
      ),
    );
  }
}

const double _pillHeight = 46;

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.hasBadge,
    required this.badgeCount,
    required this.onTap,
    required this.colors,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final bool hasBadge;
  final int badgeCount;
  final VoidCallback onTap;
  final AppColorSet colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(
      icon,
      size: 20,
      color: isSelected ? colors.onPrimary : colors.secondary,
    );

    final displayIcon = hasBadge
        ? Badge(
            label: Text(
              '$badgeCount',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            backgroundColor: colors.accent,
            child: iconWidget,
          )
        : iconWidget;

    return Semantics(
      label: AppLocalizations.of(context).a11y_tabLabel(label),
      selected: isSelected,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_pillHeight),
          child: AnimatedContainer(
            duration: DurationScale.ms200,
            constraints: const BoxConstraints(minHeight: _pillHeight),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected ? colors.primary : AppColors.transparent,
              borderRadius: BorderRadius.circular(_pillHeight),
            ),
            child: Row(
              children: [
                displayIcon,
                const SizedBox(width: SpacingScale.s12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected ? colors.onPrimary : colors.secondary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarUserRow extends StatelessWidget {
  const _SidebarUserRow({
    required this.avatarUrl,
    required this.displayName,
    required this.email,
    required this.colors,
    required this.theme,
    required this.onLogout,
  });

  final String? avatarUrl;
  final String? displayName;
  final String? email;
  final AppColorSet colors;
  final ThemeData theme;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final avatar = UserAvatar(
      radius: 16,
      avatarUrl: avatarUrl,
      displayName: displayName,
      email: email,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: SpacingScale.s8,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceAlt.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(RadiusScale.r8),
      ),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: SpacingScale.s8),
          Expanded(
            child: Text(
              displayName ?? email ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Material(
            color: AppColors.transparent,
            child: InkWell(
              onTap: onLogout,
              borderRadius: BorderRadius.circular(RadiusScale.r8),
              child: Padding(
                padding: const EdgeInsets.all(SpacingScale.s4),
                child: Icon(
                  LucideIcons.logOut,
                  size: 16,
                  color: colors.secondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingScale.s12 + 10,
        0,
        SpacingScale.s12,
        6,
      ),
      child: SizedBox(
        height: _pillHeight,
        child: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              width: 28,
              height: 22,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                AppLocalizations.of(context).appTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
