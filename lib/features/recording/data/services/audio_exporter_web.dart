import 'dart:js_interop';
import 'dart:ui' show Rect;

import 'package:logging/logging.dart';
import 'package:web/web.dart' as web;

import '../../../../core/platform/file_ops.dart' as file_ops;

class AudioExportResult {
  const AudioExportResult({required this.success, this.error});
  final bool success;
  final String? error;
}

class AudioExporter {
  static final _log = Logger('AudioExporter');

  static Future<AudioExportResult> shareAudio({
    required String localFilePath,
    String? suggestedName,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final bytes = await file_ops.readFileBytes(localFilePath);
      if (bytes.isEmpty) {
        return const AudioExportResult(
          success: false,
          error: 'File not found or empty',
        );
      }

      final blob = web.Blob(
        [bytes.toJS].toJS,
        web.BlobPropertyBag(type: 'application/octet-stream'),
      );
      final url = web.URL.createObjectURL(blob);
      final anchor = web.HTMLAnchorElement()
        ..href = url
        ..download = suggestedName ?? 'audio';
      web.document.body?.appendChild(anchor);
      anchor.click();
      anchor.remove();
      web.URL.revokeObjectURL(url);
      return const AudioExportResult(success: true);
    } catch (e, st) {
      _log.warning('shareAudio failed', e, st);
      return AudioExportResult(success: false, error: e.toString());
    }
  }
}
