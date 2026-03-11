import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
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
    } on Exception catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
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
    } on Exception catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}
