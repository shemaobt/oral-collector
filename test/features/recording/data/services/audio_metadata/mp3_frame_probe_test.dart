import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/platform/file_source.dart';
import 'package:oral_collector/features/recording/data/services/audio_metadata/mp3_frame_probe.dart';

List<int> ascii(String s) => s.codeUnits;

List<int> u32be(int v) => [
  (v >> 24) & 0xFF,
  (v >> 16) & 0xFF,
  (v >> 8) & 0xFF,
  v & 0xFF,
];

List<int> syncsafe(int v) => [
  (v >> 21) & 0x7F,
  (v >> 14) & 0x7F,
  (v >> 7) & 0x7F,
  v & 0x7F,
];

/// Builds a 4-byte MPEG audio frame header.
/// versionId: 3=MPEG1, 2=MPEG2, 0=MPEG2.5. layerId: 1=LayerIII, 2=II, 3=I.
/// channelMode: 3=mono, else stereo-ish.
List<int> frameHeader({
  required int versionId,
  required int layerId,
  required int bitrateIndex,
  required int sampleRateIndex,
  int channelMode = 3,
}) {
  final b1 = 0xE0 | (versionId << 3) | (layerId << 1) | 1; // no CRC
  final b2 = (bitrateIndex << 4) | (sampleRateIndex << 2);
  final b3 = channelMode << 6;
  return [0xFF, b1, b2, b3];
}

int _xingOffset(int versionId, int channelMode) {
  final mono = channelMode == 3;
  if (versionId == 3) return mono ? 21 : 36; // MPEG1
  return mono ? 13 : 21; // MPEG2 / 2.5
}

Uint8List buildMp3Xing({
  required int frames,
  int versionId = 3,
  int layerId = 1,
  int bitrateIndex = 9,
  int sampleRateIndex = 0,
  int channelMode = 3,
  List<int> id3 = const [],
}) {
  final body = Uint8List(417);
  body.setRange(
    0,
    4,
    frameHeader(
      versionId: versionId,
      layerId: layerId,
      bitrateIndex: bitrateIndex,
      sampleRateIndex: sampleRateIndex,
      channelMode: channelMode,
    ),
  );
  final off = _xingOffset(versionId, channelMode);
  body.setRange(off, off + 4, ascii('Xing'));
  body.setRange(off + 4, off + 8, u32be(1)); // flags: frames field present
  body.setRange(off + 8, off + 12, u32be(frames));
  return Uint8List.fromList([...id3, ...body]);
}

Uint8List buildMp3Cbr({
  required int totalBytes,
  int versionId = 3,
  int layerId = 1,
  int bitrateIndex = 9,
  int sampleRateIndex = 0,
}) {
  final buf = Uint8List(totalBytes);
  buf.setRange(
    0,
    4,
    frameHeader(
      versionId: versionId,
      layerId: layerId,
      bitrateIndex: bitrateIndex,
      sampleRateIndex: sampleRateIndex,
    ),
  );
  return buf;
}

List<int> id3v2(int contentSize) => [
  ...ascii('ID3'),
  0x04, 0x00, // version
  0x00, // flags
  ...syncsafe(contentSize),
  ...List<int>.filled(contentSize, 0),
];

void main() {
  group('probeMp3Duration', () {
    test('reads total duration from a Xing VBR header', () async {
      // MPEG1 Layer III: 1152 samples/frame at 44100 Hz.
      final bytes = buildMp3Xing(frames: 1000);
      final source = FileSource.fromBytes(bytes, name: 'vbr.mp3');

      final result = await probeMp3Duration(source);

      expect(result, isNotNull);
      expect(result!.durationSeconds, closeTo(1000 * 1152 / 44100, 1e-3));
      expect(result.codec, 'mp3');
      expect(result.playable, isTrue);
    });

    test('computes CBR duration from file size and bitrate', () async {
      // 128 kbps; 128000 bytes => 8.0 s.
      final bytes = buildMp3Cbr(totalBytes: 128000);
      final source = FileSource.fromBytes(bytes, name: 'cbr.mp3');

      final result = await probeMp3Duration(source);

      expect(result!.durationSeconds, closeTo(8.0, 0.05));
      expect(result.codec, 'mp3');
    });

    test('skips an ID3v2 tag before the first frame', () async {
      final bytes = buildMp3Xing(frames: 500, id3: id3v2(120));
      final source = FileSource.fromBytes(bytes, name: 'tagged.mp3');

      final result = await probeMp3Duration(source);

      expect(result!.durationSeconds, closeTo(500 * 1152 / 44100, 1e-3));
    });

    test('handles MPEG2 frames (576 samples/frame)', () async {
      // MPEG2 Layer III at 22050 Hz.
      final bytes = buildMp3Xing(frames: 800, versionId: 2, sampleRateIndex: 0);
      final source = FileSource.fromBytes(bytes, name: 'mpeg2.mp3');

      final result = await probeMp3Duration(source);

      expect(result!.durationSeconds, closeTo(800 * 576 / 22050, 1e-3));
    });

    test('returns null for non-MP3 bytes', () async {
      final bytes = Uint8List.fromList(
        ascii('OggS') + List<int>.filled(400, 0),
      );
      final result = await probeMp3Duration(
        FileSource.fromBytes(bytes, name: 'x.mp3'),
      );

      expect(result, isNull);
    });
  });
}
