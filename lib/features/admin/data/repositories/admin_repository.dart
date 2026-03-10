import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/env.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../genre/domain/entities/genre.dart';
import '../../../project/domain/entities/project.dart';
import '../../../recording/domain/entities/recording.dart';

/// System-wide admin stats returned by GET /api/oc/admin/stats.
class AdminStats {
  final int totalProjects;
  final int totalLanguages;
  final int totalRecordings;
  final double totalDurationSeconds;
  final int activeUsers;

  const AdminStats({
    this.totalProjects = 0,
    this.totalLanguages = 0,
    this.totalRecordings = 0,
    this.totalDurationSeconds = 0,
    this.activeUsers = 0,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalProjects: (json['total_projects'] as num?)?.toInt() ?? 0,
      totalLanguages: (json['total_languages'] as num?)?.toInt() ?? 0,
      totalRecordings: (json['total_recordings'] as num?)?.toInt() ?? 0,
      totalDurationSeconds:
          (json['total_duration_seconds'] as num?)?.toDouble() ?? 0,
      activeUsers: (json['active_users'] as num?)?.toInt() ?? 0,
    );
  }

  double get totalHours => totalDurationSeconds / 3600;
}

class AdminRepository {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  AdminRepository({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  String get _baseUrl => Env.backendUrl;

  void _checkForbidden(http.Response response) {
    if (response.statusCode == 403) {
      throw const ForbiddenException();
    }
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: 'access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Fetch system-wide admin stats.
  Future<AdminStats> fetchStats() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/oc/admin/stats'),
      headers: await _authHeaders(),
    );

    _checkForbidden(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch admin stats: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return AdminStats.fromJson(data);
  }

  /// Fetch all projects (admin view).
  Future<List<Project>> fetchAllProjects() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/oc/projects'),
      headers: await _authHeaders(),
    );

    _checkForbidden(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch projects: ${response.body}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => Project.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch all genres (admin view).
  Future<List<Genre>> fetchAllGenres() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/oc/genres'),
      headers: await _authHeaders(),
    );

    _checkForbidden(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch genres: ${response.body}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => Genre.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new genre.
  Future<Genre> createGenre({
    required String name,
    String? description,
    String? icon,
    String? color,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (description != null) body['description'] = description;
    if (icon != null) body['icon'] = icon;
    if (color != null) body['color'] = color;

    final response = await _client.post(
      Uri.parse('$_baseUrl/api/oc/genres'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );

    _checkForbidden(response);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create genre: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Genre.fromJson(data);
  }

  /// Update an existing genre.
  Future<Genre> updateGenre(String id, Map<String, dynamic> data) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/api/oc/genres/$id'),
      headers: await _authHeaders(),
      body: jsonEncode(data),
    );

    _checkForbidden(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to update genre: ${response.body}');
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    return Genre.fromJson(responseData);
  }

  /// Delete a genre (soft-delete).
  Future<void> deleteGenre(String id) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/api/oc/genres/$id'),
      headers: await _authHeaders(),
    );

    _checkForbidden(response);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete genre: ${response.body}');
    }
  }

  /// Create a new subcategory.
  Future<void> createSubcategory({
    required String genreId,
    required String name,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'genre_id': genreId,
      'name': name,
    };
    if (description != null) body['description'] = description;

    final response = await _client.post(
      Uri.parse('$_baseUrl/api/oc/subcategories'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );

    _checkForbidden(response);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create subcategory: ${response.body}');
    }
  }

  /// Delete a subcategory.
  Future<void> deleteSubcategory(String id) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/api/oc/subcategories/$id'),
      headers: await _authHeaders(),
    );

    _checkForbidden(response);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete subcategory: ${response.body}');
    }
  }

  /// Fetch recordings with cleaning_status = 'needs_cleaning' (admin view).
  Future<List<Recording>> fetchCleaningQueue() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/oc/admin/cleaning-queue'),
      headers: await _authHeaders(),
    );

    _checkForbidden(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch cleaning queue: ${response.body}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => Recording.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Trigger cleaning for a single recording.
  Future<void> triggerClean(String recordingId) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/oc/recordings/$recordingId/clean'),
      headers: await _authHeaders(),
    );

    _checkForbidden(response);
    if (response.statusCode != 200 && response.statusCode != 202) {
      throw Exception('Failed to trigger cleaning: ${response.body}');
    }
  }
}
