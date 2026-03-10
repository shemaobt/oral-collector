import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/project_member.dart';
import '../repositories/project_repository.dart';
import 'project_provider.dart';

// --- State ---

class MemberState {
  final List<ProjectMember> members;
  final bool isLoading;
  final String? error;

  const MemberState({
    this.members = const [],
    this.isLoading = false,
    this.error,
  });

  MemberState copyWith({
    List<ProjectMember>? members,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MemberState(
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// --- Provider ---

final memberNotifierProvider =
    NotifierProvider<MemberNotifier, MemberState>(MemberNotifier.new);

// --- Notifier ---

class MemberNotifier extends Notifier<MemberState> {
  ProjectRepository get _repo => ref.read(projectRepositoryProvider);

  @override
  MemberState build() {
    return const MemberState();
  }

  /// Fetch members for a project.
  Future<void> fetchMembers(String projectId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final members = await _repo.listMembers(projectId);
      state = state.copyWith(members: members, isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Remove a member from the project.
  Future<bool> removeMember(String projectId, String userId) async {
    state = state.copyWith(clearError: true);

    try {
      await _repo.removeMember(projectId, userId);
      state = state.copyWith(
        members: state.members.where((m) => m.userId != userId).toList(),
      );
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Invite a user to the project.
  Future<bool> inviteMember({
    required String projectId,
    required String email,
    required String role,
  }) async {
    state = state.copyWith(clearError: true);

    try {
      await _repo.inviteMember(
        projectId: projectId,
        email: email,
        role: role,
      );
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}
