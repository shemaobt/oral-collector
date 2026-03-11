import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../features/invite/presentation/notifiers/invite_notifier.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const double scrollBottomPadding = 120;

  static double fabBottomOffset(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding.bottom;
    return 68.0 + 6 + (safePadding > 0 ? safePadding - 16 : 2) + 16;
  }

  static const _tabs = [
    _TabItem(path: '/home', label: 'Home', icon: LucideIcons.layoutGrid),
    _TabItem(path: '/record', label: 'Record', icon: LucideIcons.mic),
    _TabItem(
      path: '/recordings',
      label: 'Recordings',
      icon: LucideIcons.listMusic,
    ),
    _TabItem(
      path: '/projects',
      label: 'Projects',
      icon: LucideIcons.folderOpen,
    ),
    _TabItem(path: '/profile', label: 'Profile', icon: LucideIcons.user),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (var i = 0; i < _tabs.length; i++) {
      if (location == _tabs[i].path ||
          location.startsWith('${_tabs[i].path}/')) {
        return i;
      }
    }
    return 0;
  }

  void _onTabTapped(BuildContext context, int index) {
    context.go(_tabs[index].path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final selectedIndex = _currentIndex(context);
    final isWide = MediaQuery.of(context).size.width >= 600;
    final pendingInvites = ref.watch(inviteNotifierProvider).pendingCount;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _onTabTapped(context, index),
              labelType: NavigationRailLabelType.all,
              destinations: _tabs
                  .map(
                    (tab) => NavigationRailDestination(
                      icon: tab.path == '/profile' && pendingInvites > 0
                          ? Badge(
                              label: Text(
                                '$pendingInvites',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: colors.accent,
                              child: Icon(tab.icon),
                            )
                          : Icon(tab.icon),
                      label: Text(tab.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: _FloatingNavBar(
        tabs: _tabs,
        selectedIndex: selectedIndex,
        onTabTapped: (index) => _onTabTapped(context, index),
        colors: colors,
        pendingInvites: pendingInvites,
        bottomPadding: MediaQuery.of(context).padding.bottom,
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
      alpha: isDark ? 0.65 : 0.70,
    );
    final itemBg = (isDark ? colors.surfaceAlt : colors.card).withValues(
      alpha: 0.85,
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
              color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
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
                    alpha: isDark ? 0.08 : 0.15,
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
