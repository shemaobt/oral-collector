import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/platform/file_source.dart';
import 'package:oral_collector/features/recording/data/services/audio_metadata/mp4_box_probe.dart';
import 'package:oral_collector/features/recording/data/services/audio_probe.dart';

List<int> ascii(String s) => s.codeUnits;

List<int> u16be(int v) => [(v >> 8) & 0xFF, v & 0xFF];

List<int> u32be(int v) => [
  (v >> 24) & 0xFF,
  (v >> 16) & 0xFF,
  (v >> 8) & 0xFF,
  v & 0xFF,
];

List<int> u64be(int v) => [
  (v >> 56) & 0xFF,
  (v >> 48) & 0xFF,
  (v >> 40) & 0xFF,
  (v >> 32) & 0xFF,
  (v >> 24) & 0xFF,
  (v >> 16) & 0xFF,
  (v >> 8) & 0xFF,
  v & 0xFF,
];

List<int> box(String type, List<int> payload) => [
  ...u32be(8 + payload.length),
  ...ascii(type),
  ...payload,
];

/// Box that uses the 64-bit `largesize` form (32-bit size field == 1).
List<int> boxLarge(String type, List<int> payload) => [
  ...u32be(1),
  ...ascii(type),
  ...u64be(16 + payload.length),
  ...payload,
];

List<int> mvhd({
  required int timescale,
  required int duration,
  int version = 0,
}) {
  if (version == 1) {
    return box('mvhd', [
      1, 0, 0, 0, // version + flags
      ...u64be(0), // creation time
      ...u64be(0), // modification time
      ...u32be(timescale),
      ...u64be(duration),
      ...List<int>.filled(80, 0), // rate/volume/matrix/etc.
    ]);
  }
  return box('mvhd', [
    0, 0, 0, 0, // version + flags
    ...u32be(0), // creation time
    ...u32be(0), // modification time
    ...u32be(timescale),
    ...u32be(duration),
    ...List<int>.filled(80, 0),
  ]);
}

List<int> stsd(String codec) {
  final entry = [
    ...u32be(36), // sample entry size
    ...ascii(codec), // data format (fourcc)
    ...List<int>.filled(28, 0), // remainder of the audio sample entry
  ];
  return box('stsd', [
    0, 0, 0, 0, // version + flags
    ...u32be(1), // entry count
    ...entry,
  ]);
}

List<int> mdhdBox({required int timescale, required int duration}) =>
    box('mdhd', [
      0, 0, 0, 0, // version + flags
      ...u32be(0), // creation time
      ...u32be(0), // modification time
      ...u32be(timescale),
      ...u32be(duration),
      ...u16be(0), // language
      ...u16be(0), // quality
    ]);

List<int> trak(String codec, {List<int> mdhd = const []}) {
  final stbl = box('stbl', stsd(codec));
  final minf = box('minf', stbl);
  final mdia = box('mdia', [...mdhd, ...minf]);
  return box('trak', mdia);
}

List<int> moov({
  required int timescale,
  required int duration,
  required String codec,
  int version = 0,
  int? mdhdTimescale,
  int? mdhdDuration,
}) => box('moov', [
  ...mvhd(timescale: timescale, duration: duration, version: version),
  ...trak(
    codec,
    mdhd: mdhdTimescale != null
        ? mdhdBox(timescale: mdhdTimescale, duration: mdhdDuration ?? 0)
        : const [],
  ),
]);

Uint8List buildMp4({
  required int timescale,
  required int duration,
  String codec = 'mp4a',
  int version = 0,
  bool moovAtEnd = true,
  int mdatSize = 64,
  bool largeMdat = false,
  int? mdhdTimescale,
  int? mdhdDuration,
}) {
  final ftyp = box('ftyp', [...ascii('isom'), ...u32be(512), ...ascii('isom')]);
  final moovBytes = moov(
    timescale: timescale,
    duration: duration,
    codec: codec,
    version: version,
    mdhdTimescale: mdhdTimescale,
    mdhdDuration: mdhdDuration,
  );
  final mdatPayload = List<int>.filled(mdatSize, 0);
  final mdatBytes = largeMdat
      ? boxLarge('mdat', mdatPayload)
      : box('mdat', mdatPayload);

  final out = <int>[...ftyp];
  if (moovAtEnd) {
    out
      ..addAll(mdatBytes)
      ..addAll(moovBytes);
  } else {
    out
      ..addAll(moovBytes)
      ..addAll(mdatBytes);
  }
  return Uint8List.fromList(out);
}

void main() {
  group('probeMp4Duration', () {
    test('reads duration from a moov at the end of the file', () async {
      // Mirrors a real Samsung recording: timescale 10000, ~2h42m.
      final bytes = buildMp4(timescale: 10000, duration: 97450851);
      final source = FileSource.fromBytes(bytes, name: 'rec.m4a');

      final result = await probeMp4Duration(source);

      expect(result, isNotNull);
      expect(result!.durationSeconds, closeTo(9745.085, 0.01));
      expect(result.codec, 'mp4a');
      expect(result.playable, isTrue);
    });

    test('reads duration from a moov at the front of the file', () async {
      final bytes = buildMp4(
        timescale: 48000,
        duration: 48000 * 30,
        moovAtEnd: false,
      );
      final result = await probeMp4Duration(
        FileSource.fromBytes(bytes, name: 'front.m4a'),
      );

      expect(result!.durationSeconds, closeTo(30.0, 1e-6));
      expect(result.playable, isTrue);
    });

    test('reads duration from an mvhd version 1 (64-bit fields)', () async {
      final bytes = buildMp4(timescale: 1000, duration: 3661000, version: 1);
      final result = await probeMp4Duration(
        FileSource.fromBytes(bytes, name: 'v1.m4a'),
      );

      expect(result!.durationSeconds, closeTo(3661.0, 1e-6));
    });

    test('finds a moov located after an mdat larger than 5 MB', () async {
      final bytes = buildMp4(
        timescale: 1000,
        duration: 60000,
        mdatSize: 6 * 1024 * 1024,
      );
      final result = await probeMp4Duration(
        FileSource.fromBytes(bytes, name: 'big.m4a'),
      );

      expect(result!.durationSeconds, closeTo(60.0, 1e-6));
      expect(result.codec, 'mp4a');
    });

    test('handles a box using the 64-bit largesize header', () async {
      final bytes = buildMp4(timescale: 1000, duration: 5000, largeMdat: true);
      final result = await probeMp4Duration(
        FileSource.fromBytes(bytes, name: 'large.m4a'),
      );

      expect(result!.durationSeconds, closeTo(5.0, 1e-6));
    });

    test('falls back to the track header when mvhd duration is zero', () async {
      // Some encoders leave the movie-header duration at 0; the real duration
      // then lives only in the track media header (mdhd).
      final bytes = buildMp4(
        timescale: 1000,
        duration: 0,
        mdhdTimescale: 8000,
        mdhdDuration: 8000 * 42,
      );
      final result = await probeMp4Duration(
        FileSource.fromBytes(bytes, name: 'mdhd.m4a'),
      );

      expect(result!.durationSeconds, closeTo(42.0, 1e-6));
    });

    test('reports a non-browser-playable codec without a duration', () async {
      // ALAC plays natively but not in a browser: surface the codec so the
      // caller can fall back to the player, but do not claim a duration.
      final bytes = buildMp4(timescale: 1000, duration: 5000, codec: 'alac');
      final result = await probeMp4Duration(
        FileSource.fromBytes(bytes, name: 'lossless.m4a'),
      );

      expect(result, isNotNull);
      expect(result!.codec, 'alac');
      expect(result.playable, isFalse);
      expect(result.hasDuration, isFalse);
    });

    test('returns null when the bytes are not an MP4 container', () async {
      final bytes = Uint8List.fromList(
        ascii('OggS') + List<int>.filled(200, 0),
      );
      final result = await probeMp4Duration(
        FileSource.fromBytes(bytes, name: 'notmp4.m4a'),
      );

      expect(result, isNull);
    });
  });

  group('AudioProbe.probeFromSource for m4a', () {
    const probe = AudioProbe();

    test('accepts an AAC m4a using the moov, without the player', () async {
      // A large mdat keeps the moov well past any slice the player would read.
      final bytes = buildMp4(
        timescale: 48000,
        duration: 48000 * 12,
        mdatSize: 6 * 1024 * 1024,
      );
      final source = FileSource.fromBytes(bytes, name: 'voice.m4a');

      final result = await probe.probeFromSource(
        source: source,
        extension: 'm4a',
        mime: 'audio/mp4',
      );

      expect(result.hasDuration, isTrue);
      expect(result.durationSeconds, closeTo(12.0, 1e-6));
      expect(result.codec, 'mp4a');
      expect(result.playable, isTrue);
    });

    test('does not accept a non-playable codec via the header path', () async {
      final bytes = buildMp4(timescale: 1000, duration: 5000, codec: 'alac');
      final source = FileSource.fromBytes(bytes, name: 'lossless.m4a');

      final result = await probe.probeFromSource(
        source: source,
        extension: 'm4a',
        mime: 'audio/mp4',
      );

      expect(result.codec, 'alac');
      expect(result.hasDuration, isFalse);
    });
  });
}
