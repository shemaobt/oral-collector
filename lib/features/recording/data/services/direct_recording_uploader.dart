import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:http/http.dart' as http;

import '../../../../core/database/app_database.dart';
import '../../../../core/network/authenticated_client.dart';
import '../../../../core/platform/file_source.dart';
import '../../../../core/util/crc32c.dart';
import '../../../sync/data/services/resumable_upload_service.dart';
import '../repositories/local_recording_repository.dart';

const int _smallFileThreshold = 5 * 1024 * 1024;

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
  DirectRecordingUploader({
    required AuthenticatedClient client,
    required ResumableUploadService resumableUploadService,
    required LocalRecordingRepository recordingRepo,
  }) : _client = client,
       _resumableUploadService = resumableUploadService,
       _recordingRepo = recordingRepo;

  final AuthenticatedClient _client;
  final ResumableUploadService _resumableUploadService;
  final LocalRecordingRepository _recordingRepo;

  static const Duration _apiTimeout = Duration(seconds: 30);

  Future<String> upload({
    required FileSource source,
    required DirectUploadMetadata meta,
    void Function(int sent, int total)? onProgress,
  }) async {
    final serverId = await _createMetadata(meta);

    if (source.length < _smallFileThreshold) {
      await _uploadSingleShot(serverId: serverId, source: source, meta: meta);
    } else {
      await _uploadResumable(
        serverId: serverId,
        source: source,
        meta: meta,
        onProgress: onProgress,
      );
    }

    return serverId;
  }

  Future<String> _createMetadata(DirectUploadMetadata meta) async {
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
    return createData['id'] as String;
  }

  Future<void> _uploadSingleShot({
    required String serverId,
    required FileSource source,
    required DirectUploadMetadata meta,
  }) async {
    final bytes = await source.readRange(0, source.length);
    final clientCrc = (Crc32c()..add(bytes)).base64BigEndian;

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

    final gcsCrc = parseGcsCrc32cHeader(putStreamed.headers);
    if (gcsCrc != null && gcsCrc != clientCrc) {
      throw _UploaderException(
        'CRC32C mismatch (client=$clientCrc, gcs=$gcsCrc)',
      );
    }

    await _confirm(serverId, crc32c: clientCrc);
  }

  Future<void> _uploadResumable({
    required String serverId,
    required FileSource source,
    required DirectUploadMetadata meta,
    void Function(int sent, int total)? onProgress,
  }) async {
    final shadowId = 'web_$serverId';
    final synthPath =
        source.filePath ??
        'web_import_${DateTime.now().millisecondsSinceEpoch}_$serverId';

    await _recordingRepo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(shadowId),
        projectId: Value(meta.projectId),
        genreId: Value(meta.genreId),
        subcategoryId: meta.subcategoryId.isNotEmpty
            ? Value(meta.subcategoryId)
            : const Value.absent(),
        registerId: meta.registerId != null && meta.registerId!.isNotEmpty
            ? Value(meta.registerId)
            : const Value.absent(),
        storytellerId:
            meta.storytellerId != null && meta.storytellerId!.isNotEmpty
            ? Value(meta.storytellerId)
            : const Value.absent(),
        userId: meta.userId != null ? Value(meta.userId) : const Value.absent(),
        title: meta.title != null ? Value(meta.title) : const Value.absent(),
        description: meta.description != null
            ? Value(meta.description)
            : const Value.absent(),
        durationSeconds: Value(meta.durationSeconds),
        fileSizeBytes: Value(meta.fileSizeBytes),
        format: Value(meta.format),
        localFilePath: Value(synthPath),
        serverId: Value(serverId),
        uploadStatus: const Value('web_uploading'),
        recordedAt: Value(meta.recordedAt),
      ),
    );

    try {
      final result = await _resumableUploadService.uploadFromSource(
        recordingId: shadowId,
        serverId: serverId,
        source: source,
        format: meta.format,
        onProgress: onProgress,
      );
      if (!result.success) {
        throw _UploaderException(
          'Resumable upload failed: ${result.error ?? 'unknown'}',
        );
      }

      await _confirm(serverId, crc32c: result.clientCrc32c);
      await _recordingRepo.deleteRecording(shadowId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _confirm(String serverId, {required String? crc32c}) async {
    final confirmBody = <String, dynamic>{};
    if (crc32c != null) confirmBody['crc32c'] = crc32c;

    final confirmResponse = await _client
        .post('/api/oc/recordings/$serverId/confirm-upload', body: confirmBody)
        .timeout(_apiTimeout);
    if (confirmResponse.statusCode != 200) {
      throw _UploaderException(
        'Confirm failed (${confirmResponse.statusCode}): ${confirmResponse.body}',
      );
    }
  }
}

class _UploaderException implements Exception {
  _UploaderException(this.message);
  final String message;
  @override
  String toString() => message;
}
