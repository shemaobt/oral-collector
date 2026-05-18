import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:http/http.dart' as http;

import '../../../../core/database/app_database.dart';
import '../../../../core/network/authenticated_client.dart';
import '../../../../core/platform/file_source.dart';
import '../../../../core/platform/recording_active_flag.dart';
import '../../../recording/data/repositories/local_recording_repository.dart';
import 'upload_downloader.dart';

const int _smallFileThreshold = 5 * 1024 * 1024;
const int _defaultChunkSize = 8 * 1024 * 1024;

const String pausedByRecordingError = 'paused_by_recording';

class ResumableUploadResult {
  final bool success;
  final String? error;

  const ResumableUploadResult({required this.success, this.error});

  bool get pausedByRecording => error == pausedByRecordingError;
}

class ResumableUploadService {
  final AuthenticatedClient _client;
  final LocalRecordingRepository _recordingRepo;
  final UploadDownloader _downloader;
  final RecordingActiveFlag _recordingFlag;

  ResumableUploadService({
    required AuthenticatedClient client,
    required LocalRecordingRepository recordingRepo,
    UploadDownloader? downloader,
    RecordingActiveFlag? recordingFlag,
  }) : _client = client,
       _recordingRepo = recordingRepo,
       _downloader = downloader ?? const BackgroundDownloaderUploader(),
       _recordingFlag = recordingFlag ?? const RecordingActiveFlag();

  Future<ResumableUploadResult> upload({
    required String recordingId,
    required String serverId,
    required String localFilePath,
    required String format,
    required int fileSizeBytes,
    void Function(int bytesSent, int totalBytes)? onProgress,
  }) {
    return _uploadInternal(
      recordingId: recordingId,
      serverId: serverId,
      filePath: localFilePath,
      fileLength: fileSizeBytes,
      format: format,
      onProgress: onProgress,
    );
  }

  /// Legacy entry-point used by direct-uploader (file imports) and the web
  /// pending-uploads banner. These flows hand in a [FileSource] (possibly
  /// memory-backed on web) instead of a file path on disk, so they cannot use
  /// the `background_downloader` transport. Keeps the original chunked-HTTP
  /// loop intact.
  Future<ResumableUploadResult> uploadFromSource({
    required String recordingId,
    required String serverId,
    required FileSource source,
    required String format,
    void Function(int bytesSent, int totalBytes)? onProgress,
  }) async {
    try {
      if (source.length < _smallFileThreshold) {
        return _legacySinglePut(
          serverId: serverId,
          source: source,
          format: format,
          onProgress: onProgress,
        );
      }
      return await _legacyResumableHttp(
        recordingId: recordingId,
        serverId: serverId,
        source: source,
        format: format,
        onProgress: onProgress,
      );
    } finally {
      source.dispose();
    }
  }

  Future<ResumableUploadResult> _uploadInternal({
    required String recordingId,
    required String serverId,
    required String filePath,
    required int fileLength,
    required String format,
    void Function(int bytesSent, int totalBytes)? onProgress,
  }) async {
    if (await _recordingFlag.read()) {
      return const ResumableUploadResult(
        success: false,
        error: pausedByRecordingError,
      );
    }

    if (fileLength < _smallFileThreshold) {
      return _singlePutUpload(
        recordingId: recordingId,
        serverId: serverId,
        filePath: filePath,
        fileLength: fileLength,
        format: format,
        onProgress: onProgress,
      );
    }

    return _resumableUpload(
      recordingId: recordingId,
      serverId: serverId,
      filePath: filePath,
      fileLength: fileLength,
      format: format,
      onProgress: onProgress,
    );
  }

  Future<ResumableUploadResult> _singlePutUpload({
    required String recordingId,
    required String serverId,
    required String filePath,
    required int fileLength,
    required String format,
    void Function(int bytesSent, int totalBytes)? onProgress,
  }) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final uploadUrlResponse = await _client
          .post(
            '/api/oc/recordings/upload-url',
            body: {'recording_id': serverId, 'format': format},
          )
          .timeout(const Duration(seconds: 30));

      if (uploadUrlResponse.statusCode != 200) {
        return ResumableUploadResult(
          success: false,
          error: 'Upload URL failed (${uploadUrlResponse.statusCode})',
        );
      }

      final uploadData =
          jsonDecode(uploadUrlResponse.body) as Map<String, dynamic>;
      final uploadUrl = uploadData['upload_url'] as String;
      final contentType =
          uploadData['content_type'] as String? ?? 'application/octet-stream';

      final result = await _downloader.putChunk(
        taskId: 'single-$recordingId-$attempt',
        url: uploadUrl,
        filePath: filePath,
        offset: 0,
        end: fileLength,
        headers: {'Content-Type': contentType},
      );

      if (result.cancelled) {
        return const ResumableUploadResult(
          success: false,
          error: pausedByRecordingError,
        );
      }

      if (result.statusCode == 200 || result.statusCode == 201) {
        onProgress?.call(fileLength, fileLength);
        return const ResumableUploadResult(success: true);
      }

      final isExpired = result.statusCode == 403 || result.statusCode == 400;
      if (isExpired && attempt == 0) {
        continue;
      }

      return ResumableUploadResult(
        success: false,
        error:
            'GCS PUT failed (${result.statusCode}): ${result.responseBody ?? result.errorReason ?? ''}',
      );
    }

    return const ResumableUploadResult(
      success: false,
      error: 'Upload failed after URL refresh retry',
    );
  }

  Future<ResumableUploadResult> _resumableUpload({
    required String recordingId,
    required String serverId,
    required String filePath,
    required int fileLength,
    required String format,
    void Function(int bytesSent, int totalBytes)? onProgress,
  }) async {
    final recording = await _recordingRepo.getRecordingById(recordingId);
    if (recording == null) {
      return const ResumableUploadResult(
        success: false,
        error: 'Recording not found',
      );
    }

    String? sessionUri = recording.resumableSessionUri;
    int startOffset = recording.uploadedBytes;

    if (sessionUri != null && sessionUri.isNotEmpty) {
      final queryOffset = await _queryUploadOffset(sessionUri, fileLength);
      if (queryOffset == null) {
        sessionUri = null;
        startOffset = 0;
      } else if (queryOffset >= fileLength) {
        return const ResumableUploadResult(success: true);
      } else {
        startOffset = queryOffset;
      }
    }

    if (sessionUri == null || sessionUri.isEmpty) {
      final newSession = await _requestResumableSession(serverId, format);
      if (newSession == null) {
        return const ResumableUploadResult(
          success: false,
          error: 'Failed to create resumable upload session',
        );
      }
      sessionUri = newSession;
      startOffset = 0;

      await _recordingRepo.updateRecording(
        recordingId,
        LocalRecordingsCompanion(
          resumableSessionUri: Value(sessionUri),
          uploadedBytes: const Value(0),
        ),
      );
    }

    var offset = startOffset;

    if (offset > 0) {
      onProgress?.call(offset, fileLength);
    }

    var chunkIndex = 0;
    while (offset < fileLength) {
      if (await _recordingFlag.read()) {
        return const ResumableUploadResult(
          success: false,
          error: pausedByRecordingError,
        );
      }

      final end = (offset + _defaultChunkSize).clamp(0, fileLength);
      final contentRange = 'bytes $offset-${end - 1}/$fileLength';

      final result = await _downloader.putChunk(
        taskId: 'chunk-$recordingId-$chunkIndex',
        url: sessionUri!,
        filePath: filePath,
        offset: offset,
        end: end,
        headers: {'Content-Range': contentRange},
      );

      if (result.cancelled) {
        return const ResumableUploadResult(
          success: false,
          error: pausedByRecordingError,
        );
      }

      final chunkResult = _classifyChunkStatus(result.statusCode);

      if (chunkResult == _ChunkResult.success) {
        offset = end;
        onProgress?.call(offset, fileLength);

        await _recordingRepo.updateRecording(
          recordingId,
          LocalRecordingsCompanion(uploadedBytes: Value(offset)),
        );
      } else if (chunkResult == _ChunkResult.sessionExpired) {
        final newSession = await _requestResumableSession(serverId, format);
        if (newSession == null) {
          return const ResumableUploadResult(
            success: false,
            error: 'Failed to recreate resumable session after expiry',
          );
        }
        sessionUri = newSession;
        offset = 0;

        await _recordingRepo.updateRecording(
          recordingId,
          LocalRecordingsCompanion(
            resumableSessionUri: Value(sessionUri),
            uploadedBytes: const Value(0),
          ),
        );
      } else {
        return ResumableUploadResult(
          success: false,
          error:
              'Chunk upload failed (${result.statusCode}): ${result.errorReason ?? result.responseBody ?? ''}',
        );
      }
      chunkIndex++;
    }

    await _recordingRepo.updateRecording(
      recordingId,
      const LocalRecordingsCompanion(
        resumableSessionUri: Value(null),
        uploadedBytes: Value(0),
      ),
    );

    return const ResumableUploadResult(success: true);
  }

  _ChunkResult _classifyChunkStatus(int statusCode) {
    if (statusCode == 308 || statusCode == 200 || statusCode == 201) {
      return _ChunkResult.success;
    }
    if (statusCode == 410) {
      return _ChunkResult.sessionExpired;
    }
    return _ChunkResult.failed;
  }

  Future<ResumableUploadResult> _legacySinglePut({
    required String serverId,
    required FileSource source,
    required String format,
    void Function(int bytesSent, int totalBytes)? onProgress,
  }) async {
    final bytes = await source.readRange(0, source.length);
    final fileLength = bytes.length;

    for (var attempt = 0; attempt < 2; attempt++) {
      final uploadUrlResponse = await _client
          .post(
            '/api/oc/recordings/upload-url',
            body: {'recording_id': serverId, 'format': format},
          )
          .timeout(const Duration(seconds: 30));

      if (uploadUrlResponse.statusCode != 200) {
        return ResumableUploadResult(
          success: false,
          error: 'Upload URL failed (${uploadUrlResponse.statusCode})',
        );
      }

      final uploadData =
          jsonDecode(uploadUrlResponse.body) as Map<String, dynamic>;
      final uploadUrl = uploadData['upload_url'] as String;
      final contentType =
          uploadData['content_type'] as String? ?? 'application/octet-stream';

      final request = http.Request('PUT', Uri.parse(uploadUrl));
      request.headers['Content-Type'] = contentType;
      request.bodyBytes = bytes;

      final uploadTimeout = Duration(
        seconds: 120 + (fileLength ~/ (10 * 1024 * 1024)) * 60,
      );

      final streamedResponse = await _client.rawClient
          .send(request)
          .timeout(uploadTimeout);

      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        onProgress?.call(fileLength, fileLength);
        return const ResumableUploadResult(success: true);
      }

      final isExpired =
          streamedResponse.statusCode == 403 ||
          streamedResponse.statusCode == 400;
      if (isExpired && attempt == 0) {
        continue;
      }

      return ResumableUploadResult(
        success: false,
        error: 'GCS PUT failed (${streamedResponse.statusCode}): $responseBody',
      );
    }

    return const ResumableUploadResult(
      success: false,
      error: 'Upload failed after URL refresh retry',
    );
  }

  Future<ResumableUploadResult> _legacyResumableHttp({
    required String recordingId,
    required String serverId,
    required FileSource source,
    required String format,
    void Function(int bytesSent, int totalBytes)? onProgress,
  }) async {
    final recording = await _recordingRepo.getRecordingById(recordingId);
    if (recording == null) {
      return const ResumableUploadResult(
        success: false,
        error: 'Recording not found',
      );
    }

    String? sessionUri = recording.resumableSessionUri;
    int startOffset = recording.uploadedBytes;
    final fileLength = source.length;

    if (sessionUri != null && sessionUri.isNotEmpty) {
      final queryOffset = await _queryUploadOffset(sessionUri, fileLength);
      if (queryOffset == null) {
        sessionUri = null;
        startOffset = 0;
      } else if (queryOffset >= fileLength) {
        return const ResumableUploadResult(success: true);
      } else {
        startOffset = queryOffset;
      }
    }

    if (sessionUri == null || sessionUri.isEmpty) {
      final newSession = await _requestResumableSession(serverId, format);
      if (newSession == null) {
        return const ResumableUploadResult(
          success: false,
          error: 'Failed to create resumable upload session',
        );
      }
      sessionUri = newSession;
      startOffset = 0;

      await _recordingRepo.updateRecording(
        recordingId,
        LocalRecordingsCompanion(
          resumableSessionUri: Value(sessionUri),
          uploadedBytes: const Value(0),
        ),
      );
    }

    var offset = startOffset;

    if (offset > 0) {
      onProgress?.call(offset, fileLength);
    }

    while (offset < fileLength) {
      final end = (offset + _defaultChunkSize).clamp(0, fileLength);
      final chunkBytes = await source.readRange(offset, end);
      final contentRange = 'bytes $offset-${end - 1}/$fileLength';

      final chunkResult = await _legacyUploadChunkHttp(
        sessionUri: sessionUri!,
        chunk: chunkBytes,
        contentRange: contentRange,
      );

      if (chunkResult == _ChunkResult.success) {
        offset = end;
        onProgress?.call(offset, fileLength);

        await _recordingRepo.updateRecording(
          recordingId,
          LocalRecordingsCompanion(uploadedBytes: Value(offset)),
        );
      } else if (chunkResult == _ChunkResult.sessionExpired) {
        final newSession = await _requestResumableSession(serverId, format);
        if (newSession == null) {
          return const ResumableUploadResult(
            success: false,
            error: 'Failed to recreate resumable session after expiry',
          );
        }
        sessionUri = newSession;
        offset = 0;

        await _recordingRepo.updateRecording(
          recordingId,
          LocalRecordingsCompanion(
            resumableSessionUri: Value(sessionUri),
            uploadedBytes: const Value(0),
          ),
        );
      } else {
        return const ResumableUploadResult(
          success: false,
          error: 'Chunk upload failed',
        );
      }
    }

    await _recordingRepo.updateRecording(
      recordingId,
      const LocalRecordingsCompanion(
        resumableSessionUri: Value(null),
        uploadedBytes: Value(0),
      ),
    );

    return const ResumableUploadResult(success: true);
  }

  Future<_ChunkResult> _legacyUploadChunkHttp({
    required String sessionUri,
    required Uint8List chunk,
    required String contentRange,
  }) async {
    try {
      final request = http.Request('PUT', Uri.parse(sessionUri));
      request.headers['Content-Range'] = contentRange;
      request.bodyBytes = chunk;

      final timeout = Duration(
        seconds: 60 + (chunk.length ~/ (1024 * 1024)) * 10,
      );

      final response = await _client.rawClient.send(request).timeout(timeout);

      await response.stream.drain<void>();

      if (response.statusCode == 308) {
        return _ChunkResult.success;
      } else if (response.statusCode == 200 || response.statusCode == 201) {
        return _ChunkResult.success;
      } else if (response.statusCode == 410) {
        return _ChunkResult.sessionExpired;
      } else {
        return _ChunkResult.failed;
      }
    } on TimeoutException {
      return _ChunkResult.failed;
    } on Exception {
      return _ChunkResult.failed;
    }
  }

  Future<String?> _requestResumableSession(
    String serverId,
    String format,
  ) async {
    try {
      final response = await _client
          .post(
            '/api/oc/recordings/resumable-upload-url',
            body: {'recording_id': serverId, 'format': format},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['session_uri'] as String;
    } on Exception {
      return null;
    }
  }

  Future<int?> _queryUploadOffset(String sessionUri, int totalSize) async {
    try {
      final request = http.Request('PUT', Uri.parse(sessionUri));
      request.headers['Content-Length'] = '0';
      request.headers['Content-Range'] = 'bytes */$totalSize';

      final response = await _client.rawClient
          .send(request)
          .timeout(const Duration(seconds: 30));

      await response.stream.drain<void>();

      if (response.statusCode == 308) {
        final range = response.headers['range'];
        if (range != null && range.startsWith('bytes=0-')) {
          final lastByte = int.tryParse(range.substring(8));
          if (lastByte != null) return lastByte + 1;
        }
        return 0;
      } else if (response.statusCode == 200 || response.statusCode == 201) {
        return totalSize;
      } else {
        return null;
      }
    } on Exception {
      return null;
    }
  }
}

enum _ChunkResult { success, sessionExpired, failed }
