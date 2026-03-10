import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/env.dart';
import '../../../../core/errors/api_exception.dart';
import '../../domain/entities/language.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/project_member.dart';

class ProjectRepository {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  ProjectRepository({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  String get _baseUrl => Env.backendUrl;

  /// Check response for 403 Forbidden and throw ForbiddenException.
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

    _checkForbidden(response);
    if (response.statusCode != 201) {
      throw Exception('Failed to create project: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Project.fromJson(data);
  }

  /// List members of a project.
  Future<List<ProjectMember>> listMembers(String projectId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/oc/projects/$projectId/members'),
      headers: await _authHeaders(),
    );

    _checkForbidden(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to list members: ${response.body}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => ProjectMember.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Remove a member from a project.
  Future<void> removeMember(String projectId, String userId) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/api/oc/projects/$projectId/members/$userId'),
      headers: await _authHeaders(),
    );

    _checkForbidden(response);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to remove member: ${response.body}');
    }
  }

  /// Invite a user to a project.
  Future<void> inviteMember({
    required String projectId,
    required String email,
    required String role,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/oc/projects/$projectId/invites'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'email': email,
        'role': role,
      }),
    );

    _checkForbidden(response);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send invite: ${response.body}');
    }
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

    _checkForbidden(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to update project: ${response.body}');
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    return Project.fromJson(responseData);
  }
}
