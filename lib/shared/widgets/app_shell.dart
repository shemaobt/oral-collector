import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/data/providers/role_provider.dart';
import '../../features/invite/presentation/notifiers/invite_notifier.dart';
import '../../features/recording/data/services/recovery_coordinator.dart';
import '../../features/recording/presentation/widgets/crash_recovery_dialog.dart';
import '../../l10n/app_localizations.dart';
import 'user_avatar.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const double scrollBottomPadding = 120;

  static double scrollPaddingFor(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600
        ? 40.0
        : scrollBottomPadding;
  }

  static double fabBottomOffset(BuildContext context) {
    if (MediaQuery.of(context).size.width >= 600) return 70.0;
    final safePadding = MediaQuery.of(context).padding.bottom;
    return 68.0 + 6 + (safePadding > 0 ? safePadding - 16 : 2) + 16;
  }

  static List<_TabItem> _allTabs(AppLocalizations l10n) => [
    _TabItem(path: '/home', label: l10n.nav_home, icon: LucideIcons.layoutGrid),
    _TabItem(path: '/record', label: l10n.nav_record, icon: LucideIcons.mic),
    _TabItem(
      path: '/recordings',
      label: l10n.nav_recordings,
      icon: LucideIcons.listMusic,
    ),
    _TabItem(
      path: '/projects',
      label: l10n.nav_projects,
      icon: LucideIcons.folderOpen,
    ),
    _TabItem(path: '/profile', label: l10n.nav_profile, icon: LucideIcons.user),
  ];

  static List<_TabItem> _mobileTabs(AppLocalizations l10n) => _allTabs(l10n);
  static List<_TabItem> _webBaseTabs(AppLocalizations l10n) =>
      _allTabs(l10n).where((t) => t.path != '/record').toList();

  int _currentIndexFrom(BuildContext context, List<_TabItem> tabs) {
    final location = GoRouterState.of(context).uri.path;
    for (var i = 0; i < tabs.length; i++) {
      if (location == tabs[i].path || location.startsWith('${tabs[i].path}/')) {
        return i;
      }
    }
    return 0;
  }

  List<_TabItem> _buildWebTabs(WidgetRef ref, AppLocalizations l10n) {
    final tabs = List<_TabItem>.from(_webBaseTabs(l10n));
    if (ref.read(roleNotifierProvider.notifier).isPlatformAdmin) {
      tabs.add(
        _TabItem(
          path: '/admin',
          label: l10n.nav_admin,
          icon: LucideIcons.layoutDashboard,
        ),
      );
    }
    return tabs;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;
    final pendingInvites = ref.watch(inviteNotifierProvider).pendingCount;

    ref.watch(roleNotifierProvider);

    ref.listen<RecoveryPrompt?>(pendingRecoveryProvider, (_, next) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        showCrashRecoveryDialog(context, ref, next);
      });
    });

    final mobileTabs = _mobileTabs(l10n);
    final tabs = isWide ? _buildWebTabs(ref, l10n) : mobileTabs;
    final selectedIndex = _currentIndexFrom(context, tabs);

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _WebSidebar(
              tabs: tabs,
              selectedIndex: selectedIndex,
              onTabTapped: (index) => context.go(tabs[index].path),
              pendingInvites: pendingInvites,
              startExpanded: isDesktop,
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: _FloatingNavBar(
        tabs: mobileTabs,
        selectedIndex: _currentIndexFrom(context, mobileTabs),
        onTabTapped: (index) => context.go(mobileTabs[index].path),
        colors: colors,
        pendingInvites: pendingInvites,
        bottomPadding: MediaQuery.of(context).padding.bottom,
      ),
    );
  }
}

class _WebSidebar extends ConsumerStatefulWidget {
  const _WebSidebar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabTapped,
    required this.pendingInvites,
    required this.startExpanded,
  });

  final List<_TabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabTapped;
  final int pendingInvites;
  final bool startExpanded;

  @override
  ConsumerState<_WebSidebar> createState() => _WebSidebarState();
}

class _WebSidebarState extends ConsumerState<_WebSidebar> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.startExpanded;
  }

  @override
  void didUpdateWidget(covariant _WebSidebar oldWidget) {
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
      duration: const Duration(milliseconds: 200),
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: List.generate(widget.tabs.length, (i) {
                final tab = widget.tabs[i];
                final isSelected = i == widget.selectedIndex;
                final hasBadge =
                    tab.path == '/profile' && widget.pendingInvites > 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _SidebarUserRow(
                avatarUrl: user.avatarUrl,
                displayName: user.displayName,
                email: user.email,
                expanded: _expanded,
                colors: colors,
                theme: theme,
                onLogout: () async {
                  await ref.read(authNotifierProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _SidebarCollapseToggle(
              expanded: _expanded,
              collapseLabel: l10n.nav_collapse,
              onTap: () => setState(() => _expanded = !_expanded),
              colors: colors,
              theme: theme,
            ),
          ),
          const SizedBox(height: 12),
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
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
            backgroundColor: colors.accent,
            child: iconWidget,
          )
        : iconWidget;

    return Semantics(
      label: '$label tab',
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? 12 : 0,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.accent.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: expanded
                ? Row(
                    children: [
                      displayIcon,
                      const SizedBox(width: 12),
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
      padding: EdgeInsets.symmetric(horizontal: expanded ? 10 : 0, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceAlt.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: expanded
          ? Row(
              children: [
                avatar,
                const SizedBox(width: 10),
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
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onLogout,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
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
                const SizedBox(height: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onLogout,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 12 : 0,
            vertical: 10,
          ),
          child: expanded
              ? Row(
                  children: [
                    Icon(
                      LucideIcons.panelLeftClose,
                      size: 18,
                      color: colors.secondary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      collapseLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.secondary,
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

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabTapped,
    required this.colors,
    required this.pendingInvites,
    required this.bottomPadding,
  });

  final List<_TabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabTapped;
  final AppColorSet colors;
  final int pendingInvites;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navBg = (isDark ? colors.card : colors.surfaceAlt).withValues(
      alpha: isDark ? 0.65 : 0.80,
    );
    final itemBg = (isDark ? colors.surfaceAlt : colors.card).withValues(
      alpha: 0.90,
    );
    final iconColor = colors.foreground.withValues(alpha: 0.55);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        6,
        16,
        bottomPadding > 16 ? bottomPadding - 16 : 2,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              height: 68,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: navBg,
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: (isDark ? Colors.white : colors.border).withValues(
                    alpha: isDark ? 0.08 : 0.25,
                  ),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  const spacing = 4.0;
                  final count = tabs.length;
                  final totalSpacing = spacing * (count - 1);
                  final usableWidth = totalWidth - totalSpacing;

                  final unselectedWidth = usableWidth / (count + 1);
                  final selectedWidth = unselectedWidth * 2;

                  return Row(
                    children: List.generate(count, (i) {
                      final isSelected = i == selectedIndex;
                      final tab = tabs[i];
                      final hasBadge =
                          tab.path == '/profile' && pendingInvites > 0;

                      return Padding(
                        padding: EdgeInsets.only(
                          right: i < count - 1 ? spacing : 0,
                        ),
                        child: Semantics(
                          label: '${tab.label} tab',
                          selected: isSelected,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => onTabTapped(i),
                              borderRadius: BorderRadius.circular(26),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                width: isSelected
                                    ? selectedWidth
                                    : unselectedWidth,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: isSelected ? colors.accent : itemBg,
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                child: _NavItemContent(
                                  icon: tab.icon,
                                  label: tab.label,
                                  isSelected: isSelected,
                                  iconColor: iconColor,
                                  hasBadge: hasBadge,
                                  badgeCount: pendingInvites,
                                  accentColor: colors.accent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemContent extends StatelessWidget {
  const _NavItemContent({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.iconColor,
    required this.hasBadge,
    required this.badgeCount,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final Color iconColor;
  final bool hasBadge;
  final int badgeCount;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(
      icon,
      size: 20,
      color: isSelected ? Colors.white : iconColor,
    );

    final displayIcon = hasBadge
        ? Badge(
            label: Text(
              '$badgeCount',
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
            backgroundColor: isSelected ? Colors.white : accentColor,
            child: iconWidget,
          )
        : iconWidget;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: isSelected
          ? Row(
              key: const ValueKey(true),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                displayIcon,
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          : Center(key: const ValueKey(false), child: displayIcon),
    );
  }
}

class _TabItem {
  const _TabItem({required this.path, required this.label, required this.icon});

  final String path;
  final String label;
  final IconData icon;
}
