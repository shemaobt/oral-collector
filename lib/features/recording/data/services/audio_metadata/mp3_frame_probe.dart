import 'dart:typed_data';

import '../../../../../core/platform/file_source.dart';
import '../audio_probe_result.dart';

/// Extracts duration from an MP3 by reading the first frame header (skipping any
/// ID3v2 tag). For VBR files it reads the Xing/Info frame count; for CBR it
/// derives duration from the file size and bitrate. MP3 is browser-playable, so
/// a successful parse always reports `playable: true`. Returns null when the
/// bytes are not MP3.
Future<AudioProbeResult?> probeMp3Duration(FileSource source) async {
  final total = source.length;
  if (total < 4) return null;

  final frameStart = await _firstFrameOffset(source, total);
  if (frameStart + 4 > total) return null;

  final windowEnd = frameStart + 2048 <= total ? frameStart + 2048 : total;
  final window = await source.readRange(frameStart, windowEnd);

  _Mp3Header? header;
  var p = -1;
  for (var i = 0; i + 4 <= window.length; i++) {
    if (window[i] == 0xFF && (window[i + 1] & 0xE0) == 0xE0) {
      final h = _parseHeader(window, i);
      if (h != null) {
        header = h;
        p = i;
        break;
      }
    }
  }
  if (header == null) return null;

  final double seconds;
  final frames = _xingFrameCount(window, p + _xingTagOffset(header));
  if (frames != null && frames > 0) {
    seconds = frames * header.samplesPerFrame / header.sampleRate;
  } else {
    final id3v1 = await _hasId3v1(source) ? 128 : 0;
    final audioBytes = total - frameStart - id3v1;
    if (audioBytes <= 0 || header.bitrate <= 0) return null;
    seconds = audioBytes * 8 / (header.bitrate * 1000);
  }
  if (seconds <= 0) return null;

  return AudioProbeResult(
    durationSeconds: seconds,
    codec: 'mp3',
    playable: true,
    diagnostic: 'mp3_frame ok',
  );
}

Future<int> _firstFrameOffset(FileSource source, int total) async {
  final head = await source.readHead(total < 10 ? total : 10);
  if (head.length >= 10 &&
      head[0] == 0x49 &&
      head[1] == 0x44 &&
      head[2] == 0x33) {
    final size =
        (head[6] & 0x7F) << 21 |
        (head[7] & 0x7F) << 14 |
        (head[8] & 0x7F) << 7 |
        (head[9] & 0x7F);
    final footer = (head[5] & 0x10) != 0 ? 10 : 0;
    return 10 + size + footer;
  }
  return 0;
}

class _Mp3Header {
  const _Mp3Header({
    required this.channelMode,
    required this.sampleRate,
    required this.bitrate,
    required this.samplesPerFrame,
    required this.versionId,
  });
  final int channelMode;
  final int sampleRate;
  final int bitrate; // kbps
  final int samplesPerFrame;
  final int versionId;
}

_Mp3Header? _parseHeader(Uint8List buf, int i) {
  final b1 = buf[i + 1];
  final b2 = buf[i + 2];
  final b3 = buf[i + 3];

  final versionId = (b1 >> 3) & 0x3; // 3=MPEG1, 2=MPEG2, 0=MPEG2.5, 1=reserved
  final layerId = (b1 >> 1) & 0x3; // 1=III, 2=II, 3=I, 0=reserved
  if (versionId == 1 || layerId == 0) return null;

  final bitrateIndex = (b2 >> 4) & 0xF;
  final sampleRateIndex = (b2 >> 2) & 0x3;
  if (bitrateIndex == 0 || bitrateIndex == 15 || sampleRateIndex == 3) {
    return null;
  }

  final mpeg1 = versionId == 3;
  final layer = 4 - layerId; // 1=LayerI, 2=LayerII, 3=LayerIII
  final bitrate = _bitrate(mpeg1, layer, bitrateIndex);
  final sampleRate = _sampleRate(versionId, sampleRateIndex);
  if (bitrate <= 0 || sampleRate <= 0) return null;

  final samplesPerFrame = layer == 1
      ? 384
      : layer == 2
      ? 1152
      : (mpeg1 ? 1152 : 576);

  return _Mp3Header(
    channelMode: (b3 >> 6) & 0x3,
    sampleRate: sampleRate,
    bitrate: bitrate,
    samplesPerFrame: samplesPerFrame,
    versionId: versionId,
  );
}

int _bitrate(bool mpeg1, int layer, int index) {
  const m1l1 = [
    0,
    32,
    64,
    96,
    128,
    160,
    192,
    224,
    256,
    288,
    320,
    352,
    384,
    416,
    448,
  ];
  const m1l2 = [
    0,
    32,
    48,
    56,
    64,
    80,
    96,
    112,
    128,
    160,
    192,
    224,
    256,
    320,
    384,
  ];
  const m1l3 = [
    0,
    32,
    40,
    48,
    56,
    64,
    80,
    96,
    112,
    128,
    160,
    192,
    224,
    256,
    320,
  ];
  const m2l1 = [
    0,
    32,
    48,
    56,
    64,
    80,
    96,
    112,
    128,
    144,
    160,
    176,
    192,
    224,
    256,
  ];
  const m2l23 = [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160];
  if (mpeg1) {
    if (layer == 1) return m1l1[index];
    if (layer == 2) return m1l2[index];
    return m1l3[index];
  }
  if (layer == 1) return m2l1[index];
  return m2l23[index];
}

int _sampleRate(int versionId, int index) {
  const mpeg1 = [44100, 48000, 32000];
  const mpeg2 = [22050, 24000, 16000];
  const mpeg25 = [11025, 12000, 8000];
  if (versionId == 3) return mpeg1[index];
  if (versionId == 2) return mpeg2[index];
  return mpeg25[index];
}

int _xingTagOffset(_Mp3Header h) {
  final mono = h.channelMode == 3;
  if (h.versionId == 3) return mono ? 21 : 36; // MPEG1
  return mono ? 13 : 21; // MPEG2 / 2.5
}

int? _xingFrameCount(Uint8List buf, int off) {
  if (off < 0 || off + 12 > buf.length) return null;
  final tag = String.fromCharCodes(buf, off, off + 4);
  if (tag != 'Xing' && tag != 'Info') return null;
  final bd = ByteData.sublistView(buf);
  final flags = bd.getUint32(off + 4);
  if ((flags & 0x1) == 0) return null; // frame count not present
  return bd.getUint32(off + 8);
}

Future<bool> _hasId3v1(FileSource source) async {
  final total = source.length;
  if (total < 128) return false;
  final tail = await source.readRange(total - 128, total);
  return tail.length >= 3 &&
      tail[0] == 0x54 &&
      tail[1] == 0x41 &&
      tail[2] == 0x47; // 'TAG'
}
