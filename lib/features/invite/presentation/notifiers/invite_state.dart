import '../../domain/entities/invite.dart';

class InviteState {
  final List<Invite> invites;
  final bool isLoading;
  final Object? error;

  const InviteState({
    this.invites = const [],
    this.isLoading = false,
    this.error,
  });

  int get pendingCount => invites.length;

  InviteState copyWith({
    List<Invite>? invites,
    bool? isLoading,
    Object? error,
    bool clearError = false,
  }) {
    return InviteState(
      invites: invites ?? this.invites,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
