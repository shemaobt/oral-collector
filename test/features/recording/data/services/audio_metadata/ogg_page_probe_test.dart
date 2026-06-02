import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/platform/file_source.dart';
import 'package:oral_collector/features/recording/data/services/audio_metadata/ogg_page_probe.dart';

List<int> ascii(String s) => s.codeUnits;

List<int> u16le(int v) => [v & 0xFF, (v >> 8) & 0xFF];

List<int> u32le(int v) => [
  v & 0xFF,
  (v >> 8) & 0xFF,
  (v >> 16) & 0xFF,
  (v >> 24) & 0xFF,
];

List<int> u64le(int v) {
  final out = <int>[];
  var x = v;
  for (var i = 0; i < 8; i++) {
    out.add(x & 0xFF);
    x = x >> 8;
  }
  return out;
}

List<int> oggPage({
  int granule = 0,
  List<int>? granuleBytes,
  required List<int> data,
  int headerType = 0,
  int seq = 0,
}) {
  final segs = <int>[];
  var rem = data.length;
  while (rem >= 255) {
    segs.add(255);
    rem -= 255;
  }
  segs.add(rem);
  return [
    ...ascii('OggS'),
    0, // version
    headerType,
    ...(granuleBytes ?? u64le(granule)),
    ...u32le(0), // serial
    ...u32le(seq),
    ...u32le(0), // crc
    segs.length,
    ...segs,
    ...data,
  ];
}

List<int> vorbisIdHeader(int sampleRate, {int channels = 1}) => [
  0x01,
  ...ascii('vorbis'),
  ...u32le(0), // vorbis version
  channels,
  ...u32le(sampleRate),
  ...List<int>.filled(16, 0),
];

List<int> opusHead(int inputSampleRate, {int channels = 1, int preSkip = 0}) =>
    [
      ...ascii('OpusHead'),
      1, // version
      channels,
      ...u16le(preSkip),
      ...u32le(inputSampleRate),
      ...u16le(0), // output gain
      0, // channel mapping family
    ];

Uint8List buildOgg(List<int> idHeader, {required int finalGranule}) {
  final first = oggPage(granule: 0, data: idHeader, headerType: 2);
  final mid = oggPage(
    granule: finalGranule ~/ 2,
    data: List<int>.filled(40, 0),
    seq: 1,
  );
  final last = oggPage(
    granule: finalGranule,
    data: List<int>.filled(40, 0),
    headerType: 4,
    seq: 2,
  );
  return Uint8List.fromList([...first, ...mid, ...last]);
}

void main() {
  group('probeOggDuration', () {
    test('reads Vorbis duration from the final page granule', () async {
      // 48000 Hz, 480000 samples => 10 s.
      final bytes = buildOgg(vorbisIdHeader(48000), finalGranule: 480000);
      final source = FileSource.fromBytes(bytes, name: 'sound.ogg');

      final result = await probeOggDuration(source);

      expect(result, isNotNull);
      expect(result!.durationSeconds, closeTo(10.0, 1e-6));
      expect(result.codec, 'vorbis');
      expect(result.playable, isTrue);
    });

    test('reads Opus duration using the fixed 48 kHz granule rate', () async {
      // Opus granule is always at 48 kHz regardless of the input sample rate.
      final bytes = buildOgg(opusHead(16000), finalGranule: 48000 * 3);
      final source = FileSource.fromBytes(bytes, name: 'voice.ogg');

      final result = await probeOggDuration(source);

      expect(result!.durationSeconds, closeTo(3.0, 1e-6));
      expect(result.codec, 'opus');
    });

    test(
      'skips a trailing page that completed no packet (granule -1)',
      () async {
        // A continuation page with an all-ones granule must be ignored; the real
        // duration is on the preceding page.
        final base = buildOgg(vorbisIdHeader(48000), finalGranule: 48000 * 4);
        final sentinel = oggPage(
          granuleBytes: List<int>.filled(8, 0xFF),
          data: List<int>.filled(20, 0),
          seq: 3,
        );
        final source = FileSource.fromBytes(
          Uint8List.fromList([...base, ...sentinel]),
          name: 'sentinel.ogg',
        );

        final result = await probeOggDuration(source);

        expect(result!.durationSeconds, closeTo(4.0, 1e-6));
      },
    );

    test('returns null for non-OGG bytes', () async {
      final bytes = Uint8List.fromList(
        ascii('RIFF') + List<int>.filled(200, 0),
      );
      final result = await probeOggDuration(
        FileSource.fromBytes(bytes, name: 'x.ogg'),
      );

      expect(result, isNull);
    });
  });
}
