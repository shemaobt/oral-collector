import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/domain/entities/user.dart';
import '../../features/sync/data/providers.dart';
import '../errors/api_exception.dart';
import '../observability/error_reporter.dart';
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
  static const _errSecDuplicateItem = -25299;

  FlutterSecureStorage get _storage => ref.read(secureStorageProvider);
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<bool>? _inFlightRefresh;

  @override
  AuthState build() {
    return const AuthState();
  }

  /// Local-only session restore (token + cached user). Fast and never throws,
  /// so the startup gate can await it before the router decides the first route
  /// without a logged-out flash and without blocking on the network.
  Future<void> restoreSession() async {
    try {
      final accessToken = await _storage.read(key: _accessTokenKey);
      if (accessToken == null) return;

      final cached = await _readCachedUser();
      if (cached != null) {
        state = state.copyWith(currentUser: cached, clearError: true);
      }
    } on Exception {
      // Keychain read failure at boot → stay logged out; the router sends the
      // user to login rather than wedging the splash.
    }
  }

  /// Online half of auto-login: refreshes the cached user against the server.
  /// Runs after [restoreSession] (and after the startup gate), so a slow or
  /// offline getMe never delays first frame.
  Future<void> refreshSessionIfOnline() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    if (accessToken == null) return;

    final online = await ref.read(connectivityServiceProvider).isOnline;
    if (!online) return;

    if (state.currentUser == null) {
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

  Future<void> tryAutoLogin() async {
    await restoreSession();
    await refreshSessionIfOnline();
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repo.login(email, password);
      await _storeTokens(result.accessToken, result.refreshToken);
      await _storeUser(result.user);
      state = state.copyWith(currentUser: result.user, isLoading: false);
    } on Exception catch (e, st) {
      ref.read(errorReporterProvider).reportError(e, st);
      state = state.copyWith(isLoading: false, error: e);
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
    } on Exception catch (e, st) {
      ref.read(errorReporterProvider).reportError(e, st);
      state = state.copyWith(isLoading: false, error: e);
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
    } on Exception catch (e, st) {
      ref.read(errorReporterProvider).reportError(e, st);
      state = state.copyWith(isLoading: false, error: e);
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
    } on Exception catch (e, st) {
      ref.read(errorReporterProvider).reportError(e, st);
      state = state.copyWith(isLoading: false, error: e);
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
    } on Exception catch (e, st) {
      ref.read(errorReporterProvider).reportError(e, st);
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> logout() async {
    await _clearTokens();
    state = const AuthState();
  }

  Future<void> _storeTokens(String accessToken, String refreshToken) async {
    await _writeIdempotent(_accessTokenKey, accessToken);
    await _writeIdempotent(_refreshTokenKey, refreshToken);
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _cachedUserKey);
  }

  Future<void> _storeUser(User user) =>
      _writeIdempotent(_cachedUserKey, jsonEncode(user.toJson()));

  // errSecDuplicateItem: o write do plugin faz upsert, mas quando seu precheck
  // containsKey não casa o item existente (ex.: a accessibility mudou — ENG-128)
  // ele cai no SecItemAdd e colide. O delete do plugin é accessibility-agnóstico,
  // então remover + regravar recupera; outras PlatformException propagam.
  Future<void> _writeIdempotent(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on PlatformException catch (e) {
      final isDuplicate =
          e.details == _errSecDuplicateItem ||
          (e.message?.contains('$_errSecDuplicateItem') ?? false) ||
          (e.message?.toLowerCase().contains('already exists') ?? false);
      if (!isDuplicate) rethrow;
      await _storage.delete(key: key);
      await _storage.write(key: key, value: value);
    }
  }

  Future<User?> _readCachedUser() async {
    final raw = await _storage.read(key: _cachedUserKey);
    if (raw == null) return null;
    try {
      return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null; // corrupt cached user → treat as no cache (incl. cast Errors)
    }
  }

  // Single-flight: concurrent callers share ONE in-flight refresh, so N
  // simultaneous 401s trigger a single token rotation (ENG-136). Must stay
  // non-async: the slot has to be assigned before any await, or the race
  // returns.
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
