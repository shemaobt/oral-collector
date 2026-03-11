import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_notifier.dart';

class RoleState {
  final Map<String, String> projectRoles;

  const RoleState({this.projectRoles = const {}});

  bool isProjectManager(String projectId) {
    return projectRoles[projectId] == 'project_manager';
  }

  bool get hasAnyManagerRole {
    return projectRoles.values.any((r) => r == 'project_manager');
  }

  RoleState copyWith({Map<String, String>? projectRoles}) {
    return RoleState(projectRoles: projectRoles ?? this.projectRoles);
  }
}

final roleNotifierProvider = NotifierProvider<RoleNotifier, RoleState>(
  RoleNotifier.new,
);

class RoleNotifier extends Notifier<RoleState> {
  @override
  RoleState build() => const RoleState();

  bool get isPlatformAdmin {
    final user = ref.read(authNotifierProvider).currentUser;
    return user?.role == 'admin';
  }

  bool canManageProject(String projectId) {
    if (isPlatformAdmin) return true;
    return state.isProjectManager(projectId);
  }

  bool get canCreateProject {
    if (isPlatformAdmin) return true;
    return state.hasAnyManagerRole;
  }

  Future<void> fetchRoleForProject(String projectId) async {
    final user = ref.read(authNotifierProvider).currentUser;
    if (user == null) return;

    final role = user.role == 'admin' ? 'project_manager' : 'member';
    state = state.copyWith(
      projectRoles: {...state.projectRoles, projectId: role},
    );
  }

  Future<void> fetchRolesForProjects(List<String> projectIds) async {
    await Future.wait(projectIds.map(fetchRoleForProject));
  }
}
