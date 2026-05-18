import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:path/path.dart' as p;

/// Result of a single PUT chunk transfer.
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

/// Wraps a single-chunk PUT transfer behind an interface so tests can inject a
/// fake transport in place of `background_downloader`. The implementation
/// must support PUTs with `Content-Range` headers and a `Range` header that
/// instructs the underlying plugin to slice the local file client-side.
abstract class UploadDownloader {
  /// PUT bytes [offset, end) of [filePath] to [url] with [headers].
  ///
  /// Implementations should add a `Range: bytes=$offset-${end - 1}` header
  /// (only on real `background_downloader` impl; the plugin strips it before
  /// sending and slices the local file). Other headers (`Content-Range`,
  /// `Authorization`, `Content-Type`) are forwarded as-is to the server.
  Future<UploadResult> putChunk({
    required String taskId,
    required String url,
    required String filePath,
    required int offset,
    required int end,
    required Map<String, String> headers,
  });

  Future<void> cancel(String taskId);

  /// Cancel every upload task currently in flight, regardless of recording.
  /// Called when recording starts so the in-flight chunk is aborted and the
  /// resumable loop can short-circuit via `paused_by_recording` (§1 mutex).
  Future<void> cancelAll();
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
    final status = result.responseStatusCode ?? 0;
    final body = result.responseBody;
    switch (result.status) {
      case TaskStatus.complete:
        return UploadResult(statusCode: status, responseBody: body);
      case TaskStatus.canceled:
        return UploadResult(
          statusCode: status,
          responseBody: body,
          cancelled: true,
        );
      case TaskStatus.failed:
      case TaskStatus.notFound:
      case TaskStatus.enqueued:
      case TaskStatus.running:
      case TaskStatus.waitingToRetry:
      case TaskStatus.paused:
        final exception = result.exception;
        return UploadResult(
          statusCode: status,
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
      // ignore — task may already be done
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
      // best-effort cancel; ignore if plugin already cleared tasks.
    }
  }
}

/// Ensure the file path is reachable by `background_downloader` on iOS where
/// some apps stage files in a sandboxed tmp dir.
bool fileIsReadable(String filePath) {
  try {
    final f = File(filePath);
    return f.existsSync();
  } on FileSystemException {
    return false;
  }
}
