import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/data/providers/role_provider.dart';
import '../data/providers/project_provider.dart';
import '../domain/entities/project.dart';
import 'create_project_dialog.dart';

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
      await ref.read(projectNotifierProvider.notifier).fetchProjects();
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
    // Watch role state to rebuild when roles are fetched
    ref.watch(roleNotifierProvider);
    final roleNotifier = ref.read(roleNotifierProvider.notifier);
    final theme = Theme.of(context);

    // Show error via SnackBar
    ref.listen<ProjectState>(projectNotifierProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    final canCreate = roleNotifier.canCreateProject;

    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => _showCreateProjectDialog(),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(LucideIcons.plus),
            )
          : null,
      body: _buildBody(state, roleNotifier, theme),
    );
  }

  Widget _buildBody(ProjectState state, RoleNotifier roleNotifier, ThemeData theme) {
    if (state.isLoading && state.projects.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.projects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.folderOpen,
                size: 64,
                color: AppColors.border,
              ),
              const SizedBox(height: 16),
              Text(
                "You haven't joined any projects yet",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.foreground.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.projects.length,
        itemBuilder: (context, index) {
          final project = state.projects[index];
          final canManage = roleNotifier.canManageProject(project.id);
          return _ProjectCard(
            project: project,
            showSettings: canManage,
            onEnter: () => _enterProject(project),
            onSettings: canManage
                ? () => context.push('/project/${project.id}/settings')
                : null,
          );
        },
      ),
    );
  }

  Future<void> _showCreateProjectDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const CreateProjectDialog(),
    );
    if (created == true && mounted) {
      ref.read(projectNotifierProvider.notifier).fetchProjects();
    }
  }

  Future<void> _enterProject(Project project) async {
    await ref.read(projectNotifierProvider.notifier).setActiveProject(project);
    if (mounted) {
      context.go('/home');
    }
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.onEnter,
    this.onSettings,
    this.showSettings = true,
  });

  final Project project;
  final VoidCallback onEnter;
  final VoidCallback? onSettings;
  final bool showSettings;

  String _formatDuration(double totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = ((totalSeconds % 3600) ~/ 60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project name and language badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (project.languageName != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      project.languageName!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (showSettings) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      LucideIcons.settings,
                      size: 20,
                      color: AppColors.secondary,
                    ),
                    onPressed: onSettings,
                    tooltip: 'Project Settings',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Stats row
            Row(
              children: [
                Icon(LucideIcons.users, size: 16, color: AppColors.border),
                const SizedBox(width: 4),
                Text(
                  '${project.memberCount}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                Icon(LucideIcons.mic, size: 16, color: AppColors.border),
                const SizedBox(width: 4),
                Text(
                  '${project.recordingCount}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                Icon(LucideIcons.clock, size: 16, color: AppColors.border),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(project.totalDurationSeconds),
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onEnter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Enter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
