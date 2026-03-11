import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/preview_helpers.dart';
import '../../auth/data/providers/role_provider.dart';
import 'notifiers/admin_notifier.dart';
import 'widgets/cleaning_section.dart';
import 'widgets/genres_section.dart';
import 'widgets/overview_section.dart';
import 'widgets/projects_section.dart';

@Preview(name: 'Admin Dashboard', wrapper: previewWrapper)
Widget adminDashboardPreview() => const AdminDashboardScreen();

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedSection = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final isAdmin = ref.read(roleNotifierProvider.notifier).isPlatformAdmin;
      if (!isAdmin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin access required'),
              backgroundColor: Colors.orange,
            ),
          );
          context.pop();
        }
        return;
      }
      ref.read(adminNotifierProvider.notifier).fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final adminState = ref.watch(adminNotifierProvider);
    final isWide = MediaQuery.of(context).size.width >= 800;

    ref.listen<String?>(adminNotifierProvider.select((s) => s.error), (
      prev,
      next,
    ) {
      if (next != null && next != prev) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next), backgroundColor: colors.error),
        );
      }
    });

    final sections = [
      const AdminNavItem(icon: LucideIcons.layoutDashboard, label: 'Overview'),
      const AdminNavItem(icon: LucideIcons.folderOpen, label: 'Projects'),
      const AdminNavItem(icon: LucideIcons.bookOpen, label: 'Genres'),
      const AdminNavItem(icon: LucideIcons.sparkles, label: 'Cleaning'),
    ];

    Widget body;
    if (adminState.isLoading && adminState.stats == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      switch (_selectedSection) {
        case 0:
          body = OverviewSection(stats: adminState.stats);
        case 1:
          body = ProjectsSection(projects: adminState.projects);
        case 2:
          body = GenresSection(
            genres: adminState.genres,
            onRefresh: () =>
                ref.read(adminNotifierProvider.notifier).fetchAll(),
          );
        case 3:
          body = CleaningSection(recordings: adminState.cleaningQueue);
        default:
          body = const SizedBox.shrink();
      }
    }

    if (isWide) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => context.pop(),
          ),
          title: const Text('Admin Dashboard'),
        ),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedSection,
              onDestinationSelected: (index) {
                setState(() => _selectedSection = index);
              },
              labelType: NavigationRailLabelType.all,
              destinations: sections
                  .map(
                    (s) => NavigationRailDestination(
                      icon: Icon(s.icon),
                      label: Text(s.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(adminNotifierProvider.notifier).fetchAll(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: body,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Admin Dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminNotifierProvider.notifier).fetchAll(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  segments: sections
                      .asMap()
                      .entries
                      .map(
                        (e) => ButtonSegment<int>(
                          value: e.key,
                          label: Text(e.value.label),
                          icon: Icon(e.value.icon, size: 18),
                        ),
                      )
                      .toList(),
                  selected: {_selectedSection},
                  onSelectionChanged: (selection) {
                    setState(() => _selectedSection = selection.first);
                  },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: colors.accent.withValues(
                      alpha: 0.1,
                    ),
                    selectedForegroundColor: colors.accent,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              body,
            ],
          ),
        ),
      ),
    );
  }
}

class AdminNavItem {
  final IconData icon;
  final String label;
  const AdminNavItem({required this.icon, required this.label});
}
