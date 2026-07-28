import 'dart:convert';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/errors/app_exception.dart' show ParseException;
import '../../../../core/network/api_error_handler.dart';
import '../../../../core/network/authenticated_client.dart';
import '../../../../core/network/error_boundary.dart' show throwForResponse;
import '../../../../core/network/response_decoder.dart';
import '../../../../core/observability/error_reporter.dart';
import '../../../../core/serialization/parse_list.dart';
import '../../../../core/serialization/safe_read.dart';
import '../../domain/entities/server_recording.dart';
import '../../domain/entities/split_segment_request.dart';
import '../../domain/entities/update_recording_request.dart';
import '../../domain/repositories/recording_api_repository.dart';

class RecordingApiRepositoryImpl implements RecordingApiRepository {
  final AuthenticatedClient _client;
  final ErrorReporter _reporter;

  RecordingApiRepositoryImpl({
    required AuthenticatedClient client,
    required ErrorReporter reporter,
  }) : _client = client,
       _reporter = reporter;

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
    String? title,
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
      if (title != null && title.isNotEmpty) 'title': title,
    };
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    final response = await _client.get('/api/oc/recordings?$query');
    return parseList(
      decodeList(response),
      ServerRecording.fromJson,
      context: 'listRecordings',
      onSkip: _reporter.parseSkipSink(context: 'listRecordings'),
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
    String serverId,
    UpdateRecordingRequest request,
  ) async {
    final response = await _client.patch(
      '/api/oc/recordings/$serverId',
      body: request.toJson(),
    );
    guardResponse(response);
    if (response.statusCode == 403) {
      throw const ForbiddenException();
    }
    // The backend deduplicates on (project_id, title). A rename onto a taken
    // title must stay distinguishable: callers save locally on a plain `false`,
    // which would leave the device disagreeing with the server. (ENG-71)
    if (response.statusCode == 409) {
      throwForResponse(response);
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
