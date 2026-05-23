import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/platform/ffmpeg_ops.dart' as ffmpeg_ops;
import '../../../../core/platform/file_ops.dart' as file_ops;
import '../../presentation/notifiers/recording_session_state.dart';
import 'recording_concat_service.dart';
import 'wav_concat.dart';

typedef CompressFn = Future<bool> Function(String src, String dst);
typedef DocumentsDirFn = Future<Directory> Function();

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
  }) : _concat = concat,
       _compressFn = compressFn ?? ffmpeg_ops.compressToM4a,
       _documentsDirFn = documentsDirFn ?? getApplicationDocumentsDirectory;

  final RecordingConcatService _concat;
  final CompressFn _compressFn;
  final DocumentsDirFn _documentsDirFn;

  Future<FinalizationOutcome?> finalize({
    required String sessionId,
    required List<String> segmentPaths,
    required Duration totalDuration,
    void Function(FinalizationStage stage)? onStage,
  }) async {
    if (segmentPaths.isEmpty) return null;

    onStage?.call(FinalizationStage.finalizing);

    final dir = await _documentsDirFn();
    String sourcePath;
    var degraded = false;

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
        for (final p in segmentPaths) {
          unawaited(_deleteFileSafe(p));
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
        unawaited(_deleteFileSafe(sourcePath));
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
    try {
      await file_ops.deleteFile(path);
    } catch (_) {}
  }
}
