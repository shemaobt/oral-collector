import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;

import '../../../../core/network/authenticated_client.dart';

class DirectUploadMetadata {
  const DirectUploadMetadata({
    required this.projectId,
    required this.genreId,
    required this.subcategoryId,
    this.registerId,
    this.storytellerId,
    this.userId,
    this.title,
    this.description,
    required this.durationSeconds,
    required this.fileSizeBytes,
    required this.format,
    required this.recordedAt,
  });

  final String projectId;
  final String genreId;
  final String subcategoryId;
  final String? registerId;
  final String? storytellerId;
  final String? userId;
  final String? title;
  final String? description;
  final double durationSeconds;
  final int fileSizeBytes;
  final String format;
  final DateTime recordedAt;
}

class DirectRecordingUploader {
  DirectRecordingUploader(this._client);
  final AuthenticatedClient _client;

  static const Duration _apiTimeout = Duration(seconds: 30);

  Future<String> upload({
    required Uint8List bytes,
    required DirectUploadMetadata meta,
  }) async {
    final createBody = <String, dynamic>{
      'project_id': meta.projectId,
      'genre_id': meta.genreId,
      'subcategory_id': meta.subcategoryId,
      'title': meta.title,
      'description': meta.description,
      'duration_seconds': meta.durationSeconds,
      'file_size_bytes': meta.fileSizeBytes,
      'format': meta.format,
      'recorded_at': meta.recordedAt.toUtc().toIso8601String(),
    };
    if (meta.registerId != null && meta.registerId!.isNotEmpty) {
      createBody['register_id'] = meta.registerId;
    }
    if (meta.storytellerId != null && meta.storytellerId!.isNotEmpty) {
      createBody['storyteller_id'] = meta.storytellerId;
    }

    final createResponse = await _client
        .post('/api/oc/recordings', body: createBody)
        .timeout(_apiTimeout);
    if (createResponse.statusCode != 201) {
      throw _UploaderException(
        'Create failed (${createResponse.statusCode}): ${createResponse.body}',
      );
    }
    final createData = jsonDecode(createResponse.body) as Map<String, dynamic>;
    final serverId = createData['id'] as String;

    final urlResponse = await _client
        .post(
          '/api/oc/recordings/upload-url',
          body: {'recording_id': serverId, 'format': meta.format},
        )
        .timeout(_apiTimeout);
    if (urlResponse.statusCode != 200) {
      throw _UploaderException(
        'Upload URL failed (${urlResponse.statusCode}): ${urlResponse.body}',
      );
    }
    final urlData = jsonDecode(urlResponse.body) as Map<String, dynamic>;
    final uploadUrl = urlData['upload_url'] as String;
    final contentType =
        urlData['content_type'] as String? ?? 'application/octet-stream';

    final putRequest = http.Request('PUT', Uri.parse(uploadUrl));
    putRequest.headers['Content-Type'] = contentType;
    putRequest.bodyBytes = bytes;
    final uploadTimeout = Duration(
      seconds: 120 + (bytes.length ~/ (10 * 1024 * 1024)) * 60,
    );
    final putStreamed = await _client.rawClient
        .send(putRequest)
        .timeout(uploadTimeout);
    final putBody = await putStreamed.stream.bytesToString();
    if (putStreamed.statusCode != 200) {
      throw _UploaderException(
        'GCS PUT failed (${putStreamed.statusCode}): $putBody',
      );
    }

    final md5Hash = crypto.md5.convert(bytes).toString();
    final confirmResponse = await _client
        .post(
          '/api/oc/recordings/$serverId/confirm-upload',
          body: {'md5_hash': md5Hash},
        )
        .timeout(_apiTimeout);
    if (confirmResponse.statusCode != 200) {
      throw _UploaderException(
        'Confirm failed (${confirmResponse.statusCode}): ${confirmResponse.body}',
      );
    }

    return serverId;
  }
}

class _UploaderException implements Exception {
  _UploaderException(this.message);
  final String message;
  @override
  String toString() => message;
}
