import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../supported_audio_formats.dart';

class AudioExportResult {
  const AudioExportResult({required this.success, this.error});
  final bool success;
  final String? error;
}

class AudioExporter {
  static Future<AudioExportResult> shareAudio({
    required String localFilePath,
    String? suggestedName,
    Rect? sharePositionOrigin,
  }) async {
    try {
      if (!await File(localFilePath).exists()) {
        return AudioExportResult(
          success: false,
          error: 'File not found at $localFilePath',
        );
      }

      final ext = p
          .extension(suggestedName ?? localFilePath)
          .replaceFirst('.', '')
          .toLowerCase();
      final mime = kSupportedAudioMimeTypes[ext];

      final file = XFile(localFilePath, name: suggestedName, mimeType: mime);
      await Share.shareXFiles(
        [file],
        subject: suggestedName,
        sharePositionOrigin:
            sharePositionOrigin ?? const Rect.fromLTWH(0, 0, 1, 1),
      );
      return const AudioExportResult(success: true);
    } catch (e, st) {
      debugPrint('AudioExporter.shareAudio failed: $e\n$st');
      return AudioExportResult(success: false, error: e.toString());
    }
  }
}
