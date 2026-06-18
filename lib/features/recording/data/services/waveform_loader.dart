import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'waveform_extractor.dart';

/// Injectable waveform-peak loader. The trim editor uses it during load so the
/// (native, ffmpeg-backed) peak extraction can be faked in widget tests, which
/// cannot run ffmpeg. Returns an empty list when extraction yields nothing, so
/// callers can fall back to a synthetic waveform.
typedef WaveformLoader =
    Future<List<double>> Function(String path, {required int targetCount});

Future<List<double>> defaultWaveformLoader(
  String path, {
  required int targetCount,
}) async {
  final peaks = await WaveformExtractor.extractPeaks(
    path,
    targetCount: targetCount,
  );
  return peaks.peaks;
}

final waveformLoaderProvider = Provider<WaveformLoader>(
  (_) => defaultWaveformLoader,
);
