import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/sync/data/providers.dart';
import '../providers/secure_storage_provider.dart';
import 'auth_repository.dart';
import 'auth_state.dart';
import 'providers.dart';

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  FlutterSecureStorage get _storage => ref.read(secureStorageProvider);
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    return const AuthState();
  }

  Future<void> tryAutoLogin() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    if (accessToken == null) return;

    // Skip network call when offline — tokens stay preserved
    final connectivity = ref.read(connectivityServiceProvider);
    final online = await connectivity.isOnline;
    if (!online) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await _repo.getMe(accessToken);
      state = state.copyWith(currentUser: user, isLoading: false);
    } on Exception {
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

  Future<void> updateProfile({String? displayName}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final accessToken = await _storage.read(key: _accessTokenKey);
      if (accessToken == null) throw Exception('Not authenticated');

      final user = await _repo.updateMe(accessToken, displayName: displayName);
      state = state.copyWith(currentUser: user, isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> uploadAvatar(String filePath) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final accessToken = await _storage.read(key: _accessTokenKey);
      if (accessToken == null) throw Exception('Not authenticated');

      final imageUrl = await _repo.uploadImage(accessToken, filePath);
      final user = await _repo.updateMe(accessToken, avatarUrl: imageUrl);
      state = state.copyWith(currentUser: user, isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<bool> handleUnauthorized() async {
    final refreshed = await _tryRefresh();
    if (!refreshed) {
      await _clearTokens();
      state = const AuthState();
    }
    return refreshed;
  }

  Future<void> logout() async {
    await _clearTokens();
    state = const AuthState();
  }

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
