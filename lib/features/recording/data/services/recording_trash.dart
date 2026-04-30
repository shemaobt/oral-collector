import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

class RecordingTrash {
  static const _folderName = '.trash';
  static const _metadataSuffix = '.json';

  static Future<Directory> _trashDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_folderName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<void> putInTrash({
    required String sourcePath,
    required Map<String, dynamic> metadata,
  }) async {
    if (kIsWeb) return;

    final source = File(sourcePath);
    if (!await source.exists()) return;

    final dir = await _trashDir();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final originalName = sourcePath.split(Platform.pathSeparator).last;
    final trashedName = '${stamp}_$originalName';
    final trashedPath = '${dir.path}/$trashedName';

    try {
      await source.rename(trashedPath);
    } on FileSystemException {
      await source.copy(trashedPath);
      await source.delete();
    }

    final meta = {
      ...metadata,
      'trashedAt': DateTime.now().toIso8601String(),
      'trashedPath': trashedPath,
    };
    await File('$trashedPath$_metadataSuffix').writeAsString(jsonEncode(meta));
  }

  static Future<void> pruneOldTrash({int maxAgeHours = 24}) async {
    if (kIsWeb) return;

    final dir = await _trashDir();
    if (!await dir.exists()) return;

    final cutoff = DateTime.now().subtract(Duration(hours: maxAgeHours));

    await for (final entity in dir.list(followLinks: false)) {
      try {
        final stat = await entity.stat();
        if (stat.modified.isBefore(cutoff)) {
          if (entity is File) {
            await entity.delete();
          } else if (entity is Directory) {
            await entity.delete(recursive: true);
          }
        }
      } on FileSystemException {
        continue;
      }
    }
  }
}
