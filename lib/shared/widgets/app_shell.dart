import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/platform/file_ops.dart' as file_ops;
import '../../core/theme/app_colors.dart';
import '../../features/auth/data/providers/role_provider.dart';
import '../../features/invite/presentation/notifiers/invite_notifier.dart';
import '../../features/recording/presentation/notifiers/recording_session_notifier.dart';
import '../../features/recording/presentation/widgets/recording_navigation_guard.dart';
import '../../l10n/app_localizations.dart';
import 'app_shell/floating_nav_bar.dart';
import 'app_shell/tab_item.dart';
import 'app_shell/web_sidebar.dart';

class AppShell extends ConsumerStatefulWidget {
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

  static List<TabItem> _allTabs(AppLocalizations l10n) => [
    TabItem(path: '/home', label: l10n.nav_home, icon: LucideIcons.layoutGrid),
    TabItem(path: '/record', label: l10n.nav_record, icon: LucideIcons.mic),
    TabItem(
      path: '/recordings',
      label: l10n.nav_recordings,
      icon: LucideIcons.listMusic,
    ),
    TabItem(
      path: '/projects',
      label: l10n.nav_projects,
      icon: LucideIcons.folderOpen,
    ),
    TabItem(path: '/profile', label: l10n.nav_profile, icon: LucideIcons.user),
  ];

  static List<TabItem> _mobileTabs(AppLocalizations l10n) => _allTabs(l10n);
  static List<TabItem> _webBaseTabs(AppLocalizations l10n) => _allTabs(l10n);

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

int _currentIndexFrom(BuildContext context, List<TabItem> tabs) {
  final location = GoRouterState.of(context).uri.path;
  for (var i = 0; i < tabs.length; i++) {
    if (location == tabs[i].path || location.startsWith('${tabs[i].path}/')) {
      return i;
    }
  }
  return 0;
}

class _AppShellState extends ConsumerState<AppShell> {
  Future<void> _navigateToTab(String targetPath) async {
    final state = ref.read(recordingSessionNotifierProvider);
    final l10n = AppLocalizations.of(context);
    if (state.isFinalizing || state.hasFinalizationError) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.recording_savingPleaseWait),
            duration: const Duration(seconds: 2),
          ),
        );
      return;
    }

    final canGo = await confirmRecordingNavigationFromTab(context, ref);
    if (!canGo) return;
    if (!mounted) return;

    final pendingResult = ref.read(pendingRecordingDecisionProvider);
    if (pendingResult != null) {
      final colors = AppColors.of(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.recording_discardTitle),
          content: Text(l10n.recording_discardMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.common_cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: colors.error),
              child: Text(l10n.recording_discard),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      try {
        await file_ops.deleteFile(pendingResult.filePath);
      } catch (_) {}
      if (!mounted) return;
      ref.read(pendingRecordingDecisionProvider.notifier).state = null;
    }

    if (!mounted) return;
    context.go(targetPath);
  }

  List<TabItem> _buildWebTabs(AppLocalizations l10n) {
    final tabs = List<TabItem>.from(AppShell._webBaseTabs(l10n));
    if (ref.read(isPlatformAdminProvider)) {
      tabs.add(
        TabItem(
          path: '/admin',
          label: l10n.nav_admin,
          icon: LucideIcons.layoutDashboard,
        ),
      );
    }
    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;
    final pendingInvites = ref.watch(inviteNotifierProvider).pendingCount;

    ref.watch(roleNotifierProvider);

    final mobileTabs = AppShell._mobileTabs(l10n);
    final tabs = isWide ? _buildWebTabs(l10n) : mobileTabs;
    final selectedIndex = _currentIndexFrom(context, tabs);

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            WebSidebar(
              tabs: tabs,
              selectedIndex: selectedIndex,
              onTabTapped: (index) => _navigateToTab(tabs[index].path),
              pendingInvites: pendingInvites,
              startExpanded: isDesktop,
            ),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: FloatingNavBar(
        tabs: mobileTabs,
        selectedIndex: _currentIndexFrom(context, mobileTabs),
        onTabTapped: (index) => _navigateToTab(mobileTabs[index].path),
        colors: colors,
        pendingInvites: pendingInvites,
        bottomPadding: MediaQuery.of(context).padding.bottom,
      ),
    );
  }
}
