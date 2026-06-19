import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/platform/file_ops.dart' as file_ops;
import 'recording_trash.dart';
import 'waveform_extractor.dart';

/// Copies a picked audio file into the app's recordings dir and returns the new
/// path + size (ENG-194). When [oldPath] is non-empty it trashes the previous
/// file and invalidates its waveform cache. Behind this seam so the replace flow
/// is unit-testable; web-safe (all IO via the `file_ops` facade, no `dart:io`).
typedef RecordingFileImporter =
    Future<({String path, int sizeBytes})> Function({
      required String sourcePath,
      required String fileName,
      required String? oldPath,
      required String recordingId,
      required String format,
    });

Future<({String path, int sizeBytes})> importRecordingFile({
  required String sourcePath,
  required String fileName,
  required String? oldPath,
  required String recordingId,
  required String format,
}) async {
  final docsDir = await getApplicationDocumentsDirectory();
  final recordingsDir = '${docsDir.path}/recordings';
  if (!await file_ops.dirExists(recordingsDir)) {
    await file_ops.createDir(recordingsDir);
  }
  final newName =
      '${DateTime.now().millisecondsSinceEpoch}_${p.basename(fileName)}';
  final newPath = '$recordingsDir/$newName';
  await file_ops.copyFile(sourcePath, newPath);
  final newSize = await file_ops.fileLength(newPath);

  if (oldPath != null && oldPath.isNotEmpty) {
    await RecordingTrash.putInTrash(
      sourcePath: oldPath,
      metadata: {
        'recordingId': recordingId,
        'format': format,
        'reason': 'replaced',
      },
    );
    WaveformExtractor.invalidate(oldPath);
  }

  return (path: newPath, sizeBytes: newSize);
}

final recordingFileImporterProvider = Provider<RecordingFileImporter>(
  (_) => importRecordingFile,
);
