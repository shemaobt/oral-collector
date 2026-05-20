import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/features/recording/data/services/wav_concat.dart';

const _sampleRate = 16000;
const _numChannels = 1;
const _bitsPerSample = 16;

Uint8List _buildWavFile(
  List<int> samples, {
  int sampleRate = _sampleRate,
  int numChannels = _numChannels,
  int bitsPerSample = _bitsPerSample,
}) {
  final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
  final blockAlign = numChannels * bitsPerSample ~/ 8;
  final dataSize = samples.length * (bitsPerSample ~/ 8);
  final fileSize = 36 + dataSize;

  final builder = BytesBuilder();
  builder.add('RIFF'.codeUnits);
  builder.add(_uint32LE(fileSize));
  builder.add('WAVE'.codeUnits);
  builder.add('fmt '.codeUnits);
  builder.add(_uint32LE(16));
  builder.add(_uint16LE(1));
  builder.add(_uint16LE(numChannels));
  builder.add(_uint32LE(sampleRate));
  builder.add(_uint32LE(byteRate));
  builder.add(_uint16LE(blockAlign));
  builder.add(_uint16LE(bitsPerSample));
  builder.add('data'.codeUnits);
  builder.add(_uint32LE(dataSize));
  for (final s in samples) {
    builder.add(_int16LE(s));
  }
  return builder.toBytes();
}

List<int> _uint32LE(int v) => [
  v & 0xff,
  (v >> 8) & 0xff,
  (v >> 16) & 0xff,
  (v >> 24) & 0xff,
];
List<int> _uint16LE(int v) => [v & 0xff, (v >> 8) & 0xff];
List<int> _int16LE(int v) => [v & 0xff, (v >> 8) & 0xff];

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('wav_concat_test_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('returns false when segment list is empty', () async {
    final ok = await concatWavFilesInDart(
      segments: <String>[],
      outputPath: '${tmp.path}/out.wav',
    );
    expect(ok, isFalse);
  });

  test('returns false when first segment does not exist', () async {
    final ok = await concatWavFilesInDart(
      segments: ['${tmp.path}/missing.wav'],
      outputPath: '${tmp.path}/out.wav',
    );
    expect(ok, isFalse);
  });

  test('single segment is copied with header preserved', () async {
    final samples = [10, 20, 30, 40];
    final input = '${tmp.path}/in.wav';
    await File(input).writeAsBytes(_buildWavFile(samples));

    final output = '${tmp.path}/out.wav';
    final ok = await concatWavFilesInDart(
      segments: [input],
      outputPath: output,
    );
    expect(ok, isTrue);

    final outBytes = await File(output).readAsBytes();
    expect(String.fromCharCodes(outBytes.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(outBytes.sublist(8, 12)), 'WAVE');
    expect(outBytes.length, _buildWavFile(samples).length);
  });

  test('concatenates two segments and updates header sizes', () async {
    final samples1 = [1, 2, 3];
    final samples2 = [4, 5, 6, 7];
    final f1 = '${tmp.path}/s1.wav';
    final f2 = '${tmp.path}/s2.wav';
    await File(f1).writeAsBytes(_buildWavFile(samples1));
    await File(f2).writeAsBytes(_buildWavFile(samples2));

    final output = '${tmp.path}/out.wav';
    final ok = await concatWavFilesInDart(
      segments: [f1, f2],
      outputPath: output,
    );
    expect(ok, isTrue);

    final outBytes = await File(output).readAsBytes();
    final expectedDataSize = (samples1.length + samples2.length) * 2;
    final reportedDataSize = outBytes.buffer.asByteData().getUint32(
      40,
      Endian.little,
    );
    final reportedFileSize = outBytes.buffer.asByteData().getUint32(
      4,
      Endian.little,
    );
    expect(reportedDataSize, expectedDataSize);
    expect(reportedFileSize, expectedDataSize + 36);
    expect(outBytes.length, 44 + expectedDataSize);
  });

  test('skips missing segments after the first', () async {
    final samples1 = [1, 2, 3];
    final f1 = '${tmp.path}/s1.wav';
    await File(f1).writeAsBytes(_buildWavFile(samples1));

    final output = '${tmp.path}/out.wav';
    final ok = await concatWavFilesInDart(
      segments: [f1, '${tmp.path}/missing.wav'],
      outputPath: output,
    );
    expect(ok, isTrue);

    final outBytes = await File(output).readAsBytes();
    final reportedDataSize = outBytes.buffer.asByteData().getUint32(
      40,
      Endian.little,
    );
    expect(reportedDataSize, samples1.length * 2);
  });

  test('returns false when first file is not a WAV', () async {
    final f1 = '${tmp.path}/s1.wav';
    await File(f1).writeAsBytes(Uint8List.fromList([0, 1, 2, 3, 4, 5]));

    final ok = await concatWavFilesInDart(
      segments: [f1],
      outputPath: '${tmp.path}/out.wav',
    );
    expect(ok, isFalse);
  });

  test('skips segments whose sample rate differs from the first', () async {
    final f1 = '${tmp.path}/s1.wav';
    final f2 = '${tmp.path}/s2_wrong_rate.wav';
    // Same canonical format
    await File(f1).writeAsBytes(_buildWavFile([1, 2]));
    // Mismatched sample rate
    await File(f2).writeAsBytes(_buildWavFile([3, 4], sampleRate: 44100));

    final output = '${tmp.path}/out.wav';
    final ok = await concatWavFilesInDart(
      segments: [f1, f2],
      outputPath: output,
    );
    expect(ok, isTrue);

    // Output should contain only the first segment's samples.
    final outBytes = await File(output).readAsBytes();
    final reportedDataSize = outBytes.buffer.asByteData().getUint32(
      40,
      Endian.little,
    );
    expect(reportedDataSize, 2 * 2);
  });

  test('skips segments whose bit depth differs from the first', () async {
    final f1 = '${tmp.path}/s1.wav';
    final f2 = '${tmp.path}/s2_wrong_bits.wav';
    await File(f1).writeAsBytes(_buildWavFile([1, 2, 3]));
    await File(f2).writeAsBytes(_buildWavFile([4, 5, 6], bitsPerSample: 8));

    final output = '${tmp.path}/out.wav';
    final ok = await concatWavFilesInDart(
      segments: [f1, f2],
      outputPath: output,
    );
    expect(ok, isTrue);

    final outBytes = await File(output).readAsBytes();
    final reportedDataSize = outBytes.buffer.asByteData().getUint32(
      40,
      Endian.little,
    );
    expect(reportedDataSize, 3 * 2);
  });

  test('skips segments whose channel count differs from the first', () async {
    final f1 = '${tmp.path}/s1.wav';
    final f2 = '${tmp.path}/s2_wrong_channels.wav';
    await File(f1).writeAsBytes(_buildWavFile([1, 2]));
    await File(f2).writeAsBytes(_buildWavFile([3, 4], numChannels: 2));

    final output = '${tmp.path}/out.wav';
    final ok = await concatWavFilesInDart(
      segments: [f1, f2],
      outputPath: output,
    );
    expect(ok, isTrue);

    final outBytes = await File(output).readAsBytes();
    final reportedDataSize = outBytes.buffer.asByteData().getUint32(
      40,
      Endian.little,
    );
    expect(reportedDataSize, 2 * 2);
  });
}
