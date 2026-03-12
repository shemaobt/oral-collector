import 'dart:convert';

import '../../../../core/network/api_error_handler.dart';
import '../../../../core/network/authenticated_client.dart';
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
    guardResponse(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch admin stats: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return AdminStats.fromJson(data);
  }

  @override
  Future<List<Project>> fetchAllProjects() async {
    final response = await _client.get('/api/oc/projects');
    guardResponse(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch projects: ${response.body}');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => Project.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Genre>> fetchAllGenres() async {
    final response = await _client.get('/api/oc/genres');
    guardResponse(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch genres: ${response.body}');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => Genre.fromJson(json as Map<String, dynamic>))
        .toList();
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
    guardResponse(response);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create genre: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Genre.fromJson(data);
  }

  @override
  Future<Genre> updateGenre(String id, Map<String, dynamic> data) async {
    final response = await _client.patch('/api/oc/genres/$id', body: data);
    guardResponse(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to update genre: ${response.body}');
    }
    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    return Genre.fromJson(responseData);
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
    guardResponse(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch cleaning queue: ${response.body}');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => Recording.fromJson(json as Map<String, dynamic>))
        .toList();
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
