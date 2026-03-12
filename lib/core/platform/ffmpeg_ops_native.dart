import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';

Future<bool> executeFFmpegCommand(String command) async {
  final session = await FFmpegKit.execute(command);
  final returnCode = await session.getReturnCode();
  return ReturnCode.isSuccess(returnCode);
}
