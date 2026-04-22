import 'package:flutter/foundation.dart';

import 'audio_probe_native.dart'
    if (dart.library.js_interop) 'audio_probe_web.dart';

export 'audio_probe_native.dart'
    if (dart.library.js_interop) 'audio_probe_web.dart'
    show createPlayableBlobUrl, revokePlayableBlobUrl;

@immutable
class AudioProbeResult {
  const AudioProbeResult({
    this.durationSeconds,
    this.codec,
    this.playable = false,
    this.diagnostic,
  });

  final double? durationSeconds;
  final String? codec;
  final bool playable;
  final String? diagnostic;

  bool get hasDuration =>
      durationSeconds != null &&
      durationSeconds!.isFinite &&
      durationSeconds! > 0;
}

class AudioProbe {
  const AudioProbe();

  Future<AudioProbeResult> probe({
    required Uint8List? bytes,
    required String? filePath,
    required String extension,
    required String mime,
  }) async {
    AudioProbeResult? headerResult;
    if (extension == 'wav' && bytes != null) {
      headerResult = _probeWavHeader(bytes);
    }

    if (headerResult != null &&
        headerResult.hasDuration &&
        headerResult.playable) {
      return headerResult;
    }

    AudioProbeResult playerResult;
    try {
      playerResult = await probeWithPlayer(
        bytes: bytes,
        filePath: filePath,
        extension: extension,
        mime: mime,
      );
    } catch (e, st) {
      debugPrint('AudioProbe: probeWithPlayer threw for $extension: $e\n$st');
      playerResult = AudioProbeResult(diagnostic: 'player_exception: $e');
    }

    final duration =
        playerResult.durationSeconds ?? headerResult?.durationSeconds;
    final codec = headerResult?.codec ?? playerResult.codec;
    final playable = playerResult.playable || (headerResult?.playable ?? false);
    final diagnostic = [
      headerResult?.diagnostic,
      playerResult.diagnostic,
    ].where((d) => d != null && d.isNotEmpty).join('; ');

    return AudioProbeResult(
      durationSeconds: duration,
      codec: codec,
      playable: playable,
      diagnostic: diagnostic.isEmpty ? null : diagnostic,
    );
  }

  AudioProbeResult? _probeWavHeader(Uint8List bytes) {
    if (bytes.length < 44) return null;

    try {
      final magic = String.fromCharCodes(bytes.sublist(0, 4));
      if (magic != 'RIFF' && magic != 'RIFX') return null;
      final waveTag = String.fromCharCodes(bytes.sublist(8, 12));
      if (waveTag != 'WAVE') return null;

      final endian = magic == 'RIFF' ? Endian.little : Endian.big;
      final data = ByteData.sublistView(bytes);

      var offset = 12;
      int? formatTag;
      int? channels;
      int? sampleRate;
      int? byteRate;
      int? dataSize;
      String? subFormatCodec;

      while (offset + 8 <= bytes.length) {
        final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
        final chunkSize = data.getUint32(offset + 4, endian);
        final payloadStart = offset + 8;

        if (chunkId == 'fmt ' && chunkSize >= 16) {
          if (payloadStart + 16 > bytes.length) return null;
          formatTag = data.getUint16(payloadStart, endian);
          channels = data.getUint16(payloadStart + 2, endian);
          sampleRate = data.getUint32(payloadStart + 4, endian);
          byteRate = data.getUint32(payloadStart + 8, endian);

          if (formatTag == 0xFFFE &&
              chunkSize >= 40 &&
              payloadStart + 40 <= bytes.length) {
            final sub = data.getUint16(payloadStart + 24, endian);
            subFormatCodec = _codecName(sub);
          }
        } else if (chunkId == 'data') {
          dataSize = chunkSize;
          break;
        }

        final next = payloadStart + chunkSize + (chunkSize & 1);
        if (next <= offset) return null;
        offset = next;
      }

      if (formatTag == null || byteRate == null || byteRate == 0) return null;
      if (dataSize == null) return null;
      if (dataSize == 0xFFFFFFFF) return null;

      final codec = subFormatCodec ?? _codecName(formatTag);
      final playable = _isWavPlayableCodec(formatTag, subFormatCodec);

      return AudioProbeResult(
        durationSeconds: dataSize / byteRate,
        codec: codec,
        playable: playable,
        diagnostic:
            'wav_header fmt=0x${formatTag.toRadixString(16)} ch=$channels sr=$sampleRate',
      );
    } catch (e) {
      return null;
    }
  }

  String _codecName(int formatTag) {
    switch (formatTag) {
      case 0x0001:
        return 'pcm';
      case 0x0003:
        return 'ieee_float';
      case 0x0006:
        return 'alaw';
      case 0x0007:
        return 'mulaw';
      case 0x0011:
        return 'adpcm_ms';
      case 0x0050:
        return 'mpeg';
      case 0x0055:
        return 'mp3';
      case 0x0161:
        return 'wma_v2';
      case 0xFFFE:
        return 'extensible';
      default:
        return 'unknown_0x${formatTag.toRadixString(16)}';
    }
  }

  bool _isWavPlayableCodec(int formatTag, String? subFormat) {
    if (formatTag == 0x0001 || formatTag == 0x0003) return true;
    if (formatTag == 0xFFFE) {
      return subFormat == 'pcm' || subFormat == 'ieee_float';
    }
    return false;
  }
}
