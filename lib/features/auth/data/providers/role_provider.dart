import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/network/authenticated_client.dart';

class RoleState {
  final Map<String, String> projectRoles;
  final bool _fetched;

  const RoleState({this.projectRoles = const {}, bool fetched = false})
    : _fetched = fetched;

  bool isProjectManager(String projectId) {
    return projectRoles[projectId] == 'manager';
  }

  bool get hasAnyManagerRole {
    return projectRoles.values.any((r) => r == 'manager');
  }

  RoleState copyWith({Map<String, String>? projectRoles, bool? fetched}) {
    return RoleState(
      projectRoles: projectRoles ?? this.projectRoles,
      fetched: fetched ?? _fetched,
    );
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
    return user?.isPlatformAdmin ?? false;
  }

  bool canManageProject(String projectId) {
    if (isPlatformAdmin) return true;
    return state.isProjectManager(projectId);
  }

  bool get canCreateProject {
    return isPlatformAdmin;
  }

  Future<void> fetchRoleForProject(String projectId) async {
    if (!state._fetched) {
      await _fetchAllProjectRoles();
    }
  }

  Future<void> fetchRolesForProjects(List<String> projectIds) async {
    if (!state._fetched) {
      await _fetchAllProjectRoles();
    }
  }

  Future<void> _fetchAllProjectRoles() async {
    final user = ref.read(authNotifierProvider).currentUser;
    if (user == null) return;

    try {
      final client = ref.read(authenticatedClientProvider);
      final response = await client.get('/api/auth/my-project-roles');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rolesMap = data['project_roles'] as Map<String, dynamic>? ?? {};
        final projectRoles = rolesMap.map(
          (key, value) => MapEntry(key, value as String),
        );
        state = state.copyWith(projectRoles: projectRoles, fetched: true);
      }
    } catch (_) {}
  }

  void invalidate() {
    state = const RoleState();
  }
}
