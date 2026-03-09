import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/env.dart';
import '../../../recording/data/repositories/local_recording_repository.dart';
import 'connectivity_service.dart';

/// Background sync engine that processes the upload queue sequentially.
///
/// Flow per recording:
/// 1. Get pending recordings from LocalRecordingRepository
/// 2. Mark as uploading
/// 3. POST /api/oc/recordings/upload-url to get signed URL
/// 4. PUT file to signed URL
/// 5. POST confirm-upload
/// 6. Mark as uploaded
/// 7. Optionally delete local file
class SyncEngine {
  final LocalRecordingRepository _recordingRepo;
  final ConnectivityService _connectivity;
  final http.Client _client;
  final FlutterSecureStorage _storage;

  /// Max number of retries per recording before giving up.
  static const int maxRetries = 5;

  /// Backoff durations for retries: 5s, 15s, 30s, 60s (then 60s for any beyond).
  static const List<Duration> _backoffDurations = [
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(seconds: 60),
  ];

  bool _isProcessing = false;

  SyncEngine({
    required LocalRecordingRepository recordingRepo,
    required ConnectivityService connectivity,
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _recordingRepo = recordingRepo,
        _connectivity = connectivity,
        _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  String get _baseUrl => Env.backendUrl;

  /// Whether the engine is currently processing the queue.
  bool get isProcessing => _isProcessing;

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: 'access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Process all pending uploads sequentially.
  ///
  /// Skips recordings that have exceeded [maxRetries].
  /// Processes one at a time to avoid battery drain.
  Future<void> processQueue({bool deleteAfterUpload = false}) async {
    if (_isProcessing) return;

    final online = await _connectivity.isOnline;
    if (!online) return;

    _isProcessing = true;
    try {
      final pending = await _recordingRepo.getPendingUploads();

      for (final recording in pending) {
        // Skip if max retries exceeded.
        if (recording.retryCount >= maxRetries) continue;

        // Check connectivity before each upload.
        final stillOnline = await _connectivity.isOnline;
        if (!stillOnline) break;

        // Apply exponential backoff if this is a retry.
        if (recording.retryCount > 0 && recording.lastRetryAt != null) {
          final backoffIndex = (recording.retryCount - 1)
              .clamp(0, _backoffDurations.length - 1);
          final backoff = _backoffDurations[backoffIndex];
          final elapsed = DateTime.now().difference(recording.lastRetryAt!);
          if (elapsed < backoff) continue;
        }

        await _uploadRecording(recording.id, recording.localFilePath,
            deleteAfterUpload: deleteAfterUpload);
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Upload a single recording through the signed-URL flow.
  Future<void> _uploadRecording(
    String id,
    String localFilePath, {
    bool deleteAfterUpload = false,
  }) async {
    try {
      // Step 1: Mark as uploading.
      await _recordingRepo.markAsUploading(id);

      // Step 2: Request a signed upload URL from the backend.
      final uploadUrlResponse = await _client.post(
        Uri.parse('$_baseUrl/api/oc/recordings/upload-url'),
        headers: await _authHeaders(),
        body: jsonEncode({'recording_id': id}),
      );

      if (uploadUrlResponse.statusCode != 200) {
        throw Exception(
            'Failed to get upload URL: ${uploadUrlResponse.body}');
      }

      final uploadData =
          jsonDecode(uploadUrlResponse.body) as Map<String, dynamic>;
      final signedUrl = uploadData['upload_url'] as String;
      final serverId = uploadData['server_id'] as String;

      // Step 3: PUT the file to the signed URL.
      final file = File(localFilePath);
      final fileBytes = await file.readAsBytes();

      final putResponse = await _client.put(
        Uri.parse(signedUrl),
        headers: {'Content-Type': 'audio/mp4'},
        body: fileBytes,
      );

      if (putResponse.statusCode != 200) {
        throw Exception('Failed to upload file: ${putResponse.statusCode}');
      }

      // Step 4: Confirm the upload with the backend.
      final confirmResponse = await _client.post(
        Uri.parse('$_baseUrl/api/oc/recordings/confirm-upload'),
        headers: await _authHeaders(),
        body: jsonEncode({'recording_id': id, 'server_id': serverId}),
      );

      if (confirmResponse.statusCode != 200) {
        throw Exception(
            'Failed to confirm upload: ${confirmResponse.body}');
      }

      final confirmData =
          jsonDecode(confirmResponse.body) as Map<String, dynamic>;
      final gcsUrl = confirmData['gcs_url'] as String;

      // Step 5: Mark as uploaded in local DB.
      await _recordingRepo.markAsUploaded(id, serverId, gcsUrl);

      // Step 6: Optionally delete the local file.
      if (deleteAfterUpload && await file.exists()) {
        await file.delete();
      }
    } on Exception {
      // Mark as failed and increment retry count.
      await _recordingRepo.markAsFailed(id);
    }
  }
}
