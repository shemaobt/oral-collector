import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../../core/platform/file_ops.dart' as file_ops;

/// Injectable audio downloaders (ENG-194). The detail screen used to call the
/// package-global `http.get` inline, which can't be intercepted in a unit test.
/// Behind these seams the notifier orchestrates the download while tests swap in
/// a fake. Web-safe to compile: all filesystem access goes through the
/// `file_ops` facade — no direct `dart:io`.

/// Downloads [url] and writes it under the app documents dir, returning the
/// local path. Throws when the response status is not 200.
typedef AudioCacheDownloader =
    Future<String> Function({required String url, required String format});

Future<String> downloadAudioToCache({
  required String url,
  required String format,
}) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw Exception('Download failed (${response.statusCode})');
  }
  final docsDir = await getApplicationDocumentsDirectory();
  final ext = format.isNotEmpty ? format : 'm4a';
  final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.$ext';
  final filePath = '${docsDir.path}/$fileName';
  await file_ops.writeFileBytes(filePath, response.bodyBytes);
  return filePath;
}

final audioCacheDownloaderProvider = Provider<AudioCacheDownloader>(
  (_) => downloadAudioToCache,
);

/// Downloads [url] to a temporary file for sharing, returning the temp path.
/// Throws when the response status is not 200.
typedef AudioExportDownloader =
    Future<String> Function({
      required String url,
      required String recordingId,
      required String format,
    });

Future<String> downloadAudioForExport({
  required String url,
  required String recordingId,
  required String format,
}) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw Exception('Download failed (${response.statusCode})');
  }
  final tempPath =
      'export_${recordingId}_${DateTime.now().millisecondsSinceEpoch}.$format';
  await file_ops.writeFileBytes(tempPath, response.bodyBytes);
  return tempPath;
}

final audioExportDownloaderProvider = Provider<AudioExportDownloader>(
  (_) => downloadAudioForExport,
);
