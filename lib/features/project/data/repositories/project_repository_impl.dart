import '../../../../core/network/api_error_handler.dart';
import '../../../../core/network/authenticated_client.dart';
import '../../../../core/network/response_decoder.dart';
import '../../../../core/observability/error_reporter.dart';
import '../../../../core/serialization/parse_list.dart';
import '../../domain/entities/language.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/project_member.dart';
import '../../domain/entities/project_stats.dart';
import '../../domain/entities/project_update.dart';
import '../../domain/repositories/project_repository.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final AuthenticatedClient _client;
  final ErrorReporter _reporter;

  ProjectRepositoryImpl({
    required AuthenticatedClient client,
    required ErrorReporter reporter,
  }) : _client = client,
       _reporter = reporter;

  @override
  Future<Language> createLanguage({
    required String name,
    required String code,
  }) async {
    final response = await _client.post(
      '/api/languages',
      body: {'name': name, 'code': code},
    );
    return Language.fromJson(decodeObject(response));
  }

  @override
  Future<List<Language>> listLanguages() async {
    final response = await _client.get('/api/languages');
    return parseList(
      decodeList(response),
      Language.fromJson,
      context: 'listLanguages',
      onSkip: _reporter.parseSkipSink(context: 'listLanguages'),
    );
  }

  @override
  Future<List<Project>> listProjects() async {
    final response = await _client.get('/api/oc/projects');
    return parseList(
      decodeList(response),
      Project.fromJson,
      context: 'listProjects',
      onSkip: _reporter.parseSkipSink(context: 'listProjects'),
    );
  }

  @override
  Future<Project> getProject(String id) async {
    final response = await _client.get('/api/projects/$id');
    return Project.fromJson(decodeObject(response));
  }

  @override
  Future<ProjectStats> getProjectStats(String projectId) async {
    final response = await _client.get('/api/oc/projects/$projectId/stats');
    return ProjectStats.fromJson(decodeObject(response));
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
    return Project.fromJson(decodeObject(response));
  }

  @override
  Future<List<ProjectMember>> listMembers(String projectId) async {
    final response = await _client.get('/api/projects/$projectId/access/users');
    return parseList(
      decodeList(response),
      ProjectMember.fromJson,
      context: 'listMembers',
      onSkip: _reporter.parseSkipSink(context: 'listMembers'),
    );
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
  Future<Project> updateProject(String id, ProjectUpdate update) async {
    final response = await _client.patch(
      '/api/projects/$id',
      body: update.toJson(),
    );
    return Project.fromJson(decodeObject(response));
  }
}
