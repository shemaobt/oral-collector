import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/env.dart';
import '../../domain/entities/genre.dart';

class GenreRepository {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  GenreRepository({
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

  /// List all genres with nested subcategories.
  Future<List<Genre>> listGenres() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/oc/genres'),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to list genres: ${response.body}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => Genre.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
