import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:web/web.dart' as web;

import 'audio_probe.dart';

String createPlayableBlobUrl(Uint8List bytes, String mime) {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mime));
  return web.URL.createObjectURL(blob);
}

void revokePlayableBlobUrl(String url) {
  web.URL.revokeObjectURL(url);
}

Future<AudioProbeResult> probeWithPlayer({
  required Uint8List? bytes,
  required String? filePath,
  required String extension,
  required String mime,
}) async {
  if (bytes == null) {
    return const AudioProbeResult(diagnostic: 'web_player: no bytes available');
  }
  final url = createPlayableBlobUrl(bytes, mime);
  final player = AudioPlayer();
  try {
    final duration = await player.setUrl(url);
    if (duration == null) {
      return const AudioProbeResult(
        diagnostic: 'web_player: setUrl returned null duration',
      );
    }
    return AudioProbeResult(
      durationSeconds: duration.inMilliseconds / 1000.0,
      playable: true,
      diagnostic: 'web_player ok',
    );
  } catch (e, st) {
    debugPrint(
      'AudioProbe web player failed for .$extension (${bytes.length}B): $e\n$st',
    );
    return AudioProbeResult(diagnostic: 'web_player: $e');
  } finally {
    revokePlayableBlobUrl(url);
    await player.dispose();
  }
}
