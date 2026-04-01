import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

import '../../../../core/auth/auth_repository.dart';
import '../../../../core/config/env.dart';
import '../../domain/entities/user.dart';

class AuthRepositoryImpl implements AuthRepository {
  final http.Client _client;

  AuthRepositoryImpl({http.Client? client}) : _client = client ?? http.Client();

  String get _baseUrl => Env.backendUrl;

  @override
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

  @override
  Future<({User user, String accessToken, String refreshToken})> signup(
    String email,
    String password,
    String? displayName,
  ) async {
    final body = <String, dynamic>{'email': email, 'password': password};
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

  @override
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

  @override
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

  @override
  Future<User> updateMe(
    String accessToken, {
    String? displayName,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['display_name'] = displayName;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;

    final response = await _client.patch(
      Uri.parse('$_baseUrl/api/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return User.fromJson(data);
  }

  @override
  Future<String> uploadImage(
    String accessToken,
    String filePath, {
    String folder = 'avatars',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/uploads/image?folder=$folder'),
    );
    request.headers['Authorization'] = 'Bearer $accessToken';

    final ext = p.extension(filePath).toLowerCase();
    final mimeType = switch (ext) {
      '.png' => MediaType('image', 'png'),
      '.webp' => MediaType('image', 'webp'),
      _ => MediaType('image', 'jpeg'),
    };

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: mimeType,
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception('Failed to upload image: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['url'] as String;
  }

  @override
  Future<void> deleteAccount(String accessToken) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/api/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete account: ${response.body}');
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'app_key': 'oral-collector'}),
    );

    if (response.statusCode != 200) {
      throw Exception('Password reset failed: ${response.body}');
    }
  }

  @override
  Future<void> resetPassword(String token, String newPassword) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'password': newPassword}),
    );

    if (response.statusCode != 200) {
      throw Exception('Reset password failed: ${response.body}');
    }
  }
}
