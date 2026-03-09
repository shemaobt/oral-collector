import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/env.dart';
import '../../domain/entities/user.dart';

class AuthRepository {
  final http.Client _client;

  AuthRepository({http.Client? client}) : _client = client ?? http.Client();

  String get _baseUrl => Env.backendUrl;

  Future<({User user, String accessToken, String refreshToken})> login(
    String email,
    String password,
  ) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode != 200) {
      throw Exception('Login failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (
      user: User.fromJson(data['user'] as Map<String, dynamic>),
      accessToken: data['tokens']['access_token'] as String,
      refreshToken: data['tokens']['refresh_token'] as String,
    );
  }

  Future<({User user, String accessToken, String refreshToken})> signup(
    String email,
    String password,
    String? displayName,
  ) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
    };
    if (displayName != null) {
      body['display_name'] = displayName;
    }

    final response = await _client.post(
      Uri.parse('$_baseUrl/api/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      throw Exception('Signup failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (
      user: User.fromJson(data['user'] as Map<String, dynamic>),
      accessToken: data['tokens']['access_token'] as String,
      refreshToken: data['tokens']['refresh_token'] as String,
    );
  }

  Future<({String accessToken, String refreshToken})> refreshToken(
    String token,
  ) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': token}),
    );

    if (response.statusCode != 200) {
      throw Exception('Token refresh failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
  }

  Future<User> getMe(String accessToken) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get user: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return User.fromJson(data);
  }
}
