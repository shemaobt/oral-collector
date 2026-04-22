import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_probe.dart';

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
    debugPrint('AudioProbe native player failed for .$extension: $e\n$st');
    return AudioProbeResult(diagnostic: 'native_player: $e');
  } finally {
    await player.dispose();
  }
}
