import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/preview_helpers.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/sync_status_indicator.dart';
import '../../auth/data/providers/role_provider.dart';
import 'notifiers/project_notifier.dart';
import 'notifiers/project_state.dart';
import 'create_project_dialog.dart';
import 'widgets/create_project_fab.dart';
import 'widgets/project_card.dart';

@Preview(name: 'Projects Screen', wrapper: previewWrapper)
Widget projectsScreenPreview() => const ProjectsScreen();

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      await ref.read(projectNotifierProvider.notifier).fetchProjects();
      if (!mounted) return;
      final projects = ref.read(projectNotifierProvider).projects;
      if (projects.isNotEmpty) {
        await ref
            .read(roleNotifierProvider.notifier)
            .fetchRolesForProjects(projects.map((p) => p.id).toList());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectNotifierProvider);
    ref.watch(roleNotifierProvider);
    final roleNotifier = ref.read(roleNotifierProvider.notifier);
    final colors = AppColors.of(context);

    ref.listen<ProjectState>(projectNotifierProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: colors.error),
        );
      }
    });

    final canCreate = roleNotifier.canCreateProject;
    final fabOffset = AppShell.fabBottomOffset(context);

    return Scaffold(
      appBar: ScreenHeader(
        title: 'Projects',
        subtitle: 'Manage your collections',
        icon: LucideIcons.folderOpen,
        actions: const [SyncStatusIndicator()],
      ),
      floatingActionButton: canCreate
          ? Padding(
              padding: EdgeInsets.only(bottom: fabOffset - 70),
              child: CreateProjectFab(
                colors: colors,
                onTap: () => _showCreateProjectDialog(),
              ),
            )
          : null,
      body: _buildBody(state, roleNotifier, colors),
    );
  }

  Widget _buildBody(
    ProjectState state,
    RoleNotifier roleNotifier,
    AppColorSet colors,
  ) {
    if (state.isLoading && state.projects.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.projects.isEmpty) {
      return const EmptyState(
        icon: LucideIcons.folderPlus,
        title: 'No projects yet',
        description:
            'Create your first project to start collecting oral stories.',
      );
    }

    final activeId = state.activeProject?.id;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(projectNotifierProvider.notifier).fetchProjects();
        final projects = ref.read(projectNotifierProvider).projects;
        if (projects.isNotEmpty) {
          await ref
              .read(roleNotifierProvider.notifier)
              .fetchRolesForProjects(projects.map((p) => p.id).toList());
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 600;

          if (isTablet) {
            return GridView.builder(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                AppShell.scrollBottomPadding,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.6,
              ),
              itemCount: state.projects.length,
              itemBuilder: (context, index) {
                final project = state.projects[index];
                return ProjectCard(
                  project: project,
                  isActive: project.id == activeId,
                  colorIndex: index,
                  onTap: () => context.push('/project/${project.id}/settings'),
                );
              },
            );
          }

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              AppShell.scrollBottomPadding,
            ),
            itemCount: state.projects.length,
            itemBuilder: (context, index) {
              final project = state.projects[index];
              return ProjectCard(
                project: project,
                isActive: project.id == activeId,
                colorIndex: index,
                onTap: () => context.push('/project/${project.id}/settings'),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showCreateProjectDialog() async {
    final created = await showCreateProjectSheet(context);
    if (created == true && mounted) {
      ref.read(projectNotifierProvider.notifier).fetchProjects();
    }
  }
}
