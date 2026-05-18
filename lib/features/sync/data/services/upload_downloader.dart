import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class UploadResult {
  final int statusCode;
  final String? responseBody;
  final String? errorReason;
  final bool cancelled;

  const UploadResult({
    required this.statusCode,
    this.responseBody,
    this.errorReason,
    this.cancelled = false,
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
}

UploadDownloader defaultUploadDownloader({http.Client? httpClient}) {
  if (!kIsWeb && Platform.isAndroid) {
    return HttpInlineUploader(httpClient ?? http.Client());
  }
  return const BackgroundDownloaderUploader();
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
          cancelled: true,
        );
      }
      return UploadResult(statusCode: response.statusCode, responseBody: body);
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
    Future<void>.delayed(const Duration(seconds: 2), () {
      _cancelAllPending = false;
    });
  }
}

class BackgroundDownloaderUploader implements UploadDownloader {
  const BackgroundDownloaderUploader();

  @override
  Future<UploadResult> putChunk({
    required String taskId,
    required String url,
    required String filePath,
    required int offset,
    required int end,
    required Map<String, String> headers,
  }) async {
    final dir = p.dirname(filePath);
    final filename = p.basename(filePath);
    final task = UploadTask(
      taskId: taskId,
      url: url,
      baseDirectory: BaseDirectory.root,
      directory: dir.startsWith('/') ? dir.substring(1) : dir,
      filename: filename,
      httpRequestMethod: 'PUT',
      post: 'binary',
      headers: {...headers, 'Range': 'bytes=$offset-${end - 1}'},
      priority: 0,
      updates: Updates.statusAndProgress,
      retries: 0,
    );

    final result = await FileDownloader().upload(task);
    final exception = result.exception;
    final effectiveStatus = switch (result.status) {
      TaskStatus.complete => result.responseStatusCode ?? 200,
      _ when exception is TaskHttpException && exception.httpResponseCode > 0 =>
        exception.httpResponseCode,
      _ => result.responseStatusCode ?? 0,
    };
    final body = result.responseBody;
    switch (result.status) {
      case TaskStatus.complete:
        return UploadResult(statusCode: effectiveStatus, responseBody: body);
      case TaskStatus.canceled:
        return UploadResult(
          statusCode: effectiveStatus,
          responseBody: body,
          cancelled: true,
        );
      case TaskStatus.failed:
      case TaskStatus.notFound:
      case TaskStatus.enqueued:
      case TaskStatus.running:
      case TaskStatus.waitingToRetry:
      case TaskStatus.paused:
        return UploadResult(
          statusCode: effectiveStatus,
          responseBody: body,
          errorReason: exception?.description ?? result.status.name,
        );
    }
  }

  @override
  Future<void> cancel(String taskId) async {
    try {
      await FileDownloader().cancelTaskWithId(taskId);
    } on Object {
      // task already finished
    }
  }

  @override
  Future<void> cancelAll() async {
    try {
      final tasks = await FileDownloader().allTasks();
      for (final task in tasks) {
        await FileDownloader().cancelTaskWithId(task.taskId);
      }
    } on Object {
      // best-effort
    }
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
