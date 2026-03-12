import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/repositories/project_repository.dart';
import 'member_state.dart';

final memberNotifierProvider = NotifierProvider<MemberNotifier, MemberState>(
  MemberNotifier.new,
);

class MemberNotifier extends Notifier<MemberState> {
  ProjectRepository get _repo => ref.read(projectRepositoryProvider);

  @override
  MemberState build() => const MemberState();

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

  Future<bool> inviteMember({
    required String projectId,
    required String email,
    required String role,
  }) async {
    state = state.copyWith(clearError: true);

    try {
      await _repo.inviteMember(projectId: projectId, email: email, role: role);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}
