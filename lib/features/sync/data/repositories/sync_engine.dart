import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_exception.dart' show AppException;
import '../../../../core/network/authenticated_client.dart';
import '../../../../core/network/response_decoder.dart';
import '../../../../core/platform/file_ops.dart' as file_ops;
import '../../../../core/serialization/safe_read.dart';
import '../../../recording/data/repositories/local_recording_repository.dart';
import '../../../storyteller/data/repositories/local_storyteller_repository.dart';
import '../../domain/repositories/connectivity_service.dart';
import '../../domain/repositories/sync_engine.dart';
import '../services/resumable_upload_service.dart';
import '../services/upload_downloader.dart';

class SyncEngineImpl implements SyncEngine {
  final LocalRecordingRepository _recordingRepo;
  final LocalStorytellerRepository _storytellerRepo;
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
    required LocalStorytellerRepository storytellerRepo,
    required ConnectivityService connectivity,
    required AuthenticatedClient client,
    UploadDownloader? uploadDownloader,
  }) : _recordingRepo = recordingRepo,
       _storytellerRepo = storytellerRepo,
       _connectivity = connectivity,
       _client = client {
    _uploadService = ResumableUploadService(
      client: _client,
      recordingRepo: _recordingRepo,
      downloader: uploadDownloader,
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
    // Set the guard before any await so two rapid callers can't both pass the
    // check while one is mid-connectivity-probe. The previous ordering left a
    // window where a second processQueue() entered before the first set the
    // flag, doubling the work and racing the coordinator's resume.
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      final online = await _connectivity.isOnline;
      if (!online) return;

      if (wifiOnly) {
        final onWifi = await _connectivity.isOnWifi;
        if (!onWifi) return;
      }

      await _processPendingStorytellers();

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
        final subcategoryId =
            (recording.subcategoryId != null &&
                recording.subcategoryId!.isNotEmpty)
            ? recording.subcategoryId
            : 'unclassified';
        final createBody = <String, dynamic>{
          'project_id': recording.projectId,
          'genre_id': recording.genreId,
          'subcategory_id': subcategoryId,
          'title': recording.title,
          'description': recording.description,
          'duration_seconds': recording.durationSeconds,
          'file_size_bytes': recording.fileSizeBytes,
          'format': recording.format,
          'recorded_at': recording.recordedAt.toUtc().toIso8601String(),
        };
        if (recording.registerId != null && recording.registerId!.isNotEmpty) {
          createBody['register_id'] = recording.registerId;
        }
        if (recording.secondaryGenreId != null &&
            recording.secondaryGenreId!.isNotEmpty) {
          createBody['secondary_genre_id'] = recording.secondaryGenreId;
        }
        if (recording.secondarySubcategoryId != null &&
            recording.secondarySubcategoryId!.isNotEmpty) {
          createBody['secondary_subcategory_id'] =
              recording.secondarySubcategoryId;
        }
        if (recording.secondaryRegisterId != null &&
            recording.secondaryRegisterId!.isNotEmpty) {
          createBody['secondary_register_id'] = recording.secondaryRegisterId;
        }
        if (recording.storytellerId != null &&
            recording.storytellerId!.isNotEmpty) {
          final resolvedStorytellerId = await _resolveStorytellerServerId(
            recording.storytellerId!,
          );
          if (resolvedStorytellerId == null) {
            debugPrint(
              'SyncEngine: skipping recording $id, '
              'referenced storyteller ${recording.storytellerId} is not yet synced',
            );
            return;
          }
          createBody['storyteller_id'] = resolvedStorytellerId;
        }
        final createResponse = await _client
            .post('/api/oc/recordings', body: createBody)
            .timeout(_apiTimeout);

        final createData = decodeObject(createResponse);
        serverId = readString(createData, 'id');

        await _recordingRepo.updateRecording(
          id,
          LocalRecordingsCompanion(serverId: Value(serverId)),
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

      if (uploadResult.pausedByRecording) {
        await _recordingRepo.updateRecording(
          id,
          const LocalRecordingsCompanion(uploadStatus: Value('local')),
        );
        return;
      }

      if (!uploadResult.success) {
        throw Exception('Upload failed: ${uploadResult.error}');
      }

      final confirmBody = <String, dynamic>{};
      if (uploadResult.clientCrc32c != null) {
        confirmBody['crc32c'] = uploadResult.clientCrc32c;
      }

      final confirmResponse = await _client
          .post(
            '/api/oc/recordings/$serverId/confirm-upload',
            body: confirmBody,
          )
          .timeout(_apiTimeout);

      final confirmData = decodeObject(confirmResponse);
      final gcsUrl = readStringOrNull(confirmData, 'gcs_url');

      await _recordingRepo.markAsUploaded(id, serverId, gcsUrl);

      if (deleteAfterUpload && !kIsWeb) {
        await file_ops.deleteFile(resolvedPath);
      }
    } on AppException catch (e, st) {
      // Retry decision by the typed flag (ENG-103), not by exception subtype.
      if (e.retryable) {
        debugPrint('SyncEngine: retryable upload failure for $id: $e');
        await _recordingRepo.markAsFailed(id);
      } else {
        debugPrint('SyncEngine: permanent upload failure for $id: $e\n$st');
        await _markPermanentlyFailed(id);
      }
    } on FormatException catch (e, st) {
      // Server returned a non-JSON body. Retrying won't help; mark terminal.
      debugPrint('SyncEngine: response parse error for $id: $e\n$st');
      await _markPermanentlyFailed(id);
    } on Exception catch (e, st) {
      // Transport faults (socket/timeout/filesystem) and other transient
      // Exception subtypes → retry. Programmer errors (Error subtypes like
      // TypeError, StateError) are NOT caught here — they propagate as bugs.
      debugPrint('SyncEngine: unexpected error uploading $id: $e\n$st');
      await _recordingRepo.markAsFailed(id);
    }
  }

  Future<void> _processPendingStorytellers() async {
    final pending = await _storytellerRepo.getPendingSyncs();
    for (final row in pending) {
      if (row.retryCount > 0 && row.lastRetryAt != null) {
        final backoffIndex = (row.retryCount - 1).clamp(
          0,
          _backoffDurations.length - 1,
        );
        final backoff = _backoffDurations[backoffIndex];
        final elapsed = DateTime.now().difference(row.lastRetryAt!);
        if (elapsed < backoff) continue;
      }

      final stillOnline = await _connectivity.isOnline;
      if (!stillOnline) return;

      try {
        await _storytellerRepo.markUploading(row.id);

        final body = <String, dynamic>{
          'name': row.name,
          'sex': row.sex,
          'external_acceptance_confirmed': row.externalAcceptanceConfirmed,
          if (row.age != null) 'age': row.age,
          if (row.location != null && row.location!.isNotEmpty)
            'location': row.location,
          if (row.dialect != null && row.dialect!.isNotEmpty)
            'dialect': row.dialect,
        };

        final response = await _client
            .post('/api/oc/projects/${row.projectId}/storytellers', body: body)
            .timeout(_apiTimeout);

        if (response.statusCode != 201 && response.statusCode != 200) {
          debugPrint(
            'SyncEngine: storyteller ${row.id} failed '
            'with ${response.statusCode}: ${response.body}',
          );
          await _storytellerRepo.markFailed(row.id);
          continue;
        }

        final data = decodeObject(response);
        final serverId = readString(data, 'id');
        await _storytellerRepo.markUploaded(row.id, serverId);
        await _recordingRepo.reassignStorytellerId(
          fromId: row.id,
          toId: serverId,
        );
      } on TimeoutException catch (e) {
        debugPrint('SyncEngine: timeout syncing storyteller ${row.id}: $e');
        await _storytellerRepo.markFailed(row.id);
      } on SocketException catch (e) {
        debugPrint(
          'SyncEngine: socket error syncing storyteller ${row.id}: $e',
        );
        await _storytellerRepo.markFailed(row.id);
      } on Exception catch (e) {
        debugPrint('SyncEngine: error syncing storyteller ${row.id}: $e');
        await _storytellerRepo.markFailed(row.id);
      }
    }
  }

  Future<String?> _resolveStorytellerServerId(String referencedId) async {
    final row = await _storytellerRepo.getRowById(referencedId);
    if (row == null) {
      return referencedId;
    }
    if (row.serverId != null && row.serverId!.isNotEmpty) {
      return row.serverId;
    }
    if (row.syncStatus == 'synced') {
      return row.id;
    }
    return null;
  }

  Future<void> _markPermanentlyFailed(String id) async {
    await _recordingRepo.updateRecording(
      id,
      LocalRecordingsCompanion(
        uploadStatus: const Value('failed'),
        retryCount: const Value(maxRetries),
        lastRetryAt: Value(DateTime.now()),
      ),
    );
  }
}
