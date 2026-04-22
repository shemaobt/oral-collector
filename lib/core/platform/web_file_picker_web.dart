import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'file_source.dart';
import 'file_source_web.dart';

Future<List<FileSource>> pickAudioFilesImpl({
  required List<String> allowedExtensions,
  bool multiple = true,
}) {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..multiple = multiple
    ..accept = allowedExtensions.map((ext) => '.$ext').join(',');

  final completer = Completer<List<FileSource>>();

  void complete(List<FileSource> result) {
    if (completer.isCompleted) return;
    completer.complete(result);
  }

  input.onchange = ((web.Event _) {
    final files = input.files;
    if (files == null || files.length == 0) {
      complete(const []);
      return;
    }
    final sources = <FileSource>[];
    for (var i = 0; i < files.length; i++) {
      final f = files.item(i);
      if (f != null) sources.add(fileSourceFromWebFile(f));
    }
    complete(sources);
  }).toJS;

  input.oncancel = ((web.Event _) {
    complete(const []);
  }).toJS;

  input.click();
  return completer.future;
}
