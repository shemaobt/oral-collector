import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/network/authenticated_client.dart';
import '../../../../core/platform/file_ops.dart' as file_ops;
import '../../../recording/data/repositories/local_recording_repository.dart';
import '../../domain/repositories/connectivity_service.dart';
import '../../domain/repositories/sync_engine.dart';

class _NonRetryableUploadException implements Exception {
  final String message;
  _NonRetryableUploadException(this.message);
  @override
  String toString() => message;
}

class SyncEngineImpl implements SyncEngine {
  final LocalRecordingRepository _recordingRepo;
  final ConnectivityService _connectivity;
  final AuthenticatedClient _client;

  static const int maxRetries = 5;
  static const Duration _apiTimeout = Duration(seconds: 30);

  static const List<Duration> _backoffDurations = [
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(seconds: 60),
  ];

  bool _isProcessing = false;

  SyncEngineImpl({
    required LocalRecordingRepository recordingRepo,
    required ConnectivityService connectivity,
    required AuthenticatedClient client,
  }) : _recordingRepo = recordingRepo,
       _connectivity = connectivity,
       _client = client;

  @override
  bool get isProcessing => _isProcessing;

  static String _contentTypeForFormat(String format) {
    const mapping = {
      'm4a': 'audio/mp4',
      'aac': 'audio/aac',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'webm': 'audio/webm',
    };
    return mapping[format.toLowerCase()] ?? 'application/octet-stream';
  }

  @override
  Future<void> processQueue({
    bool deleteAfterUpload = false,
    void Function(int bytesSent, int totalBytes)? onProgress,
  }) async {
    if (_isProcessing) return;
    if (kIsWeb) return;

    final online = await _connectivity.isOnline;
    if (!online) return;

    _isProcessing = true;
    try {
      final pending = await _recordingRepo.getPendingUploads();

      for (final recording in pending) {
        if (recording.retryCount >= maxRetries) continue;

        final stillOnline = await _connectivity.isOnline;
        if (!stillOnline) break;

        if (recording.retryCount > 0 && recording.lastRetryAt != null) {
          final backoffIndex = (recording.retryCount - 1).clamp(
            0,
            _backoffDurations.length - 1,
          );
          final backoff = _backoffDurations[backoffIndex];
          final elapsed = DateTime.now().difference(recording.lastRetryAt!);
          if (elapsed < backoff) continue;
        }

        await _uploadRecording(
          recording.id,
          recording.localFilePath,
          deleteAfterUpload: deleteAfterUpload,
          onProgress: onProgress,
        );
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<String?> _resolveFilePath(String storedPath) async {
    if (await file_ops.fileExists(storedPath)) return storedPath;

    final docsDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(storedPath);

    final resolved = '${docsDir.path}/$fileName';
    if (await file_ops.fileExists(resolved)) return resolved;

    final inSubdir = '${docsDir.path}/recordings/$fileName';
    if (await file_ops.fileExists(inSubdir)) return inSubdir;

    return null;
  }

  Future<void> _uploadRecording(
    String id,
    String localFilePath, {
    bool deleteAfterUpload = false,
    void Function(int bytesSent, int totalBytes)? onProgress,
  }) async {
    try {
      final resolvedPath = await _resolveFilePath(localFilePath);
      if (resolvedPath == null) {
        await _recordingRepo.markAsFailed(id, incrementRetry: false);
        return;
      }
      if (resolvedPath != localFilePath) {
        await _recordingRepo.updateRecording(
          id,
          LocalRecordingsCompanion(localFilePath: Value(resolvedPath)),
        );
      }

      final recording = await _recordingRepo.getRecordingById(id);
      if (recording == null) return;

      await _recordingRepo.markAsUploading(id);

      String serverId;

      if (recording.serverId != null && recording.serverId!.isNotEmpty) {
        serverId = recording.serverId!;
      } else {
        final createBody = <String, dynamic>{
          'project_id': recording.projectId,
          'genre_id': recording.genreId,
          'subcategory_id': recording.subcategoryId,
          'title': recording.title,
          'duration_seconds': recording.durationSeconds,
          'file_size_bytes': recording.fileSizeBytes,
          'format': recording.format,
          'recorded_at': recording.recordedAt.toUtc().toIso8601String(),
        };
        if (recording.registerId != null && recording.registerId!.isNotEmpty) {
          createBody['register_id'] = recording.registerId;
        }
        final createResponse = await _client
            .post('/api/oc/recordings', body: createBody)
            .timeout(_apiTimeout);

        _checkResponse(
          createResponse.statusCode,
          createResponse.body,
          'Create',
          expected: 201,
        );

        final createData =
            jsonDecode(createResponse.body) as Map<String, dynamic>;
        serverId = createData['id'] as String;

        await _recordingRepo.updateRecording(
          id,
          LocalRecordingsCompanion(serverId: Value(serverId)),
        );
      }

      final uploadUrlResponse = await _client
          .post(
            '/api/oc/recordings/upload-url',
            body: {'recording_id': serverId, 'format': recording.format},
          )
          .timeout(_apiTimeout);

      _checkResponse(
        uploadUrlResponse.statusCode,
        uploadUrlResponse.body,
        'Upload URL',
        expected: 200,
      );

      final uploadData =
          jsonDecode(uploadUrlResponse.body) as Map<String, dynamic>;
      final uploadUrl = uploadData['upload_url'] as String;
      final contentType =
          uploadData['content_type'] as String? ??
          _contentTypeForFormat(recording.format);

      // Streamed upload to avoid loading entire file into memory
      final file = File(resolvedPath);
      final fileLength = await file.length();

      final request = http.StreamedRequest('PUT', Uri.parse(uploadUrl));
      request.headers['Content-Type'] = contentType;
      request.contentLength = fileLength;

      var bytesSent = 0;
      file.openRead().listen(
        (chunk) {
          request.sink.add(chunk);
          bytesSent += chunk.length;
          onProgress?.call(bytesSent, fileLength);
        },
        onDone: () => request.sink.close(),
        onError: (e) => request.sink.addError(e),
      );

      // Dynamic timeout: 120s base + 60s per 10MB
      final uploadTimeout = Duration(
        seconds: 120 + (fileLength ~/ (10 * 1024 * 1024)) * 60,
      );

      final streamedResponse = await _client.rawClient
          .send(request)
          .timeout(uploadTimeout);

      final responseBody = await streamedResponse.stream.bytesToString();
      if (streamedResponse.statusCode != 200) {
        _checkResponse(streamedResponse.statusCode, responseBody, 'GCS PUT');
      }

      final confirmResponse = await _client
          .post('/api/oc/recordings/$serverId/confirm-upload')
          .timeout(_apiTimeout);

      _checkResponse(
        confirmResponse.statusCode,
        confirmResponse.body,
        'Confirm',
        expected: 200,
      );

      final confirmData =
          jsonDecode(confirmResponse.body) as Map<String, dynamic>;
      final gcsUrl = confirmData['gcs_url'] as String?;

      await _recordingRepo.markAsUploaded(id, serverId, gcsUrl);

      if (deleteAfterUpload) {
        await file_ops.deleteFile(resolvedPath);
      }
    } on _NonRetryableUploadException {
      await _recordingRepo.updateRecording(
        id,
        LocalRecordingsCompanion(
          uploadStatus: const Value('failed'),
          retryCount: const Value(maxRetries),
          lastRetryAt: Value(DateTime.now()),
        ),
      );
    } on TimeoutException {
      await _recordingRepo.markAsFailed(id);
    } on SocketException {
      await _recordingRepo.markAsFailed(id);
    } on Exception {
      await _recordingRepo.markAsFailed(id);
    }
  }

  void _checkResponse(
    int statusCode,
    String body,
    String operation, {
    int? expected,
  }) {
    if (expected != null && statusCode == expected) return;
    if (expected == null && statusCode >= 200 && statusCode < 300) return;

    if (statusCode == 401 || statusCode == 403) {
      throw _NonRetryableUploadException(
        '$operation: auth error ($statusCode): $body',
      );
    }
    if (statusCode >= 400 && statusCode < 500) {
      throw _NonRetryableUploadException(
        '$operation: client error ($statusCode): $body',
      );
    }
    throw Exception('$operation failed ($statusCode): $body');
  }
}
