import 'file_source.dart';

Future<List<FileSource>> pickAudioFilesImpl({
  required List<String> allowedExtensions,
  bool multiple = true,
}) => throw UnsupportedError(
  'pickAudioFiles is web-only; use package:file_picker on native targets',
);
