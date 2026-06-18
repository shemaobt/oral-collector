import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/observability/error_reporter.dart';
import '../../../../core/platform/ffmpeg_ops.dart' as ffmpeg_ops;
import '../../../../core/platform/file_ops.dart' as file_ops;
import '../../presentation/notifiers/recording_session_state.dart';
import 'recording_concat_service.dart';
import 'wav_concat.dart';

typedef CompressFn = Future<bool> Function(String src, String dst);
typedef DocumentsDirFn = Future<Directory> Function();
typedef DeleteFn = Future<void> Function(String path);

class FinalizationOutcome {
  const FinalizationOutcome({required this.result, this.degraded = false});

  final RecordingResult result;
  final bool degraded;
}

class RecordingFinalizationService {
  RecordingFinalizationService({
    required RecordingConcatService concat,
    CompressFn? compressFn,
    DocumentsDirFn? documentsDirFn,
    DeleteFn? deleteFn,
    ErrorReporter reporter = const NoopErrorReporter(),
  }) : _concat = concat,
       _compressFn = compressFn ?? ffmpeg_ops.compressToM4a,
       _documentsDirFn = documentsDirFn ?? getApplicationDocumentsDirectory,
       _deleteFn = deleteFn ?? file_ops.deleteFile,
       _reporter = reporter;

  final RecordingConcatService _concat;
  final CompressFn _compressFn;
  final DocumentsDirFn _documentsDirFn;
  final DeleteFn _deleteFn;
  final ErrorReporter _reporter;

  Future<FinalizationOutcome?> finalize({
    required String sessionId,
    required List<String> segmentPaths,
    required Duration totalDuration,
    void Function(FinalizationStage stage)? onStage,
    bool deleteSources = true,
  }) async {
    if (segmentPaths.isEmpty) return null;

    onStage?.call(FinalizationStage.finalizing);

    final dir = await _documentsDirFn();
    String sourcePath;
    var degraded = false;
    // sourcePath is a concat temp we created, not an original recording.
    var derived = false;

    if (segmentPaths.length == 1) {
      sourcePath = segmentPaths.first;
    } else {
      onStage?.call(FinalizationStage.combiningSegments);
      final firstIsWav = segmentPaths.first.toLowerCase().endsWith('.wav');
      final concatExt = firstIsWav ? 'wav' : 'm4a';
      final concatPath = '${dir.path}/concat_$sessionId.$concatExt';

      String? concatResult;
      try {
        concatResult = await _concat.concatSegments(
          segmentPaths: segmentPaths,
          outputPath: concatPath,
        );
      } catch (e, st) {
        debugPrint('RecordingFinalizationService: concat failed: $e\n$st');
        concatResult = null;
      }

      if (concatResult == null && firstIsWav) {
        try {
          final ok = await concatWavFilesInDart(
            segments: segmentPaths,
            outputPath: concatPath,
          );
          if (ok) {
            concatResult = concatPath;
            degraded = true;
          }
        } catch (e, st) {
          debugPrint(
            'RecordingFinalizationService: pure-dart WAV concat failed: '
            '$e\n$st',
          );
        }
      }

      if (concatResult != null) {
        sourcePath = concatResult;
        derived = true;
        if (deleteSources) {
          for (final p in segmentPaths) {
            unawaited(_deleteFileSafe(p));
          }
        }
      } else {
        sourcePath = segmentPaths.first;
        degraded = true;
      }
    }

    final isWav = sourcePath.toLowerCase().endsWith('.wav');
    if (isWav) {
      onStage?.call(FinalizationStage.compressingAudio);
      final m4aPath = '${dir.path}/recording_$sessionId.m4a';
      var ok = false;
      try {
        ok = await _compressFn(sourcePath, m4aPath);
      } catch (e, st) {
        debugPrint('RecordingFinalizationService: compress failed: $e\n$st');
        ok = false;
      }
      if (ok) {
        // Delete sourcePath when the caller wants the sources gone, or when it
        // is a concat temp we created (never an original recording, so safe to
        // reclaim even while keeping sources).
        if (deleteSources || derived) {
          unawaited(_deleteFileSafe(sourcePath));
        }
        return FinalizationOutcome(
          result: RecordingResult(
            filePath: m4aPath,
            durationSeconds: totalDuration.inMilliseconds / 1000.0,
          ),
          degraded: degraded,
        );
      }
      return FinalizationOutcome(
        result: RecordingResult(
          filePath: sourcePath,
          durationSeconds: totalDuration.inMilliseconds / 1000.0,
          format: 'wav',
        ),
        degraded: true,
      );
    }

    return FinalizationOutcome(
      result: RecordingResult(
        filePath: sourcePath,
        durationSeconds: totalDuration.inMilliseconds / 1000.0,
      ),
      degraded: degraded,
    );
  }

  Future<void> _deleteFileSafe(String path) async {
    // Best-effort cleanup stays fire-and-forget, but a real failure (permission,
    // I/O) must not vanish silently. file_ops tolerates a missing file, so
    // anything thrown here is a genuine failure worth surfacing.
    try {
      await _deleteFn(path);
    } catch (e, st) {
      _reporter.reportError(e, st);
    }
  }
}
