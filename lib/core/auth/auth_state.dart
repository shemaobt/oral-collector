import '../../features/auth/domain/entities/user.dart';

class AuthState {
  final User? currentUser;
  final bool isLoading;
  final String? error;

  const AuthState({this.currentUser, this.isLoading = false, this.error});

  bool get isAuthenticated => currentUser != null;

  AuthState copyWith({
    User? currentUser,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
