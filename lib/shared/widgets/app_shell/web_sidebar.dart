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

class WebSidebar extends ConsumerStatefulWidget {
  const WebSidebar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabTapped,
    required this.pendingInvites,
    required this.startExpanded,
  });

  final List<TabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabTapped;
  final int pendingInvites;
  final bool startExpanded;

  @override
  ConsumerState<WebSidebar> createState() => _WebSidebarState();
}

class _WebSidebarState extends ConsumerState<WebSidebar> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.startExpanded;
  }

  @override
  void didUpdateWidget(covariant WebSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startExpanded && !oldWidget.startExpanded) {
      _expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);
    final user = authState.currentUser;
    final l10n = AppLocalizations.of(context);

    return AnimatedContainer(
      duration: DurationScale.ms200,
      curve: Curves.easeInOut,
      width: _expanded ? 220 : 72,
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          right: BorderSide(
            color: colors.border.withValues(alpha: isDark ? 0.15 : 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SpacingScale.s12),
            child: Column(
              children: List.generate(widget.tabs.length, (i) {
                final tab = widget.tabs[i];
                final isSelected = i == widget.selectedIndex;
                final hasBadge =
                    tab.path == '/profile' && widget.pendingInvites > 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: SpacingScale.s4),
                  child: _SidebarNavItem(
                    icon: tab.icon,
                    label: tab.label,
                    isSelected: isSelected,
                    expanded: _expanded,
                    hasBadge: hasBadge,
                    badgeCount: widget.pendingInvites,
                    onTap: () => widget.onTabTapped(i),
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
                expanded: _expanded,
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
          const SizedBox(height: SpacingScale.s8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SpacingScale.s12),
            child: _SidebarCollapseToggle(
              expanded: _expanded,
              collapseLabel: l10n.nav_collapse,
              onTap: () => setState(() => _expanded = !_expanded),
              colors: colors,
              theme: theme,
            ),
          ),
          const SizedBox(height: SpacingScale.s12),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.expanded,
    required this.hasBadge,
    required this.badgeCount,
    required this.onTap,
    required this.colors,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final bool expanded;
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
      color: isSelected ? colors.accent : colors.secondary,
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
          borderRadius: BorderRadius.circular(RadiusScale.r8),
          child: AnimatedContainer(
            duration: DurationScale.ms200,
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? 12 : 0,
              vertical: SpacingScale.s8,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.accent.withValues(alpha: 0.1)
                  : AppColors.transparent,
              borderRadius: BorderRadius.circular(RadiusScale.r8),
            ),
            child: expanded
                ? Row(
                    children: [
                      displayIcon,
                      const SizedBox(width: SpacingScale.s12),
                      Expanded(
                        child: Text(
                          label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? colors.accent
                                : colors.secondary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Center(child: displayIcon),
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
    required this.expanded,
    required this.colors,
    required this.theme,
    required this.onLogout,
  });

  final String? avatarUrl;
  final String? displayName;
  final String? email;
  final bool expanded;
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
      padding: EdgeInsets.symmetric(
        horizontal: expanded ? 10 : 0,
        vertical: SpacingScale.s8,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceAlt.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(RadiusScale.r8),
      ),
      child: expanded
          ? Row(
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
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                avatar,
                const SizedBox(height: SpacingScale.s8),
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

class _SidebarCollapseToggle extends StatelessWidget {
  const _SidebarCollapseToggle({
    required this.expanded,
    required this.collapseLabel,
    required this.onTap,
    required this.colors,
    required this.theme,
  });

  final bool expanded;
  final String collapseLabel;
  final VoidCallback onTap;
  final AppColorSet colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusScale.r8),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 12 : 0,
            vertical: SpacingScale.s8,
          ),
          child: expanded
              ? Row(
                  children: [
                    Icon(
                      LucideIcons.panelLeftClose,
                      size: 18,
                      color: colors.secondary,
                    ),
                    const SizedBox(width: SpacingScale.s12),
                    Flexible(
                      child: Text(
                        collapseLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.secondary,
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Icon(
                    LucideIcons.panelLeftOpen,
                    size: 18,
                    color: colors.secondary,
                  ),
                ),
        ),
      ),
    );
  }
}
