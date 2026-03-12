import '../../domain/entities/invite.dart';

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
