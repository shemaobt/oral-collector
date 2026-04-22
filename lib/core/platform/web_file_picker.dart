import 'file_source.dart';

import 'web_file_picker_native.dart'
    if (dart.library.js_interop) 'web_file_picker_web.dart';

Future<List<FileSource>> pickAudioFiles({
  required List<String> allowedExtensions,
  bool multiple = true,
}) => pickAudioFilesImpl(
  allowedExtensions: allowedExtensions,
  multiple: multiple,
);

Future<FileSource?> pickSingleAudioFile({
  required List<String> allowedExtensions,
}) async {
  final sources = await pickAudioFiles(
    allowedExtensions: allowedExtensions,
    multiple: false,
  );
  return sources.isEmpty ? null : sources.first;
}
