import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/preview_helpers.dart';
import '../../../shared/widgets/error_snack_bar.dart';
import '../../auth/data/providers/role_provider.dart';
import '../../sync/presentation/notifiers/sync_notifier.dart';
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
          showErrorSnackBar(context, 'Admin access required');
          context.pop();
        }
        return;
      }
      if (ref.read(syncNotifierProvider).isOnline) {
        ref.read(adminNotifierProvider.notifier).fetchAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final adminState = ref.watch(adminNotifierProvider);
    final isWide = MediaQuery.of(context).size.width >= 700;

    ref.listen(syncNotifierProvider.select((s) => s.isOnline), (prev, next) {
      if (next && prev == false) {
        ref.read(adminNotifierProvider.notifier).fetchAll();
      }
    });

    ref.listen<String?>(adminNotifierProvider.select((s) => s.error), (
      prev,
      next,
    ) {
      if (next != null && next != prev) {
        showErrorSnackBar(context, next);
      }
    });

    final sections = [
      (icon: LucideIcons.layoutDashboard, label: l10n.admin_overview),
      (icon: LucideIcons.folderOpen, label: l10n.admin_projects),
      (icon: LucideIcons.bookOpen, label: l10n.admin_genres),
      (icon: LucideIcons.sparkles, label: l10n.admin_cleaning),
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
                onRefresh: () async {
                  if (!ref.read(syncNotifierProvider).isOnline) return;
                  await ref.read(adminNotifierProvider.notifier).fetchAll();
                },
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + 16,
              24,
              0,
            ),
            child: Text(
              l10n.admin_title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: List.generate(sections.length, (i) {
                final section = sections[i];
                final isSelected = i == _selectedSection;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          section.icon,
                          size: 16,
                          color: isSelected ? colors.accent : colors.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(section.label),
                      ],
                    ),
                    onSelected: (_) => setState(() => _selectedSection = i),
                    selectedColor: colors.accent.withValues(alpha: 0.12),
                    labelStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected ? colors.accent : colors.secondary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected
                            ? colors.accent.withValues(alpha: 0.3)
                            : colors.border.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),

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
}
