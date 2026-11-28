import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/platform/file_ops.dart' as file_ops;
import '../../core/theme/app_colors.dart';
import '../../features/auth/data/providers/role_provider.dart';
import '../../features/invite/presentation/notifiers/invite_notifier.dart';
import '../../features/recording/presentation/notifiers/interrupted_sessions_notifier.dart';
import '../../features/recording/presentation/notifiers/recording_session_notifier.dart';
import '../../features/recording/presentation/widgets/leave_recording_dialog.dart';
import '../../features/recording/presentation/widgets/recording_navigation_guard.dart';
import '../../l10n/app_localizations.dart';
import 'app_shell/floating_nav_bar.dart';
import 'app_shell/tab_item.dart';
import 'app_shell/web_sidebar.dart';
import 'brush_sign.dart';
import 'quick_notice.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const double scrollBottomPadding = 120;
  static const double wideBreakpoint = 1024;

  static double scrollPaddingFor(BuildContext context) {
    return MediaQuery.of(context).size.width >= wideBreakpoint
        ? 40.0
        : scrollBottomPadding;
  }

  static double fabBottomOffset(BuildContext context) {
    if (MediaQuery.of(context).size.width >= wideBreakpoint) return 70.0;
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
      showQuickNotice(
        context,
        l10n.recording_savingPleaseWait,
        sign: Sign.info,
      );
      return;
    }

    final canGo = await confirmRecordingNavigationFromTab(context, ref);
    if (!canGo) return;
    if (!mounted) return;

    // Switching tabs is the other way out of the confirmation form, and the
    // field team used it as much as the back button — so it offers the same
    // three doors (ENG-518).
    final pendingResult = ref.read(pendingRecordingDecisionProvider);
    if (pendingResult != null) {
      final sessionId = pendingResult.sessionId;
      final interrupted = ref.read(
        interruptedSessionsNotifierProvider.notifier,
      );
      final choice = await showLeaveRecordingDialog(
        context,
        canKeepForLater: sessionId != null,
      );
      if (choice == null) return;
      if (choice == LeaveRecordingChoice.keepForLater) {
        await interrupted.keepForLater(sessionId!);
      } else {
        try {
          await file_ops.deleteFile(pendingResult.filePath);
        } catch (_) {}
      }
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
    final isWide = screenWidth >= AppShell.wideBreakpoint;
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
            ),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: QuickNoticeFloor(child: widget.child),
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
