import 'dart:convert';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../../../core/platform/ffmpeg_ops.dart' as ffmpeg;
import '../../../../core/platform/file_ops.dart' as file_ops;

class RecordingConcatService {
  Future<String?> concatSegments({
    required List<String> segmentPaths,
    required String outputPath,
  }) async {
    if (segmentPaths.isEmpty) return null;

    final dir = await getTemporaryDirectory();
    final listPath =
        '${dir.path}/concat_${DateTime.now().millisecondsSinceEpoch}.txt';

    final listContents = segmentPaths
        .map((p) => "file '${p.replaceAll("'", r"'\''")}'")
        .join('\n');

    try {
      await file_ops.writeFileBytes(
        listPath,
        Uint8List.fromList(utf8.encode(listContents)),
      );

      final ok = await ffmpeg.executeFFmpegCommand(
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
