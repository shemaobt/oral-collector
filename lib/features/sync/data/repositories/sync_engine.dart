import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/network/authenticated_client.dart';
import '../../../../core/platform/file_ops.dart' as file_ops;
import '../../../recording/data/repositories/local_recording_repository.dart';
import '../../domain/repositories/connectivity_service.dart';
import '../../domain/repositories/sync_engine.dart';

class SyncEngineImpl implements SyncEngine {
  final LocalRecordingRepository _recordingRepo;
  final ConnectivityService _connectivity;
  final AuthenticatedClient _client;

  static const int maxRetries = 5;

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

  @override
  Future<void> processQueue({bool deleteAfterUpload = false}) async {
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
        final createResponse = await _client.post(
          '/api/oc/recordings',
          body: createBody,
        );

        if (createResponse.statusCode != 201) {
          throw Exception(
            'Create failed (${createResponse.statusCode}): ${createResponse.body}',
          );
        }

        final createData =
            jsonDecode(createResponse.body) as Map<String, dynamic>;
        serverId = createData['id'] as String;

        await _recordingRepo.updateRecording(
          id,
          LocalRecordingsCompanion(serverId: Value(serverId)),
        );
      }

      final uploadUrlResponse = await _client.post(
        '/api/oc/recordings/upload-url',
        body: {'recording_id': serverId, 'format': recording.format},
      );

      if (uploadUrlResponse.statusCode != 200) {
        throw Exception(
          'Upload URL failed (${uploadUrlResponse.statusCode}): ${uploadUrlResponse.body}',
        );
      }

      final uploadData =
          jsonDecode(uploadUrlResponse.body) as Map<String, dynamic>;
      final uploadUrl = uploadData['upload_url'] as String;

      final fileBytes = await file_ops.readFileBytes(resolvedPath);

      final putResponse = await _client.rawClient.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': 'audio/mp4'},
        body: fileBytes,
      );

      if (putResponse.statusCode != 200) {
        throw Exception(
          'GCS PUT failed (${putResponse.statusCode}): ${putResponse.body}',
        );
      }

      final confirmResponse = await _client.post(
        '/api/oc/recordings/$serverId/confirm-upload',
      );

      if (confirmResponse.statusCode != 200) {
        throw Exception(
          'Confirm failed (${confirmResponse.statusCode}): ${confirmResponse.body}',
        );
      }

      final confirmData =
          jsonDecode(confirmResponse.body) as Map<String, dynamic>;
      final gcsUrl = confirmData['gcs_url'] as String? ?? '';

      await _recordingRepo.markAsUploaded(id, serverId, gcsUrl);

      if (deleteAfterUpload) {
        await file_ops.deleteFile(resolvedPath);
      }
    } on Exception {
      await _recordingRepo.markAsFailed(id);
    }
  }
}
