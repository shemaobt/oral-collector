import 'dart:async';

import 'package:path_provider/path_provider.dart';

import '../../../../core/platform/ffmpeg_ops.dart' as ffmpeg_ops;
import '../../../../core/platform/file_ops.dart' as file_ops;
import '../../presentation/notifiers/recording_session_state.dart';
import 'recording_concat_service.dart';

class RecordingFinalizationService {
  RecordingFinalizationService({required RecordingConcatService concat})
    : _concat = concat;

  final RecordingConcatService _concat;

  Future<RecordingResult?> finalize({
    required String sessionId,
    required List<String> segmentPaths,
    required Duration totalDuration,
  }) async {
    if (segmentPaths.isEmpty) return null;
    final dir = await getApplicationDocumentsDirectory();
    String sourcePath;

    if (segmentPaths.length == 1) {
      sourcePath = segmentPaths.first;
    } else {
      final firstIsWav = segmentPaths.first.toLowerCase().endsWith('.wav');
      final concatExt = firstIsWav ? 'wav' : 'm4a';
      final concatPath = '${dir.path}/concat_$sessionId.$concatExt';
      final concatResult = await _concat.concatSegments(
        segmentPaths: segmentPaths,
        outputPath: concatPath,
      );
      if (concatResult != null) {
        sourcePath = concatResult;
        for (final p in segmentPaths) {
          unawaited(_deleteFileSafe(p));
        }
      } else {
        sourcePath = segmentPaths.first;
      }
    }

    final isWav = sourcePath.toLowerCase().endsWith('.wav');
    if (isWav) {
      final m4aPath = '${dir.path}/recording_$sessionId.m4a';
      final ok = await ffmpeg_ops.compressToM4a(sourcePath, m4aPath);
      if (ok) {
        unawaited(_deleteFileSafe(sourcePath));
        return RecordingResult(
          filePath: m4aPath,
          durationSeconds: totalDuration.inMilliseconds / 1000.0,
        );
      }
      return RecordingResult(
        filePath: sourcePath,
        durationSeconds: totalDuration.inMilliseconds / 1000.0,
        format: 'wav',
      );
    }

    return RecordingResult(
      filePath: sourcePath,
      durationSeconds: totalDuration.inMilliseconds / 1000.0,
    );
  }

  Future<void> _deleteFileSafe(String path) async {
    try {
      await file_ops.deleteFile(path);
    } catch (_) {}
  }
}
