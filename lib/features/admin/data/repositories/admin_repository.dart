import '../../../../core/network/api_error_handler.dart';
import '../../../../core/network/authenticated_client.dart';
import '../../../../core/network/response_decoder.dart';
import '../../../../core/serialization/parse_list.dart';
import '../../../genre/domain/entities/genre.dart';
import '../../../project/domain/entities/project.dart';
import '../../../recording/domain/entities/recording.dart';
import '../../domain/entities/admin_stats.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AuthenticatedClient _client;

  AdminRepositoryImpl({required AuthenticatedClient client}) : _client = client;

  @override
  Future<AdminStats> fetchStats() async {
    final response = await _client.get('/api/oc/admin/stats');
    return AdminStats.fromJson(decodeObject(response));
  }

  @override
  Future<List<Project>> fetchAllProjects() async {
    final response = await _client.get('/api/oc/projects');
    return parseList(
      decodeList(response),
      Project.fromJson,
      context: 'fetchAllProjects',
    );
  }

  @override
  Future<List<Genre>> fetchAllGenres() async {
    final response = await _client.get('/api/oc/genres');
    return parseList(
      decodeList(response),
      Genre.fromJson,
      context: 'fetchAllGenres',
    );
  }

  @override
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

    final response = await _client.post('/api/oc/genres', body: body);
    return Genre.fromJson(decodeObject(response));
  }

  @override
  Future<Genre> updateGenre(String id, Map<String, dynamic> data) async {
    final response = await _client.patch('/api/oc/genres/$id', body: data);
    return Genre.fromJson(decodeObject(response));
  }

  @override
  Future<void> deleteGenre(String id) async {
    final response = await _client.delete('/api/oc/genres/$id');
    guardResponse(response);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete genre: ${response.body}');
    }
  }

  @override
  Future<void> createSubcategory({
    required String genreId,
    required String name,
    String? description,
  }) async {
    final body = <String, dynamic>{'genre_id': genreId, 'name': name};
    if (description != null) body['description'] = description;

    final response = await _client.post('/api/oc/subcategories', body: body);
    guardResponse(response);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create subcategory: ${response.body}');
    }
  }

  @override
  Future<void> deleteSubcategory(String id) async {
    final response = await _client.delete('/api/oc/subcategories/$id');
    guardResponse(response);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete subcategory: ${response.body}');
    }
  }

  @override
  Future<List<Recording>> fetchCleaningQueue() async {
    final response = await _client.get('/api/oc/admin/cleaning-queue');
    return parseList(
      decodeList(response),
      Recording.fromJson,
      context: 'fetchCleaningQueue',
    );
  }

  @override
  Future<void> triggerClean(String recordingId) async {
    final response = await _client.post(
      '/api/oc/recordings/$recordingId/clean',
    );
    guardResponse(response);
    if (response.statusCode != 200 && response.statusCode != 202) {
      throw Exception('Failed to trigger cleaning: ${response.body}');
    }
  }
}
