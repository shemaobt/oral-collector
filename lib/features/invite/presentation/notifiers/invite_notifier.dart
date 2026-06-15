import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/observability/error_reporter.dart';
import '../../data/providers.dart';
import '../../domain/repositories/invite_repository.dart';
import 'invite_state.dart';

final inviteNotifierProvider = NotifierProvider<InviteNotifier, InviteState>(
  InviteNotifier.new,
);

class InviteNotifier extends Notifier<InviteState> {
  InviteRepository get _repo => ref.read(inviteRepositoryProvider);

  @override
  InviteState build() => const InviteState();

  Future<void> fetchInvites() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final invites = await _repo.fetchMyInvites();
      state = state.copyWith(invites: invites, isLoading: false);
    } on UnauthorizedException {
      state = state.copyWith(isLoading: false);
      // Fire-and-forget: handleUnauthorized pode propagar uma falha transitória
      // de refresh (ENG-141); aqui ela é ignorada (sessão preservada). Só
      // Exceptions, não Errors, para não mascarar bugs.
      ref
          .read(authNotifierProvider.notifier)
          .handleUnauthorized()
          .catchError((_) => false, test: (e) => e is Exception);
    } on Exception catch (e, st) {
      ref.read(errorReporterProvider).reportError(e, st);
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<bool> acceptInvite(String inviteId) async {
    state = state.copyWith(clearError: true);
    try {
      await _repo.acceptInvite(inviteId);
      state = state.copyWith(
        invites: state.invites.where((i) => i.id != inviteId).toList(),
      );
      return true;
    } on UnauthorizedException {
      ref
          .read(authNotifierProvider.notifier)
          .handleUnauthorized()
          .catchError((_) => false, test: (e) => e is Exception);
      return false;
    } on Exception catch (e, st) {
      ref.read(errorReporterProvider).reportError(e, st);
      state = state.copyWith(error: e);
      return false;
    }
  }

  Future<bool> declineInvite(String inviteId) async {
    state = state.copyWith(clearError: true);
    try {
      await _repo.declineInvite(inviteId);
      state = state.copyWith(
        invites: state.invites.where((i) => i.id != inviteId).toList(),
      );
      return true;
    } on UnauthorizedException {
      ref
          .read(authNotifierProvider.notifier)
          .handleUnauthorized()
          .catchError((_) => false, test: (e) => e is Exception);
      return false;
    } on Exception catch (e, st) {
      ref.read(errorReporterProvider).reportError(e, st);
      state = state.copyWith(error: e);
      return false;
    }
  }
}
