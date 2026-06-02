import 'dart:typed_data';

import '../../../../../core/platform/file_source.dart';
import '../audio_probe_result.dart';

const int _tailWindow = 64 * 1024;

/// Extracts duration from an Ogg (Vorbis/Opus) stream: the codec and sample rate
/// come from the identification header in the first page, and the total sample
/// count comes from the `granule_position` of the last page (read from the tail
/// so large files are not loaded whole). Ogg fields are little-endian. Returns
/// null when the bytes are not a recognised Ogg audio stream.
Future<AudioProbeResult?> probeOggDuration(FileSource source) async {
  final total = source.length;
  if (total < 28) return null;

  final head = await source.readHead(total < 256 ? total : 256);
  if (!_isOggS(head, 0)) return null;
  final dataStart = 27 + head[26]; // header + segment table
  final info = _identify(head, dataStart);
  if (info == null) return null;

  final tailLen = total < _tailWindow ? total : _tailWindow;
  final tail = await source.readRange(total - tailLen, total);
  final granule = _lastGranule(tail);
  if (granule == null || granule <= 0) return null;

  final seconds = granule / info.granuleRate;
  if (seconds <= 0) return null;
  return AudioProbeResult(
    durationSeconds: seconds,
    codec: info.codec,
    playable: true,
    diagnostic: 'ogg_page ok',
  );
}

class _OggInfo {
  const _OggInfo(this.codec, this.granuleRate);
  final String codec;
  final int granuleRate;
}

_OggInfo? _identify(Uint8List buf, int dataStart) {
  if (dataStart < 0 || dataStart + 16 > buf.length) return null;
  if (buf[dataStart] == 0x01 &&
      String.fromCharCodes(buf, dataStart + 1, dataStart + 7) == 'vorbis') {
    final sr = ByteData.sublistView(
      buf,
    ).getUint32(dataStart + 12, Endian.little);
    if (sr <= 0) return null;
    return _OggInfo('vorbis', sr);
  }
  if (dataStart + 8 <= buf.length &&
      String.fromCharCodes(buf, dataStart, dataStart + 8) == 'OpusHead') {
    return const _OggInfo('opus', 48000); // Opus granule is always 48 kHz
  }
  return null;
}

bool _isOggS(Uint8List b, int o) =>
    o + 4 <= b.length &&
    b[o] == 0x4F &&
    b[o + 1] == 0x67 &&
    b[o + 2] == 0x67 &&
    b[o + 3] == 0x53;

int? _lastGranule(Uint8List tail) {
  final bd = ByteData.sublistView(tail);
  for (var i = tail.length - 27; i >= 0; i--) {
    if (!_isOggS(tail, i) || tail[i + 4] != 0) continue;
    final lo = bd.getUint32(i + 6, Endian.little);
    final hi = bd.getUint32(i + 10, Endian.little);
    // 0xFFFFFFFFFFFFFFFF marks a page with no completed packet; skip it.
    if (hi == 0xFFFFFFFF && lo == 0xFFFFFFFF) continue;
    return hi * 0x100000000 + lo;
  }
  return null;
}
