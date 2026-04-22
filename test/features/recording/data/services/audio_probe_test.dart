import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/data/services/audio_probe.dart';

Uint8List buildWavHeader({
  required int formatTag,
  required int channels,
  required int sampleRate,
  required int bitsPerSample,
  required int dataSize,
  int? byteRateOverride,
  int? extraFmtBytes,
}) {
  final fmtChunkSize = 16 + (extraFmtBytes ?? 0);
  final byteRate =
      byteRateOverride ?? sampleRate * channels * bitsPerSample ~/ 8;
  final blockAlign = channels * bitsPerSample ~/ 8;
  final totalSize = 4 + (8 + fmtChunkSize) + (8 + dataSize);

  final buffer = BytesBuilder();
  buffer.add(ascii('RIFF'));
  buffer.add(u32le(totalSize));
  buffer.add(ascii('WAVE'));

  buffer.add(ascii('fmt '));
  buffer.add(u32le(fmtChunkSize));
  buffer.add(u16le(formatTag));
  buffer.add(u16le(channels));
  buffer.add(u32le(sampleRate));
  buffer.add(u32le(byteRate));
  buffer.add(u16le(blockAlign));
  buffer.add(u16le(bitsPerSample));
  if (extraFmtBytes != null && extraFmtBytes > 0) {
    buffer.add(List<int>.filled(extraFmtBytes, 0));
  }

  buffer.add(ascii('data'));
  buffer.add(u32le(dataSize));

  return buffer.toBytes();
}

List<int> ascii(String s) => s.codeUnits;

List<int> u16le(int value) {
  return [value & 0xFF, (value >> 8) & 0xFF];
}

List<int> u32le(int value) {
  return [
    value & 0xFF,
    (value >> 8) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 24) & 0xFF,
  ];
}

void main() {
  group('AudioProbe WAV header', () {
    const probe = AudioProbe();

    test('accepts 16-bit mono PCM and computes duration', () async {
      final sampleRate = 16000;
      final channels = 1;
      final bitsPerSample = 16;
      final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
      final dataSize = byteRate * 5;

      final header = buildWavHeader(
        formatTag: 0x0001,
        channels: channels,
        sampleRate: sampleRate,
        bitsPerSample: bitsPerSample,
        dataSize: dataSize,
      );

      final result = await probe.probe(
        bytes: header,
        filePath: null,
        extension: 'wav',
        mime: 'audio/wav',
      );

      expect(result.hasDuration, isTrue);
      expect(result.durationSeconds, closeTo(5.0, 1e-6));
      expect(result.codec, 'pcm');
      expect(result.playable, isTrue);
    });

    test('accepts IEEE float and marks playable', () async {
      final header = buildWavHeader(
        formatTag: 0x0003,
        channels: 2,
        sampleRate: 44100,
        bitsPerSample: 32,
        dataSize: 44100 * 2 * 4,
      );
      final result = await probe.probe(
        bytes: header,
        filePath: null,
        extension: 'wav',
        mime: 'audio/wav',
      );
      expect(result.hasDuration, isTrue);
      expect(result.codec, 'ieee_float');
      expect(result.playable, isTrue);
    });

    test('µ-law WAV gets duration but marked not playable', () async {
      final sampleRate = 8000;
      final channels = 1;
      final byteRate = sampleRate * channels;
      final dataSize = byteRate * 3;

      final header = buildWavHeader(
        formatTag: 0x0007,
        channels: channels,
        sampleRate: sampleRate,
        bitsPerSample: 8,
        dataSize: dataSize,
      );
      final result = await probe.probe(
        bytes: header,
        filePath: null,
        extension: 'wav',
        mime: 'audio/wav',
      );
      expect(result.durationSeconds, closeTo(3.0, 1e-6));
      expect(result.codec, 'mulaw');
      expect(result.playable, isFalse);
    });

    test('A-law WAV gets duration but marked not playable', () async {
      final header = buildWavHeader(
        formatTag: 0x0006,
        channels: 1,
        sampleRate: 8000,
        bitsPerSample: 8,
        dataSize: 8000 * 2,
      );
      final result = await probe.probe(
        bytes: header,
        filePath: null,
        extension: 'wav',
        mime: 'audio/wav',
      );
      expect(result.durationSeconds, closeTo(2.0, 1e-6));
      expect(result.codec, 'alaw');
      expect(result.playable, isFalse);
    });

    test('truncated header falls through', () async {
      final header = Uint8List.fromList(
        ascii('RIFF') + u32le(0) + ascii('WAVE'),
      );
      final result = await probe.probe(
        bytes: header,
        filePath: null,
        extension: 'wav',
        mime: 'audio/wav',
      );
      expect(result.hasDuration, isFalse);
    });

    test('RF64 sentinel (0xFFFFFFFF data size) falls through', () async {
      final header = buildWavHeader(
        formatTag: 0x0001,
        channels: 1,
        sampleRate: 48000,
        bitsPerSample: 16,
        dataSize: 0xFFFFFFFF,
      );
      final result = await probe.probe(
        bytes: header,
        filePath: null,
        extension: 'wav',
        mime: 'audio/wav',
      );
      expect(result.hasDuration, isFalse);
    });

    test('zero byte_rate falls through', () async {
      final header = buildWavHeader(
        formatTag: 0x0001,
        channels: 1,
        sampleRate: 16000,
        bitsPerSample: 16,
        dataSize: 100,
        byteRateOverride: 0,
      );
      final result = await probe.probe(
        bytes: header,
        filePath: null,
        extension: 'wav',
        mime: 'audio/wav',
      );
      expect(result.hasDuration, isFalse);
    });

    test('non-WAV magic returns null from header probe', () async {
      final bytes = Uint8List.fromList(
        ascii('OggS') + List<int>.filled(100, 0),
      );
      final result = await probe.probe(
        bytes: bytes,
        filePath: null,
        extension: 'wav',
        mime: 'audio/wav',
      );
      expect(result.hasDuration, isFalse);
    });

    test('buffer shorter than 44 bytes returns null', () async {
      final result = await probe.probe(
        bytes: Uint8List(10),
        filePath: null,
        extension: 'wav',
        mime: 'audio/wav',
      );
      expect(result.hasDuration, isFalse);
    });
  });
}
