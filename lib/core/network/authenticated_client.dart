import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../auth/auth_notifier.dart';
import '../config/env.dart';
import '../providers/http_client_provider.dart';
import '../providers/secure_storage_provider.dart';

typedef TokenRefresher = Future<bool> Function();

class AuthenticatedClient {
  final http.Client _client;
  final FlutterSecureStorage _storage;
  final TokenRefresher? _refreshToken;
  bool _isRefreshing = false;

  AuthenticatedClient({
    required http.Client client,
    required FlutterSecureStorage storage,
    TokenRefresher? refreshToken,
  }) : _client = client,
       _storage = storage,
       _refreshToken = refreshToken;

  String get baseUrl => Env.backendUrl;

  Future<Map<String, String>> _headers([Map<String, String>? extra]) async {
    final token = await _storage.read(key: 'access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?extra,
    };
  }

  Future<http.Response> _withRefresh(
    Future<http.Response> Function() request,
  ) async {
    final response = await request();
    if (response.statusCode == 401 && _refreshToken != null && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshed = await _refreshToken();
        if (refreshed) {
          return request();
        }
      } finally {
        _isRefreshing = false;
      }
    }
    return response;
  }

  Future<http.Response> get(String path) async {
    return _withRefresh(
      () async =>
          _client.get(Uri.parse('$baseUrl$path'), headers: await _headers()),
    );
  }

  Future<http.Response> post(String path, {Object? body}) async {
    return _withRefresh(
      () async => _client.post(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(),
        body: body is String ? body : (body != null ? jsonEncode(body) : null),
      ),
    );
  }

  Future<http.Response> patch(String path, {Object? body}) async {
    return _withRefresh(
      () async => _client.patch(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(),
        body: body is String ? body : (body != null ? jsonEncode(body) : null),
      ),
    );
  }

  Future<http.Response> put(
    String url, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    return _client.put(
      Uri.parse(url.startsWith('http') ? url : '$baseUrl$url'),
      headers: headers ?? await _headers(),
      body: body is String ? body : (body != null ? jsonEncode(body) : null),
    );
  }

  Future<http.Response> delete(String path) async {
    return _withRefresh(
      () async =>
          _client.delete(Uri.parse('$baseUrl$path'), headers: await _headers()),
    );
  }

  Future<Map<String, String>> get authHeaders => _headers();

  http.Client get rawClient => _client;
}

final authenticatedClientProvider = Provider<AuthenticatedClient>((ref) {
  return AuthenticatedClient(
    client: ref.watch(httpClientProvider),
    storage: ref.watch(secureStorageProvider),
    refreshToken: () =>
        ref.read(authNotifierProvider.notifier).handleUnauthorized(),
  );
});
