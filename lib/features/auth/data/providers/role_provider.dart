import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../project/data/providers/project_provider.dart';
import '../../../project/data/repositories/project_repository.dart';
import 'auth_provider.dart';

// --- State ---

class RoleState {
  /// Map of projectId → user's role in that project ('user' | 'project_manager').
  final Map<String, String> projectRoles;

  const RoleState({this.projectRoles = const {}});

  /// Check if user has project_manager role for a specific project.
  bool isProjectManager(String projectId) {
    return projectRoles[projectId] == 'project_manager';
  }

  /// Check if user is project_manager in any cached project.
  bool get hasAnyManagerRole {
    return projectRoles.values.any((r) => r == 'project_manager');
  }

  RoleState copyWith({Map<String, String>? projectRoles}) {
    return RoleState(projectRoles: projectRoles ?? this.projectRoles);
  }
}

// --- Provider ---

final roleNotifierProvider =
    NotifierProvider<RoleNotifier, RoleState>(RoleNotifier.new);

// --- Notifier ---

class RoleNotifier extends Notifier<RoleState> {
  ProjectRepository get _repo => ref.read(projectRepositoryProvider);

  @override
  RoleState build() => const RoleState();

  /// Whether the current user is a platform admin.
  bool get isPlatformAdmin {
    final user = ref.read(authNotifierProvider).currentUser;
    return user?.role == 'admin';
  }

  /// Whether user can manage a specific project (platform admin OR project manager).
  bool canManageProject(String projectId) {
    if (isPlatformAdmin) return true;
    return state.isProjectManager(projectId);
  }

  /// Whether user can create projects (platform admin OR PM in any project).
  bool get canCreateProject {
    if (isPlatformAdmin) return true;
    return state.hasAnyManagerRole;
  }

  /// Fetch the current user's role for a single project via the members API.
  Future<void> fetchRoleForProject(String projectId) async {
    final user = ref.read(authNotifierProvider).currentUser;
    if (user == null) return;

    try {
      final members = await _repo.listMembers(projectId);
      final me = members.where((m) => m.userId == user.id).firstOrNull;
      if (me != null) {
        state = state.copyWith(
          projectRoles: {...state.projectRoles, projectId: me.role},
        );
      }
    } on Exception {
      // Silently fail — role defaults to non-manager
    }
  }

  /// Fetch roles for multiple projects in parallel.
  Future<void> fetchRolesForProjects(List<String> projectIds) async {
    await Future.wait(projectIds.map(fetchRoleForProject));
  }
}
