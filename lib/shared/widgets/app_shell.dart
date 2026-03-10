import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'sync_status_indicator.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _TabItem(path: '/home', label: 'Home', icon: LucideIcons.layoutGrid),
    _TabItem(path: '/record', label: 'Record', icon: LucideIcons.mic),
    _TabItem(path: '/recordings', label: 'Recordings', icon: LucideIcons.listMusic),
    _TabItem(path: '/projects', label: 'Projects', icon: LucideIcons.folderOpen),
    _TabItem(path: '/profile', label: 'Profile', icon: LucideIcons.user),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  void _onTabTapped(BuildContext context, int index) {
    context.go(_tabs[index].path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _currentIndex(context);
    final isWide = MediaQuery.of(context).size.width >= 600;

    if (isWide) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_tabs[selectedIndex].label),
          actions: const [SyncStatusIndicator()],
        ),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _onTabTapped(context, index),
              labelType: NavigationRailLabelType.all,
              destinations: _tabs
                  .map((tab) => NavigationRailDestination(
                        icon: Icon(tab.icon),
                        label: Text(tab.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_tabs[selectedIndex].label),
        actions: const [SyncStatusIndicator()],
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => _onTabTapped(context, index),
        type: BottomNavigationBarType.fixed,
        items: _tabs
            .map((tab) => BottomNavigationBarItem(
                  icon: Icon(tab.icon),
                  label: tab.label,
                ))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.path,
    required this.label,
    required this.icon,
  });

  final String path;
  final String label;
  final IconData icon;
}
