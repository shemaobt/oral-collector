import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/invite.dart';
import '../repositories/invite_repository.dart';

// --- State ---

class InviteState {
  final List<Invite> invites;
  final bool isLoading;
  final String? error;

  const InviteState({
    this.invites = const [],
    this.isLoading = false,
    this.error,
  });

  int get pendingCount => invites.length;

  InviteState copyWith({
    List<Invite>? invites,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return InviteState(
      invites: invites ?? this.invites,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// --- Providers ---

final inviteRepositoryProvider = Provider<InviteRepository>(
  (_) => InviteRepository(),
);

final inviteNotifierProvider =
    NotifierProvider<InviteNotifier, InviteState>(InviteNotifier.new);

// --- Notifier ---

class InviteNotifier extends Notifier<InviteState> {
  InviteRepository get _repo => ref.read(inviteRepositoryProvider);

  @override
  InviteState build() {
    return const InviteState();
  }

  /// Fetch pending invites for the current user.
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

  /// Accept an invite and remove it from the list.
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

  /// Decline an invite and remove it from the list.
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
