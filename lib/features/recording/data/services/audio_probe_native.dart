import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';

import '../../../../core/platform/file_source.dart';

import 'audio_probe.dart';

final _log = Logger('AudioProbe');

String createPlayableBlobUrl(Uint8List bytes, String mime) {
  throw UnsupportedError(
    'createPlayableBlobUrl is only available on web builds',
  );
}

void revokePlayableBlobUrl(String url) {}

Future<AudioProbeResult> probeWithPlayer({
  required Uint8List? bytes,
  required String? filePath,
  required String extension,
  required String mime,
}) async {
  if (filePath == null) {
    return const AudioProbeResult(diagnostic: 'native_player: no filePath');
  }
  return _probePath(filePath: filePath, extension: extension);
}

Future<AudioProbeResult> probeWithPlayerFromSource({
  required FileSource source,
  required String extension,
  required String mime,
}) async {
  final path = source.filePath;
  if (path == null) {
    return const AudioProbeResult(
      diagnostic: 'native_player: source has no filePath',
    );
  }
  return _probePath(filePath: path, extension: extension);
}

Future<AudioProbeResult> _probePath({
  required String filePath,
  required String extension,
}) async {
  final player = AudioPlayer();
  try {
    final duration = await player.setFilePath(filePath);
    if (duration == null) {
      return const AudioProbeResult(
        diagnostic: 'native_player: setFilePath returned null duration',
      );
    }
    return AudioProbeResult(
      durationSeconds: duration.inMilliseconds / 1000.0,
      playable: true,
      diagnostic: 'native_player ok',
    );
  } catch (e, st) {
    _log.warning('native player failed for .$extension', e, st);
    return AudioProbeResult(diagnostic: 'native_player: $e');
  } finally {
    await player.dispose();
  }
}
