import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

import '../../../../core/platform/ffmpeg_ops.dart' as ffmpeg;

class WaveformPeaks {
  final List<double> peaks;
  final int targetCount;

  const WaveformPeaks(this.peaks, this.targetCount);

  bool get isEmpty => peaks.isEmpty;
}

class WaveformExtractor {
  static final Map<String, WaveformPeaks> _cache = {};

  static String _cacheKey(String audioPath, int fileLength, int targetCount) {
    return '$audioPath|$fileLength|$targetCount';
  }

  static Future<WaveformPeaks> extractPeaks(
    String audioPath, {
    int targetCount = 2000,
  }) async {
    if (kIsWeb) return const WaveformPeaks([], 0);

    int fileLength = 0;
    try {
      fileLength = await File(audioPath).length();
    } on FileSystemException {
      // fall through with length 0
    }

    final key = _cacheKey(audioPath, fileLength, targetCount);
    final cached = _cache[key];
    if (cached != null && cached.peaks.isNotEmpty) return cached;

    final tempDir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final pcmPath = '${tempDir.path}/peaks_$stamp.pcm';

    final command = '-y -i "$audioPath" -ac 1 -ar 8000 -f s16le "$pcmPath"';
    final success = await ffmpeg.executeFFmpegCommand(command);
    if (!success) {
      return const WaveformPeaks([], 0);
    }

    try {
      final pcmFile = File(pcmPath);
      if (!await pcmFile.exists()) return const WaveformPeaks([], 0);

      final bytes = await pcmFile.readAsBytes();
      if (bytes.isEmpty) return const WaveformPeaks([], 0);

      final peaks = _binPeaks(bytes, targetCount);
      final result = WaveformPeaks(peaks, targetCount);
      _cache[key] = result;
      return result;
    } finally {
      try {
        await File(pcmPath).delete();
      } on FileSystemException {
        // ignore
      }
    }
  }

  static void invalidate(String audioPath) {
    _cache.removeWhere((k, _) => k.startsWith('$audioPath|'));
  }

  static List<double> _binPeaks(Uint8List bytes, int targetCount) {
    final sampleCount = bytes.lengthInBytes ~/ 2;
    if (sampleCount == 0 || targetCount <= 0) return const [];

    final samplesPerBin = math.max(1, sampleCount ~/ targetCount);
    final peaks = List<double>.filled(targetCount, 0.0);
    final data = ByteData.sublistView(bytes);

    for (var bin = 0; bin < targetCount; bin++) {
      final start = bin * samplesPerBin;
      final end = math.min(sampleCount, start + samplesPerBin);
      if (start >= end) break;

      var peak = 0;
      for (var i = start; i < end; i++) {
        final v = data.getInt16(i * 2, Endian.little).abs();
        if (v > peak) peak = v;
      }
      peaks[bin] = (peak / 32767.0).clamp(0.0, 1.0);
    }

    return peaks;
  }
}
