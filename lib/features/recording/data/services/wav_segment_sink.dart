import 'dart:io';
import 'dart:typed_data';

/// Append-only WAV PCM sink backed by a [RandomAccessFile].
///
/// Writes a 44-byte canonical RIFF/WAVE header with size placeholders set to
/// 0 at open. PCM bytes are appended synchronously as they arrive. On
/// [close], the RIFF and data chunk sizes are patched to reflect the final
/// file size. If the process dies before [close], the on-disk file is
/// recoverable by `WavHeaderRepair` (which expects the same 0-placeholder
/// shape produced by the native `record` plugin's `WaveContainer`).
class WavSegmentSink {
  WavSegmentSink._(this.path, this._raf, this.sampleRate, this.numChannels);

  final String path;
  final int sampleRate;
  final int numChannels;
  final RandomAccessFile _raf;
  int _dataBytes = 0;

  static WavSegmentSink open(String path, int sampleRate, int numChannels) {
    final raf = File(path).openSync(mode: FileMode.write);
    raf.writeFromSync(_buildPlaceholderHeader(sampleRate, numChannels));
    return WavSegmentSink._(path, raf, sampleRate, numChannels);
  }

  void appendBytes(Uint8List bytes) {
    _raf.writeFromSync(bytes);
    _dataBytes += bytes.length;
  }

  int get dataBytes => _dataBytes;

  Duration get currentDuration {
    final byteRate = sampleRate * numChannels * 2;
    return Duration(milliseconds: _dataBytes * 1000 ~/ byteRate);
  }

  Future<void> close() async {
    final fileSize = 44 + _dataBytes;
    await _raf.setPosition(4);
    await _raf.writeFrom(_uint32LE(fileSize - 8));
    await _raf.setPosition(40);
    await _raf.writeFrom(_uint32LE(_dataBytes));
    await _raf.flush();
    await _raf.close();
  }

  Future<void> closeWithoutPatch() async {
    await _raf.close();
  }

  static Uint8List _buildPlaceholderHeader(int sampleRate, int numChannels) {
    const bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final blockAlign = numChannels * bitsPerSample ~/ 8;
    final h = BytesBuilder();
    h.add(const [0x52, 0x49, 0x46, 0x46]); // "RIFF"
    h.add(_uint32LE(0)); // riff size placeholder
    h.add(const [0x57, 0x41, 0x56, 0x45]); // "WAVE"
    h.add(const [0x66, 0x6D, 0x74, 0x20]); // "fmt "
    h.add(_uint32LE(16)); // fmt chunk size (PCM)
    h.add(_uint16LE(1)); // audioFormat = PCM
    h.add(_uint16LE(numChannels));
    h.add(_uint32LE(sampleRate));
    h.add(_uint32LE(byteRate));
    h.add(_uint16LE(blockAlign));
    h.add(_uint16LE(bitsPerSample));
    h.add(const [0x64, 0x61, 0x74, 0x61]); // "data"
    h.add(_uint32LE(0)); // data size placeholder
    return h.toBytes();
  }

  static Uint8List _uint32LE(int v) {
    final x = v & 0xFFFFFFFF;
    return Uint8List.fromList([
      x & 0xFF,
      (x >> 8) & 0xFF,
      (x >> 16) & 0xFF,
      (x >> 24) & 0xFF,
    ]);
  }

  static Uint8List _uint16LE(int v) {
    final x = v & 0xFFFF;
    return Uint8List.fromList([x & 0xFF, (x >> 8) & 0xFF]);
  }
}
