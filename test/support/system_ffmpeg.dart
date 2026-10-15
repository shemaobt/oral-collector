import 'dart:io';

Future<bool> runSystemFFmpeg(String command) async {
  final result = await Process.run('sh', [
    '-c',
    'ffmpeg -hide_banner -loglevel error $command',
  ]);
  return result.exitCode == 0;
}

Future<void> writeToneM4a(String path, {required int seconds}) async {
  final ok = await runSystemFFmpeg(
    '-y -f lavfi -i "sine=frequency=440:duration=$seconds" '
    '-ac 1 -ar 16000 -c:a aac -b:a 128k "$path"',
  );
  if (!ok) throw StateError('could not generate $path');
}

Future<void> writeToneMp3(String path, {required int seconds}) async {
  final ok = await runSystemFFmpeg(
    '-y -f lavfi -i "sine=frequency=440:duration=$seconds" '
    '-ac 1 -ar 16000 -c:a libmp3lame -b:a 64k "$path"',
  );
  if (!ok) throw StateError('could not generate $path');
}

Future<double> measuredDurationSeconds(String path) async {
  final result = await Process.run('ffprobe', [
    '-v',
    'error',
    '-show_entries',
    'format=duration',
    '-of',
    'csv=p=0',
    path,
  ]);
  return double.parse((result.stdout as String).trim());
}

Future<double> measuredMeanVolumeDb(String path) async {
  final result = await Process.run('ffmpeg', [
    '-hide_banner',
    '-i',
    path,
    '-af',
    'volumedetect',
    '-f',
    'null',
    '-',
  ]);
  final match = RegExp(
    r'mean_volume: (-?[\d.]+) dB',
  ).firstMatch(result.stderr as String);
  if (match == null) throw StateError('no volume measured for $path');
  return double.parse(match.group(1)!);
}
