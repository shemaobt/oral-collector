import 'dart:convert';

import '../../../../core/network/api_error_handler.dart';
import '../../../../core/network/authenticated_client.dart';
import '../../domain/entities/language.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/project_member.dart';
import '../../domain/repositories/project_repository.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final AuthenticatedClient _client;

  ProjectRepositoryImpl({required AuthenticatedClient client})
    : _client = client;

  @override
  Future<Language> createLanguage({
    required String name,
    required String code,
  }) async {
    final response = await _client.post(
      '/api/languages',
      body: {'name': name, 'code': code},
    );
    guardResponse(response);
    if (response.statusCode != 201) {
      throw Exception('Failed to create language: ${response.body}');
    }
    return Language.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<List<Language>> listLanguages() async {
    final response = await _client.get('/api/languages');
    guardResponse(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to list languages: ${response.body}');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => Language.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Project>> listProjects() async {
    final response = await _client.get('/api/oc/projects');
    guardResponse(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to list projects: ${response.body}');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => Project.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Project> getProject(String id) async {
    final response = await _client.get('/api/projects/$id');
    if (response.statusCode != 200) {
      throw Exception('Failed to get project: ${response.body}');
    }
    return Project.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> getProjectStats(String projectId) async {
    final response = await _client.get('/api/oc/projects/$projectId/stats');
    guardResponse(response);
    if (response.statusCode != 200) return {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  @override
  Future<Project> createProject({
    required String name,
    required String languageId,
    String? description,
  }) async {
    final body = <String, dynamic>{'name': name, 'language_id': languageId};
    if (description != null) body['description'] = description;

    final response = await _client.post('/api/projects', body: body);
    guardResponse(response);
    if (response.statusCode != 201) {
      throw Exception('Failed to create project: ${response.body}');
    }
    return Project.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<List<ProjectMember>> listMembers(String projectId) async {
    final response = await _client.get('/api/projects/$projectId/access/users');
    guardResponse(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to list members: ${response.body}');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => ProjectMember.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> removeMember(String projectId, String userId) async {
    final response = await _client.delete(
      '/api/projects/$projectId/access/users/$userId',
    );
    guardResponse(response);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to remove member: ${response.body}');
    }
  }

  @override
  Future<void> inviteMember({
    required String projectId,
    required String email,
    required String role,
  }) async {
    final response = await _client.post(
      '/api/oc/projects/$projectId/invites',
      body: {'email': email, 'role': role},
    );
    guardResponse(response);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send invite: ${response.body}');
    }
  }

  @override
  Future<Project> updateProject(String id, Map<String, dynamic> data) async {
    final response = await _client.patch('/api/projects/$id', body: data);
    guardResponse(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to update project: ${response.body}');
    }
    return Project.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
