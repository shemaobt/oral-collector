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
  Future<List<ServerRecording>> listRecordings(String projectId) async {
    final response = await _client.get(
      '/api/oc/recordings?project_id=$projectId',
    );
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
    String? genreId,
    String? subcategoryId,
    String? cleaningStatus,
  }) async {
    final body = <String, dynamic>{};
    if (genreId != null) body['genre_id'] = genreId;
    if (subcategoryId != null) body['subcategory_id'] = subcategoryId;
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
}
