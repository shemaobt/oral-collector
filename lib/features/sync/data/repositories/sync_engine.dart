import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
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
import '../services/resumable_upload_service.dart';

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
  late final ResumableUploadService _uploadService;

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
       _client = client {
    _uploadService = ResumableUploadService(
      client: _client,
      recordingRepo: _recordingRepo,
    );
  }

  @override
  bool get isProcessing => _isProcessing;

  @override
  Future<void> processQueue({
    bool deleteAfterUpload = false,
    bool wifiOnly = false,
    int maxConcurrency = 1,
    void Function(String recordingId, int bytesSent, int totalBytes)?
    onProgress,
  }) async {
    if (_isProcessing) return;

    final online = await _connectivity.isOnline;
    if (!online) return;

    if (wifiOnly) {
      final onWifi = await _connectivity.isOnWifi;
      if (!onWifi) return;
    }

    _isProcessing = true;
    try {
      final pending = await _recordingRepo.getPendingUploads();

      final eligible = <LocalRecording>[];
      for (final recording in pending) {
        if (recording.retryCount >= maxRetries) continue;

        if (recording.retryCount > 0 && recording.lastRetryAt != null) {
          final backoffIndex = (recording.retryCount - 1).clamp(
            0,
            _backoffDurations.length - 1,
          );
          final backoff = _backoffDurations[backoffIndex];
          final elapsed = DateTime.now().difference(recording.lastRetryAt!);
          if (elapsed < backoff) continue;
        }

        eligible.add(recording);
      }

      if (maxConcurrency <= 1) {
        for (final recording in eligible) {
          final stillOnline = await _connectivity.isOnline;
          if (!stillOnline) break;

          if (wifiOnly) {
            final stillWifi = await _connectivity.isOnWifi;
            if (!stillWifi) break;
          }

          await _uploadRecording(
            recording.id,
            recording.localFilePath,
            deleteAfterUpload: deleteAfterUpload,
            onProgress: onProgress,
          );
        }
      } else {
        var index = 0;
        final active = <Future<void>>[];

        while (index < eligible.length || active.isNotEmpty) {
          while (index < eligible.length && active.length < maxConcurrency) {
            final stillOnline = await _connectivity.isOnline;
            if (!stillOnline) break;

            if (wifiOnly) {
              final stillWifi = await _connectivity.isOnWifi;
              if (!stillWifi) break;
            }

            final recording = eligible[index++];
            late final Future<void> entry;
            entry = _uploadRecording(
              recording.id,
              recording.localFilePath,
              deleteAfterUpload: deleteAfterUpload,
              onProgress: onProgress,
            ).whenComplete(() => active.remove(entry));
            active.add(entry);
          }

          if (active.isNotEmpty) {
            await Future.any(active);
          } else {
            break;
          }
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Future<void> uploadSingle(
    String recordingId, {
    bool deleteAfterUpload = false,
    void Function(String recordingId, int bytesSent, int totalBytes)?
    onProgress,
  }) async {
    final recording = await _recordingRepo.getRecordingById(recordingId);
    if (recording == null) return;

    final online = await _connectivity.isOnline;
    if (!online) return;

    await _uploadRecording(
      recording.id,
      recording.localFilePath,
      deleteAfterUpload: deleteAfterUpload,
      onProgress: onProgress,
    );
  }

  Future<String?> _resolveFilePath(String storedPath) async {
    if (kIsWeb) return storedPath;

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
    void Function(String recordingId, int bytesSent, int totalBytes)?
    onProgress,
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

      String? md5Hash = recording.md5Hash;
      if (md5Hash == null || md5Hash.isEmpty) {
        final fileBytes = await file_ops.readFileBytes(resolvedPath);
        md5Hash = crypto.md5.convert(fileBytes).toString();
        await _recordingRepo.updateRecording(
          id,
          LocalRecordingsCompanion(md5Hash: Value(md5Hash)),
        );
      }

      final uploadResult = await _uploadService.upload(
        recordingId: id,
        serverId: serverId,
        localFilePath: resolvedPath,
        format: recording.format,
        fileSizeBytes: recording.fileSizeBytes,
        onProgress: onProgress != null
            ? (sent, total) => onProgress(id, sent, total)
            : null,
      );

      if (!uploadResult.success) {
        throw Exception('Upload failed: ${uploadResult.error}');
      }

      final confirmResponse = await _client
          .post(
            '/api/oc/recordings/$serverId/confirm-upload',
            body: {'md5_hash': md5Hash},
          )
          .timeout(_apiTimeout);

      _checkResponse(
        confirmResponse.statusCode,
        confirmResponse.body,
        'Confirm',
        expected: 200,
      );

      final verifiedData = await _pollForVerification(serverId);

      if (verifiedData == null) {
        throw Exception('Verification polling timed out');
      }

      final gcsUrl = verifiedData['gcs_url'] as String?;
      final serverStatus = verifiedData['upload_status'] as String?;

      if (serverStatus == 'upload_failed') {
        final error =
            verifiedData['upload_error'] as String? ?? 'Verification failed';
        throw Exception('Server verification failed: $error');
      }

      await _recordingRepo.markAsUploaded(id, serverId, gcsUrl);

      if (deleteAfterUpload && !kIsWeb && serverStatus == 'verified') {
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

  static const int _verificationMaxAttempts = 15;
  static const Duration _verificationInterval = Duration(seconds: 2);

  Future<Map<String, dynamic>?> _pollForVerification(String serverId) async {
    for (var i = 0; i < _verificationMaxAttempts; i++) {
      await Future<void>.delayed(_verificationInterval);

      try {
        final response = await _client
            .get('/api/oc/recordings/$serverId')
            .timeout(_apiTimeout);

        if (response.statusCode != 200) continue;

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = data['upload_status'] as String?;

        if (status == 'verified' || status == 'upload_failed') {
          return data;
        }
      } on Exception {
        continue;
      }
    }

    return null;
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
