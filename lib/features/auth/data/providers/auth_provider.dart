import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/user.dart';
import '../repositories/auth_repository.dart';

// --- State ---

class AuthState {
  final User? currentUser;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.currentUser,
    this.isLoading = false,
    this.error,
  });

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

// --- Providers ---

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (_) => AuthRepository(),
);

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// --- Notifier ---

class AuthNotifier extends Notifier<AuthState> {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  FlutterSecureStorage get _storage => ref.read(secureStorageProvider);
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    return const AuthState();
  }

  /// Check for stored token and auto-login on app start.
  Future<void> tryAutoLogin() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    if (accessToken == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await _repo.getMe(accessToken);
      state = state.copyWith(currentUser: user, isLoading: false);
    } on Exception catch (e) {
      // Token may be expired — try refresh
      final refreshed = await _tryRefresh();
      if (!refreshed) {
        await _clearTokens();
        state = const AuthState();
      }
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repo.login(email, password);
      await _storeTokens(result.accessToken, result.refreshToken);
      state = state.copyWith(currentUser: result.user, isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> signup(
    String email,
    String password, {
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repo.signup(email, password, displayName);
      await _storeTokens(result.accessToken, result.refreshToken);
      state = state.copyWith(currentUser: result.user, isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    await _clearTokens();
    state = const AuthState();
  }

  // --- Private helpers ---

  Future<void> _storeTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<bool> _tryRefresh() async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;

      final tokens = await _repo.refreshToken(refreshToken);
      await _storeTokens(tokens.accessToken, tokens.refreshToken);

      final user = await _repo.getMe(tokens.accessToken);
      state = state.copyWith(currentUser: user, isLoading: false);
      return true;
    } on Exception {
      return false;
    }
  }
}
