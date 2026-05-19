import 'dart:io';
import 'dart:typed_data';

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
  final pcm = BytesBuilder();
  pcm.add(firstBytes.sublist(44));

  for (var i = 1; i < segments.length; i++) {
    final file = File(segments[i]);
    if (!await file.exists()) continue;
    final bytes = await file.readAsBytes();
    if (!_looksLikeWav(bytes)) continue;
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
