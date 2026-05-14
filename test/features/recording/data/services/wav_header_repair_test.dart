import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/features/recording/data/services/wav_header_repair.dart';

void main() {
  late Directory tmpDir;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('wav_repair_test_');
  });

  tearDown(() async {
    if (tmpDir.existsSync()) {
      await tmpDir.delete(recursive: true);
    }
  });

  /// Builds a minimal in-flight WAV file. The RIFF + data chunk sizes are
  /// left as placeholders (0), mimicking what an interrupted `record` package
  /// session leaves on disk.
  Future<File> writeBrokenWav({
    required String name,
    required int sampleRate,
    required int numChannels,
    required int bitsPerSample,
    required int pcmByteCount,
  }) async {
    final path = '${tmpDir.path}/$name.wav';
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final blockAlign = numChannels * bitsPerSample ~/ 8;

    final header = BytesBuilder();
    header.add(_ascii('RIFF'));
    header.add(_u32le(0)); // placeholder - to be repaired
    header.add(_ascii('WAVE'));
    header.add(_ascii('fmt '));
    header.add(_u32le(16));
    header.add(_u16le(1)); // PCM
    header.add(_u16le(numChannels));
    header.add(_u32le(sampleRate));
    header.add(_u32le(byteRate));
    header.add(_u16le(blockAlign));
    header.add(_u16le(bitsPerSample));
    header.add(_ascii('data'));
    header.add(_u32le(0)); // placeholder - to be repaired

    final pcm = Uint8List(pcmByteCount);

    final file = File(path);
    await file.writeAsBytes([...header.toBytes(), ...pcm]);
    return file;
  }

  test(
    'repair fills in RIFF and data sizes based on actual file size',
    () async {
      final file = await writeBrokenWav(
        name: 'broken',
        sampleRate: 16000,
        numChannels: 1,
        bitsPerSample: 16,
        pcmByteCount: 32000, // 1 second @ 16kHz mono 16-bit
      );

      final result = await const WavHeaderRepair().repair(file.path);

      expect(result, isNotNull);
      expect(result!.duration, const Duration(milliseconds: 1000));
      expect(result.fileSize, 44 + 32000);

      final bytes = await file.readAsBytes();
      expect(
        _readU32le(bytes, 4),
        bytes.length - 8,
        reason: 'RIFF chunk size = fileSize - 8',
      );
      expect(
        _readU32le(bytes, 40),
        bytes.length - 44,
        reason: 'data chunk size = fileSize - 44 (44-byte header)',
      );
    },
  );

  test('repair survives PCM byte count that is not a whole second', () async {
    final file = await writeBrokenWav(
      name: 'partial',
      sampleRate: 16000,
      numChannels: 1,
      bitsPerSample: 16,
      pcmByteCount: 16000, // 500ms
    );

    final result = await const WavHeaderRepair().repair(file.path);

    expect(result, isNotNull);
    expect(result!.duration, const Duration(milliseconds: 500));
  });

  test('repair returns null for non-existent file', () async {
    final result = await const WavHeaderRepair().repair(
      '${tmpDir.path}/does_not_exist.wav',
    );
    expect(result, isNull);
  });

  test('repair returns null for file too small to be a WAV', () async {
    final path = '${tmpDir.path}/tiny.wav';
    await File(path).writeAsBytes(List<int>.filled(20, 0));
    final result = await const WavHeaderRepair().repair(path);
    expect(result, isNull);
  });

  test('repair returns null for file with invalid RIFF magic', () async {
    final path = '${tmpDir.path}/not_riff.wav';
    final bytes = List<int>.filled(100, 0);
    bytes.setRange(0, 4, _ascii('XXXX'));
    await File(path).writeAsBytes(bytes);
    final result = await const WavHeaderRepair().repair(path);
    expect(result, isNull);
  });

  test('repair is idempotent — running twice gives the same result', () async {
    final file = await writeBrokenWav(
      name: 'idempotent',
      sampleRate: 16000,
      numChannels: 1,
      bitsPerSample: 16,
      pcmByteCount: 64000, // 2s
    );

    final first = await const WavHeaderRepair().repair(file.path);
    final second = await const WavHeaderRepair().repair(file.path);

    expect(first?.duration, const Duration(milliseconds: 2000));
    expect(second?.duration, const Duration(milliseconds: 2000));
    expect(first?.fileSize, second?.fileSize);
  });

  test(
    'repair returns null when only the header was written (no PCM)',
    () async {
      final file = await writeBrokenWav(
        name: 'header_only',
        sampleRate: 16000,
        numChannels: 1,
        bitsPerSample: 16,
        pcmByteCount: 0,
      );

      final result = await const WavHeaderRepair().repair(file.path);
      expect(result, isNull);
    },
  );
}

List<int> _ascii(String s) => s.codeUnits;

List<int> _u16le(int value) {
  return [value & 0xFF, (value >> 8) & 0xFF];
}

List<int> _u32le(int value) {
  return [
    value & 0xFF,
    (value >> 8) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 24) & 0xFF,
  ];
}

int _readU32le(List<int> bytes, int offset) {
  return bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);
}
