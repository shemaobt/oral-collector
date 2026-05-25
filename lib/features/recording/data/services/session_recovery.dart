import 'dart:io';

import '../repositories/recording_session_repository.dart';
import 'segmented_recorder.dart';

Future<SegmentedRecordingResult?> recoverSessionFromDisk({
  required RecordingSessionRepository repo,
  required String sessionId,
  required Directory documentsDir,
  bool Function(String)? fileExists,
}) async {
  final exists = fileExists ?? (p) => File(p).existsSync();
  final session = await repo.getById(sessionId);
  if (session == null) return null;

  final dbPaths = repo.decodeSegmentPaths(session);
  final orphans = _findOrphanSegments(
    documentsDir: documentsDir,
    sessionId: sessionId,
  );

  final merged = <String>{...dbPaths, ...orphans}.where(exists).toList()
    ..sort(_byIndexThenName);

  if (merged.isEmpty) return null;

  try {
    await repo.markRecovered(sessionId);
  } catch (_) {}

  return SegmentedRecordingResult(
    sessionId: sessionId,
    segmentPaths: merged,
    totalDuration: Duration(
      milliseconds: (session.totalDurationSeconds * 1000).round(),
    ),
  );
}

List<String> _findOrphanSegments({
  required Directory documentsDir,
  required String sessionId,
}) {
  try {
    if (!documentsDir.existsSync()) return const <String>[];
    final pattern = RegExp('^rec_${RegExp.escape(sessionId)}_\\d+\\.wav\$');
    final paths = <String>[];
    for (final entry in documentsDir.listSync(followLinks: false)) {
      final basename = entry.uri.pathSegments.last;
      if (pattern.hasMatch(basename)) {
        paths.add(entry.path);
      }
    }
    return paths;
  } catch (_) {
    return const <String>[];
  }
}

int _byIndexThenName(String a, String b) {
  final idxA = _extractIndex(a);
  final idxB = _extractIndex(b);
  if (idxA != null && idxB != null) return idxA.compareTo(idxB);
  return a.compareTo(b);
}

int? _extractIndex(String path) {
  final match = RegExp(r'_(\d+)\.wav$').firstMatch(path);
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}
