import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class UploadResult {
  final int statusCode;
  final String? responseBody;
  final String? errorReason;
  final bool cancelled;
  final Map<String, String> responseHeaders;

  const UploadResult({
    required this.statusCode,
    this.responseBody,
    this.errorReason,
    this.cancelled = false,
    this.responseHeaders = const {},
  });
}

abstract class UploadDownloader {
  Future<UploadResult> putChunk({
    required String taskId,
    required String url,
    required String filePath,
    required int offset,
    required int end,
    required Map<String, String> headers,
  });

  Future<void> cancel(String taskId);

  Future<void> cancelAll();

  /// Re-arms the uploader after a [cancelAll]. The coordinator calls this
  /// when the recording mutex releases. Implementations without sticky
  /// cancel state can return immediately.
  Future<void> resumeAfterCancel();
}

UploadDownloader defaultUploadDownloader({http.Client? httpClient}) {
  // In-process HTTP transport on every platform (see [HttpInlineUploader]):
  // the upload loop lives in the Dart isolate, so it stops when the app is
  // closed and resumes from the saved GCS offset on the next launch.
  return HttpInlineUploader(httpClient ?? http.Client());
}

/// In-process HTTP chunk transport. Used on Android so the upload loop dies
/// together with the Dart isolate when the user swipes the app away, matching
/// the iOS behaviour (pause on close, resume from offset on next launch).
class HttpInlineUploader implements UploadDownloader {
  HttpInlineUploader(this._client);

  final http.Client _client;
  final Set<String> _cancelledTaskIds = {};
  bool _cancelAllPending = false;

  @override
  Future<UploadResult> putChunk({
    required String taskId,
    required String url,
    required String filePath,
    required int offset,
    required int end,
    required Map<String, String> headers,
  }) async {
    if (_cancelAllPending || _cancelledTaskIds.contains(taskId)) {
      return const UploadResult(statusCode: 0, cancelled: true);
    }

    final file = File(filePath);
    if (!await file.exists()) {
      return const UploadResult(statusCode: 0, errorReason: 'file_not_found');
    }

    final raf = await file.open();
    Uint8List bytes;
    try {
      await raf.setPosition(offset);
      bytes = await raf.read(end - offset);
    } finally {
      await raf.close();
    }

    if (_cancelAllPending || _cancelledTaskIds.contains(taskId)) {
      return const UploadResult(statusCode: 0, cancelled: true);
    }

    final request = http.Request('PUT', Uri.parse(url));
    headers.forEach((k, v) => request.headers[k] = v);
    request.bodyBytes = bytes;

    final timeout = Duration(
      seconds: 60 + (bytes.length ~/ (1024 * 1024)) * 10,
    );

    try {
      final response = await _client.send(request).timeout(timeout);
      final body = await response.stream.bytesToString();
      if (_cancelAllPending || _cancelledTaskIds.contains(taskId)) {
        _cancelledTaskIds.remove(taskId);
        return UploadResult(
          statusCode: response.statusCode,
          responseBody: body,
          responseHeaders: response.headers,
          cancelled: true,
        );
      }
      return UploadResult(
        statusCode: response.statusCode,
        responseBody: body,
        responseHeaders: response.headers,
      );
    } on TimeoutException {
      return const UploadResult(statusCode: 0, errorReason: 'timeout');
    } on http.ClientException catch (e) {
      return UploadResult(statusCode: 0, errorReason: e.message);
    } on SocketException catch (e) {
      return UploadResult(statusCode: 0, errorReason: e.message);
    }
  }

  @override
  Future<void> cancel(String taskId) async {
    _cancelledTaskIds.add(taskId);
  }

  @override
  Future<void> cancelAll() async {
    _cancelAllPending = true;
  }

  @override
  Future<void> resumeAfterCancel() async {
    _cancelAllPending = false;
    _cancelledTaskIds.clear();
  }
}

bool fileIsReadable(String filePath) {
  try {
    final f = File(filePath);
    return f.existsSync();
  } on FileSystemException {
    return false;
  }
}
