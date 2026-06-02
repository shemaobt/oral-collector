import 'dart:typed_data';

import '../../../../../core/platform/file_source.dart';
import '../audio_probe_result.dart';

/// Audio codecs a browser can decode straight from an MP4/M4A container.
const Set<String> _browserPlayableMp4Codecs = {'mp4a', 'Opus', '.mp3'};

const int _maxMoovBytes = 64 * 1024 * 1024;
const int _maxTopLevelBoxes = 64;

/// Extracts duration and audio codec from an MP4/M4A (ISO-BMFF) container by
/// reading only the `moov` box, wherever it sits in the file (front or end).
///
/// Returns null when the bytes are not a parseable MP4. For a codec the browser
/// cannot decode, the codec is reported without a duration so the caller can
/// fall back to the platform player (which may decode it natively).
Future<AudioProbeResult?> probeMp4Duration(FileSource source) async {
  final moov = await _readMoovPayload(source);
  if (moov == null) return null;

  var seconds = _findMovieHeaderDuration(moov, const ['mvhd']);
  // A zero/absent movie-header duration happens; fall back to the track header.
  if (seconds == null || seconds <= 0) {
    seconds = _findMovieHeaderDuration(moov, const ['trak', 'mdia', 'mdhd']);
  }
  if (seconds == null || seconds <= 0) return null;

  final codec = _audioCodec(moov);
  final playable = codec != null && _browserPlayableMp4Codecs.contains(codec);
  if (!playable) {
    return AudioProbeResult(
      codec: codec,
      playable: false,
      diagnostic: 'mp4_box: codec=${codec ?? "unknown"} not browser-playable',
    );
  }

  return AudioProbeResult(
    durationSeconds: seconds,
    codec: codec,
    playable: true,
    diagnostic: 'mp4_box ok',
  );
}

class _BoxLoc {
  const _BoxLoc(this.payloadStart, this.payloadEnd);
  final int payloadStart;
  final int payloadEnd;
}

/// Walks top-level boxes with ranged reads and returns the `moov` box payload.
Future<Uint8List?> _readMoovPayload(FileSource source) async {
  final total = source.length;
  var pos = 0;
  for (var i = 0; i < _maxTopLevelBoxes && pos + 8 <= total; i++) {
    final headEnd = pos + 16 <= total ? pos + 16 : total;
    final header = await source.readRange(pos, headEnd);
    if (header.length < 8) return null;
    final bd = ByteData.sublistView(header);

    var size = bd.getUint32(0);
    final type = String.fromCharCodes(header, 4, 8);
    var headerSize = 8;
    if (size == 1) {
      if (header.length < 16) return null;
      size = _u64(bd, 8);
      headerSize = 16;
    } else if (size == 0) {
      size = total - pos;
    }
    if (size < headerSize) return null;

    if (type == 'moov') {
      final payloadStart = pos + headerSize;
      final payloadEnd = pos + size <= total ? pos + size : total;
      final length = payloadEnd - payloadStart;
      if (length <= 0 || length > _maxMoovBytes) return null;
      return source.readRange(payloadStart, payloadEnd);
    }
    pos += size;
  }
  return null;
}

double? _findMovieHeaderDuration(Uint8List moov, List<String> path) {
  final loc = _findBoxPath(moov, 0, moov.length, path);
  if (loc == null) return null;
  return _movieHeaderDuration(moov, loc.payloadStart);
}

_BoxLoc? _findBoxPath(Uint8List buf, int start, int end, List<String> path) {
  var rangeStart = start;
  var rangeEnd = end;
  _BoxLoc? found;
  for (final wanted in path) {
    found = _findBox(buf, rangeStart, rangeEnd, wanted);
    if (found == null) return null;
    rangeStart = found.payloadStart;
    rangeEnd = found.payloadEnd;
  }
  return found;
}

_BoxLoc? _findBox(Uint8List buf, int start, int end, String wanted) {
  final bd = ByteData.sublistView(buf);
  var pos = start;
  while (pos + 8 <= end) {
    var size = bd.getUint32(pos);
    final type = String.fromCharCodes(buf, pos + 4, pos + 8);
    var headerSize = 8;
    if (size == 1) {
      if (pos + 16 > end) return null;
      size = _u64(bd, pos + 8);
      headerSize = 16;
    } else if (size == 0) {
      size = end - pos;
    }
    if (size < headerSize) return null;
    final boxEnd = pos + size;
    if (boxEnd > end) return null;
    if (type == wanted) return _BoxLoc(pos + headerSize, boxEnd);
    pos = boxEnd;
  }
  return null;
}

/// Reads timescale/duration from an `mvhd` or `mdhd` payload (identical layout
/// for these fields). `duration / timescale` gives seconds.
double? _movieHeaderDuration(Uint8List buf, int payloadStart) {
  if (payloadStart + 4 > buf.length) return null;
  final bd = ByteData.sublistView(buf);
  final version = buf[payloadStart];

  final int timescale;
  final int duration;
  if (version == 1) {
    final tsOff = payloadStart + 4 + 8 + 8; // version+flags, creation, mod
    if (tsOff + 12 > buf.length) return null;
    timescale = bd.getUint32(tsOff);
    duration = _u64(bd, tsOff + 4);
  } else {
    final tsOff = payloadStart + 4 + 4 + 4;
    if (tsOff + 8 > buf.length) return null;
    timescale = bd.getUint32(tsOff);
    duration = bd.getUint32(tsOff + 4);
  }
  if (timescale == 0) return null;
  return duration / timescale;
}

// Codec of the first track's sample description. M4A is audio-only, so the
// first trak is the audio track (mvhd duration above covers the whole movie).
String? _audioCodec(Uint8List moov) {
  final stsd = _findBoxPath(moov, 0, moov.length, const [
    'trak',
    'mdia',
    'minf',
    'stbl',
    'stsd',
  ]);
  if (stsd == null) return null;
  // stsd payload: version+flags(4) + entry_count(4) + first sample entry,
  // whose layout is size(4) + data format fourcc(4).
  final entryStart = stsd.payloadStart + 8;
  if (entryStart + 8 > moov.length) return null;
  return String.fromCharCodes(moov, entryStart + 4, entryStart + 8);
}

/// Reads a 64-bit big-endian value as two 32-bit halves so it works on the web
/// (dart2js has no native 64-bit ints / ByteData.getUint64).
int _u64(ByteData bd, int offset) =>
    bd.getUint32(offset) * 0x100000000 + bd.getUint32(offset + 4);
