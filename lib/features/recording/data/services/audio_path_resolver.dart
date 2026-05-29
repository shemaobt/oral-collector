import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/platform/file_ops.dart' as file_ops;

Future<String?> resolveRecordingPath(String storedPath) async {
  if (kIsWeb) return null;
  if (storedPath.isEmpty) return null;

  if (await file_ops.fileExists(storedPath)) return storedPath;

  final docsDir = await getApplicationDocumentsDirectory();
  final fileName = p.basename(storedPath);
  final resolved = '${docsDir.path}/$fileName';
  if (await file_ops.fileExists(resolved)) return resolved;

  final inSubdir = '${docsDir.path}/recordings/$fileName';
  if (await file_ops.fileExists(inSubdir)) return inSubdir;

  return null;
}
