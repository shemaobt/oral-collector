import 'dart:convert';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/authenticated_client.dart';
import '../../../../core/network/api_error_handler.dart';
import '../../domain/entities/server_recording.dart';
import '../../domain/repositories/recording_api_repository.dart';

class RecordingApiRepositoryImpl implements RecordingApiRepository {
  final AuthenticatedClient _client;

  RecordingApiRepositoryImpl({required AuthenticatedClient client})
    : _client = client;

  @override
  Future<ServerRecording> getRecording(String serverId) async {
    final response = await _client.get('/api/oc/recordings/$serverId');
    guardResponse(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to get recording: ${response.body}');
    }
    return ServerRecording.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<List<ServerRecording>> listRecordings(
    String projectId, {
    int offset = 0,
    int limit = 50,
    String? userId,
    String? storytellerId,
    String? uploadStatus,
  }) async {
    final params = <String, String>{
      'project_id': projectId,
      'offset': '$offset',
      'limit': '$limit',
      if (userId != null && userId.isNotEmpty) 'user_id': userId,
      if (storytellerId != null && storytellerId.isNotEmpty)
        'storyteller_id': storytellerId,
      if (uploadStatus != null && uploadStatus.isNotEmpty)
        'upload_status': uploadStatus,
    };
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final response = await _client.get('/api/oc/recordings?$query');
    guardResponse(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to list recordings: ${response.body}');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => ServerRecording.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<bool> deleteRecording(String serverId) async {
    final response = await _client.delete('/api/oc/recordings/$serverId');
    guardResponse(response);
    if (response.statusCode == 403) {
      throw const ForbiddenException();
    }
    return response.statusCode == 200 ||
        response.statusCode == 204 ||
        response.statusCode == 404;
  }

  @override
  Future<bool> updateRecording(
    String serverId, {
    String? title,
    String? description,
    String? genreId,
    String? subcategoryId,
    String? registerId,
    String? storytellerId,
    String? cleaningStatus,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (genreId != null) body['genre_id'] = genreId;
    if (subcategoryId != null) body['subcategory_id'] = subcategoryId;
    if (registerId != null) body['register_id'] = registerId;
    if (storytellerId != null) body['storyteller_id'] = storytellerId;
    if (cleaningStatus != null) body['cleaning_status'] = cleaningStatus;

    final response = await _client.patch(
      '/api/oc/recordings/$serverId',
      body: body,
    );
    guardResponse(response);
    if (response.statusCode == 403) {
      throw const ForbiddenException();
    }
    return response.statusCode == 200;
  }

  @override
  Future<int> clearStaleRecordings(String projectId) async {
    final response = await _client.post(
      '/api/oc/recordings/clear-stale?project_id=$projectId',
    );
    guardResponse(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to clear stale recordings: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['deleted'] as int? ?? 0;
  }

  @override
  Future<List<String>> splitRecording({
    required String serverId,
    required List<Map<String, double>> segments,
  }) async {
    final response = await _client.post(
      '/api/oc/recordings/$serverId/split',
      body: {'segments': segments},
    );
    guardResponse(response);
    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 202) {
      throw Exception(
        'Split failed (${response.statusCode}): ${response.body}',
      );
    }
    final data = jsonDecode(response.body);
    if (data is Map<String, dynamic> && data.containsKey('recording_ids')) {
      return (data['recording_ids'] as List<dynamic>).cast<String>();
    }
    return [];
  }
}
