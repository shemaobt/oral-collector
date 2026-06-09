import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/domain/entities/user.dart';
import '../../features/sync/data/providers.dart';
import '../errors/api_exception.dart';
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
  static const _cachedUserKey = 'cached_user';

  FlutterSecureStorage get _storage => ref.read(secureStorageProvider);
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<bool>? _inFlightRefresh;

  @override
  AuthState build() {
    return const AuthState();
  }

  Future<void> tryAutoLogin() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    if (accessToken == null) return;

    final cached = await _readCachedUser();
    if (cached != null) {
      state = state.copyWith(currentUser: cached, clearError: true);
    }

    final online = await ref.read(connectivityServiceProvider).isOnline;
    if (!online) return;

    if (cached == null) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final user = await _repo.getMe(accessToken);
      await _storeUser(user);
      state = state.copyWith(currentUser: user, isLoading: false);
    } on UnauthorizedException {
      try {
        final refreshed = await _tryRefresh();
        if (!refreshed) {
          await _clearTokens();
          state = const AuthState();
        }
      } on Exception {
        // Refresh transitório no boot: preserva a sessão em cache (offline-first).
        state = state.copyWith(isLoading: false);
      }
    } on Exception {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repo.login(email, password);
      await _storeTokens(result.accessToken, result.refreshToken);
      await _storeUser(result.user);
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
      await _storeUser(result.user);
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
      await _storeUser(user);
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
      await _storeUser(user);
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

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final accessToken = await _storage.read(key: _accessTokenKey);
      if (accessToken == null) throw Exception('Not authenticated');

      await _repo.deleteAccount(accessToken);
      await _clearTokens();
      state = const AuthState();
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

  Future<void> _storeTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _cachedUserKey);
  }

  Future<void> _storeUser(User user) =>
      _storage.write(key: _cachedUserKey, value: jsonEncode(user.toJson()));

  Future<User?> _readCachedUser() async {
    final raw = await _storage.read(key: _cachedUserKey);
    if (raw == null) return null;
    try {
      return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null; // corrupt cached user → treat as no cache (incl. cast Errors)
    }
  }

  // Single-flight: chamadas concorrentes compartilham UM refresh em voo, então
  // N respostas 401 simultâneas disparam só uma rotação de token (ENG-136).
  // Mantém-se NÃO-async — o slot precisa ser atribuído antes de qualquer await,
  // senão a corrida reaparece.
  Future<bool> _tryRefresh() {
    return _inFlightRefresh ??= _doTryRefresh().whenComplete(
      () => _inFlightRefresh = null,
    );
  }

  Future<bool> _doTryRefresh() async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;

      final tokens = await _repo.refreshToken(refreshToken);
      await _storeTokens(tokens.accessToken, tokens.refreshToken);

      final user = await _repo.getMe(tokens.accessToken);
      await _storeUser(user);
      state = state.copyWith(currentUser: user, isLoading: false);
      return true;
    } on UnauthorizedException {
      return false;
    }
    // Outras exceções (rede/timeout/5xx/parse) são transitórias: propagam para a
    // request falhar como erro de rede, preservando a sessão (ENG-141).
  }
}
