import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/env.dart';
import '../../../../core/errors/api_exception.dart';

/// Repository for server-side recording operations (DELETE, PATCH).
class RecordingApiRepository {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  RecordingApiRepository({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  String get _baseUrl => Env.backendUrl;

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: 'access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Delete a recording from the server.
  /// Returns true if successful (200/204) or recording not found (404).
  /// Throws [ForbiddenException] on 403.
  Future<bool> deleteRecording(String serverId) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/api/oc/recordings/$serverId'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 403) {
      throw const ForbiddenException();
    }
    return response.statusCode == 200 ||
        response.statusCode == 204 ||
        response.statusCode == 404;
  }

  /// Update a recording's genre/subcategory on the server.
  /// Returns true if successful.
  /// Throws [ForbiddenException] on 403.
  Future<bool> updateRecording(
    String serverId, {
    String? genreId,
    String? subcategoryId,
  }) async {
    final body = <String, dynamic>{};
    if (genreId != null) body['genre_id'] = genreId;
    if (subcategoryId != null) body['subcategory_id'] = subcategoryId;

    final response = await _client.patch(
      Uri.parse('$_baseUrl/api/oc/recordings/$serverId'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    if (response.statusCode == 403) {
      throw const ForbiddenException();
    }
    return response.statusCode == 200;
  }
}
