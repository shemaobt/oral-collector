import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';

import 'file_ops.dart' as file_ops;

typedef FFmpegRunner = Future<bool> Function(String command);

Future<bool> executeFFmpegCommand(String command) async {
  final session = await FFmpegKit.execute(command);
  final returnCode = await session.getReturnCode();
  return ReturnCode.isSuccess(returnCode);
}

Future<bool> compressToM4a(
  String inputPath,
  String outputPath, {
  FFmpegRunner runner = executeFFmpegCommand,
}) async {
  final ok = await runner(
    '-i "$inputPath" -c:a aac -b:a 128k -ar 16000 -ac 1 -y "$outputPath"',
  );
  // A success return code does not guarantee a real output: ffmpeg can exit 0
  // with a missing or empty file (release-mode/permission edge cases). Verify
  // before the caller treats this as license to delete the source (ENG-140 F18).
  if (!ok) return false;
  if (!await file_ops.fileExists(outputPath)) return false;
  if (await file_ops.fileLength(outputPath) <= 0) return false;
  return true;
}
