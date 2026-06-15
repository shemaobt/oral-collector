import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/observability/error_reporter.dart';
import '../../../sync/presentation/notifiers/sync_notifier.dart';
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
    if (!ref.read(syncNotifierProvider).isOnline) {
      state = state.copyWith(isLoading: false, clearError: true);
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final members = await _repo.listMembers(projectId);
      state = state.copyWith(members: members, isLoading: false);
    } on Exception catch (e, st) {
      _reportUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: e);
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
    } on Exception catch (e, st) {
      _reportUnexpected(e, st);
      state = state.copyWith(error: e);
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
    } on Exception catch (e, st) {
      _reportUnexpected(e, st);
      state = state.copyWith(error: e);
      return false;
    }
  }

  void _reportUnexpected(Object error, StackTrace stackTrace) {
    // 401 é sessão expirada esperada (tratada por refresh/login alhures);
    // só erros inesperados vão à telemetria.
    if (error is UnauthorizedException) return;
    ref.read(errorReporterProvider).reportError(error, stackTrace);
  }
}
