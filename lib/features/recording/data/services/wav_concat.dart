import 'dart:io';
import 'dart:typed_data';

/// Concatenates PCM WAV segments by stitching the raw `data` chunk of each
/// onto the first segment's header.
///
/// Assumes **canonical PCM WAV** with a 44-byte header: `RIFF`/file-size/`WAVE`
/// + `fmt ` chunk of 16 bytes + `data` chunk header. The `record` package
/// produces files matching this layout. Files with extra header chunks (LIST,
/// JUNK, fact, …) will be rejected by [_looksLikeWav] or produce a garbled
/// output — this concatenator is intentionally a last-resort fallback for
/// when FFmpeg-based concat is unavailable.
///
/// Segments whose `fmt` chunk (sample rate, bit depth, channel count) does
/// not match the first segment are skipped to avoid producing audio that
/// switches format mid-stream.
Future<bool> concatWavFilesInDart({
  required List<String> segments,
  required String outputPath,
}) async {
  if (segments.isEmpty) return false;

  final firstFile = File(segments.first);
  if (!await firstFile.exists()) return false;

  final firstBytes = await firstFile.readAsBytes();
  if (!_looksLikeWav(firstBytes)) return false;

  final header = Uint8List.fromList(firstBytes.sublist(0, 44));
  final referenceFmt = _fmtChunkBytes(firstBytes);
  final pcm = BytesBuilder();
  pcm.add(firstBytes.sublist(44));

  for (var i = 1; i < segments.length; i++) {
    final file = File(segments[i]);
    if (!await file.exists()) continue;
    final bytes = await file.readAsBytes();
    if (!_looksLikeWav(bytes)) continue;
    if (!_listEquals(_fmtChunkBytes(bytes), referenceFmt)) continue;
    pcm.add(bytes.sublist(44));
  }

  final pcmBytes = pcm.toBytes();
  final headerView = ByteData.view(header.buffer);
  headerView.setUint32(4, pcmBytes.length + 36, Endian.little);
  headerView.setUint32(40, pcmBytes.length, Endian.little);

  final out = BytesBuilder();
  out.add(header);
  out.add(pcmBytes);
  await File(outputPath).writeAsBytes(out.toBytes(), flush: true);
  return true;
}

bool _looksLikeWav(Uint8List bytes) {
  if (bytes.length < 44) return false;
  if (String.fromCharCodes(bytes.sublist(0, 4)) != 'RIFF') return false;
  if (String.fromCharCodes(bytes.sublist(8, 12)) != 'WAVE') return false;
  return true;
}

/// The 16 bytes of the canonical PCM fmt chunk body (audioFormat, channels,
/// sampleRate, byteRate, blockAlign, bitsPerSample). Bytes 20..36 in a
/// canonical-PCM file.
Uint8List _fmtChunkBytes(Uint8List bytes) =>
    Uint8List.fromList(bytes.sublist(20, 36));

bool _listEquals(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
