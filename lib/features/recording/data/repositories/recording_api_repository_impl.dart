import 'dart:convert';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/errors/app_exception.dart' show ParseException;
import '../../../../core/network/api_error_handler.dart';
import '../../../../core/network/authenticated_client.dart';
import '../../../../core/network/response_decoder.dart';
import '../../../../core/serialization/parse_list.dart';
import '../../../../core/serialization/safe_read.dart';
import '../../domain/entities/server_recording.dart';
import '../../domain/entities/split_segment_request.dart';
import '../../domain/repositories/recording_api_repository.dart';

class RecordingApiRepositoryImpl implements RecordingApiRepository {
  final AuthenticatedClient _client;

  RecordingApiRepositoryImpl({required AuthenticatedClient client})
    : _client = client;

  @override
  Future<ServerRecording> getRecording(String serverId) async {
    final response = await _client.get('/api/oc/recordings/$serverId');
    return ServerRecording.fromJson(decodeObject(response));
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
    return parseList(
      decodeList(response),
      ServerRecording.fromJson,
      context: 'listRecordings',
    );
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
    String? secondaryGenreId,
    String? secondarySubcategoryId,
    String? secondaryRegisterId,
    bool clearSecondary = false,
    String? storytellerId,
    String? cleaningStatus,
    double? durationSeconds,
    int? fileSizeBytes,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (genreId != null) body['genre_id'] = genreId;
    if (subcategoryId != null) body['subcategory_id'] = subcategoryId;
    if (registerId != null) body['register_id'] = registerId;
    if (clearSecondary) {
      body['secondary_genre_id'] = null;
      body['secondary_subcategory_id'] = null;
      body['secondary_register_id'] = null;
    } else {
      if (secondaryGenreId != null) {
        body['secondary_genre_id'] = secondaryGenreId;
      }
      if (secondarySubcategoryId != null) {
        body['secondary_subcategory_id'] = secondarySubcategoryId;
      }
      if (secondaryRegisterId != null) {
        body['secondary_register_id'] = secondaryRegisterId;
      }
    }
    if (storytellerId != null) body['storyteller_id'] = storytellerId;
    if (cleaningStatus != null) body['cleaning_status'] = cleaningStatus;
    if (durationSeconds != null) body['duration_seconds'] = durationSeconds;
    if (fileSizeBytes != null) body['file_size_bytes'] = fileSizeBytes;

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
    final data = decodeObject(response);
    return readIntOrNull(data, 'deleted') ?? 0;
  }

  @override
  Future<List<String>> splitRecording({
    required String serverId,
    required List<SplitSegmentRequest> segments,
  }) async {
    final response = await _client.post(
      '/api/oc/recordings/$serverId/split',
      body: {'segments': segments.map((s) => s.toJson()).toList()},
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
    if (data is! Map<String, dynamic>) return const [];
    final ids = data['recording_ids'];
    if (ids is! List) return const [];
    return ids.map((e) {
      if (e is String) return e;
      throw ParseException(
        field: 'recording_ids',
        expected: 'String',
        cause: e,
      );
    }).toList();
  }
}
