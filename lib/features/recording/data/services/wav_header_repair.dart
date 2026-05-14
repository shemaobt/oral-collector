import 'dart:io';

import 'package:flutter/foundation.dart';

class WavRepairResult {
  const WavRepairResult({required this.duration, required this.fileSize});

  final Duration duration;
  final int fileSize;
}

class WavHeaderRepair {
  const WavHeaderRepair();

  Future<WavRepairResult?> repair(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    final fileSize = await file.length();
    if (fileSize < 44) return null;

    RandomAccessFile? raf;
    try {
      raf = await file.open(mode: FileMode.append);

      await raf.setPosition(0);
      final riffHeader = await raf.read(12);
      if (riffHeader.length < 12) return null;
      if (String.fromCharCodes(riffHeader.sublist(0, 4)) != 'RIFF') return null;
      if (String.fromCharCodes(riffHeader.sublist(8, 12)) != 'WAVE')
        return null;

      int sampleRate = 0;
      int numChannels = 0;
      int bitsPerSample = 0;
      int? dataChunkSizeFieldPos;
      int? dataStartPos;

      int pos = 12;
      while (pos + 8 <= fileSize) {
        await raf.setPosition(pos);
        final chunkHeader = await raf.read(8);
        if (chunkHeader.length < 8) break;

        final chunkId = String.fromCharCodes(chunkHeader.sublist(0, 4));
        final declaredSize = _readUint32LE(chunkHeader, 4);

        if (chunkId == 'fmt ') {
          final fmtSize = declaredSize == 0 ? 16 : declaredSize;
          if (fmtSize < 16) return null;
          final fmtBody = await raf.read(fmtSize);
          if (fmtBody.length < 16) return null;
          numChannels = _readUint16LE(fmtBody, 2);
          sampleRate = _readUint32LE(fmtBody, 4);
          bitsPerSample = _readUint16LE(fmtBody, 14);
          pos += 8 + fmtSize;
        } else if (chunkId == 'data') {
          dataChunkSizeFieldPos = pos + 4;
          dataStartPos = pos + 8;
          break;
        } else {
          if (declaredSize <= 0 || declaredSize > fileSize - pos - 8) {
            return null;
          }
          pos += 8 + declaredSize;
        }
      }

      if (dataChunkSizeFieldPos == null || dataStartPos == null) return null;
      if (sampleRate <= 0 || numChannels <= 0 || bitsPerSample <= 0) {
        return null;
      }

      final dataSize = fileSize - dataStartPos;
      if (dataSize <= 0) return null;
      final riffSize = fileSize - 8;

      await raf.setPosition(4);
      await raf.writeFrom(_uint32LE(riffSize));
      await raf.setPosition(dataChunkSizeFieldPos);
      await raf.writeFrom(_uint32LE(dataSize));
      await raf.flush();

      final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
      if (byteRate <= 0) return null;
      final durationMs = (dataSize * 1000) ~/ byteRate;
      return WavRepairResult(
        duration: Duration(milliseconds: durationMs),
        fileSize: fileSize,
      );
    } on Exception {
      return null;
    } finally {
      await raf?.close();
    }
  }

  static int _readUint16LE(List<int> data, int offset) {
    return data[offset] | (data[offset + 1] << 8);
  }

  static int _readUint32LE(List<int> data, int offset) {
    return data[offset] |
        (data[offset + 1] << 8) |
        (data[offset + 2] << 16) |
        (data[offset + 3] << 24);
  }

  static Uint8List _uint32LE(int value) {
    final v = value & 0xFFFFFFFF;
    return Uint8List.fromList([
      v & 0xFF,
      (v >> 8) & 0xFF,
      (v >> 16) & 0xFF,
      (v >> 24) & 0xFF,
    ]);
  }
}
