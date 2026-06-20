import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../../../core/platform/ffmpeg_ops.dart' as ffmpeg;
import '../../../../core/platform/file_ops.dart' as file_ops;

typedef TempDirPathFn = Future<String> Function();
typedef NowFn = DateTime Function();
typedef FfmpegExecFn = Future<bool> Function(String command);

class RecordingConcatService {
  RecordingConcatService({
    TempDirPathFn? tempDirPath,
    NowFn? now,
    FfmpegExecFn? ffmpegExec,
  }) : _tempDirPath = tempDirPath ?? _defaultTempDirPath,
       _now = now ?? DateTime.now,
       _ffmpegExec = ffmpegExec ?? ffmpeg.executeFFmpegCommand;

  final TempDirPathFn _tempDirPath;
  final NowFn _now;
  final FfmpegExecFn _ffmpegExec;

  static Future<String> _defaultTempDirPath() async =>
      (await getTemporaryDirectory()).path;

  static String _scratchSuffix() =>
      math.Random.secure().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');

  Future<String?> concatSegments({
    required List<String> segmentPaths,
    required String outputPath,
  }) async {
    if (segmentPaths.isEmpty) return null;

    final dirPath = await _tempDirPath();
    // Random suffix on top of the timestamp: two concats that start in the same
    // millisecond (back-to-back recordings, a retry) must not share a scratch
    // list file and corrupt each other's ffmpeg input.
    final listPath =
        '$dirPath/concat_${_now().millisecondsSinceEpoch}_${_scratchSuffix()}.txt';

    final listContents = segmentPaths
        .map((p) => "file '${p.replaceAll("'", r"'\''")}'")
        .join('\n');

    try {
      await file_ops.writeFileBytes(
        listPath,
        Uint8List.fromList(utf8.encode(listContents)),
      );

      final ok = await _ffmpegExec(
        '-y -f concat -safe 0 -i "$listPath" -c copy "$outputPath"',
      );

      if (!ok) return null;

      if (!await file_ops.fileExists(outputPath)) return null;
      if (await file_ops.fileLength(outputPath) <= 0) return null;

      return outputPath;
    } finally {
      try {
        await file_ops.deleteFile(listPath);
      } catch (_) {}
    }
  }
}
