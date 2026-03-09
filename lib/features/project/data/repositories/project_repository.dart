import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/env.dart';
import '../../domain/entities/language.dart';
import '../../domain/entities/project.dart';

class ProjectRepository {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  ProjectRepository({
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

  /// List all available languages.
  Future<List<Language>> listLanguages() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/languages'),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to list languages: ${response.body}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => Language.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// List all projects the current user is a member of.
  Future<List<Project>> listProjects() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/oc/projects'),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to list projects: ${response.body}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => Project.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get a single project by ID.
  Future<Project> getProject(String id) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/projects/$id'),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get project: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Project.fromJson(data);
  }

  /// Create a new project.
  Future<Project> createProject({
    required String name,
    required String languageId,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'language_id': languageId,
    };
    if (description != null) {
      body['description'] = description;
    }

    final response = await _client.post(
      Uri.parse('$_baseUrl/api/projects'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create project: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Project.fromJson(data);
  }

  /// Update a project.
  Future<Project> updateProject(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/api/projects/$id'),
      headers: await _authHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update project: ${response.body}');
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    return Project.fromJson(responseData);
  }
}
