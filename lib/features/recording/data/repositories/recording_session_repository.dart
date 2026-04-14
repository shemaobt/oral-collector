import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';

class RecordingSessionRepository {
  final AppDatabase _db;

  RecordingSessionRepository(this._db);

  Future<void> insertSession(RecordingSessionsCompanion data) async {
    await _db.into(_db.recordingSessions).insert(data);
  }

  Future<RecordingSession?> getById(String id) {
    return (_db.select(
      _db.recordingSessions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<RecordingSession>> findActiveSessions() {
    return (_db.select(
      _db.recordingSessions,
    )..where((t) => t.status.equals('active'))).get();
  }

  Future<void> appendSegment(
    String sessionId,
    String path,
    double segmentDurationSeconds,
  ) async {
    final session = await getById(sessionId);
    if (session == null) return;

    final paths = _decodeSegments(session.segmentPathsJson);
    paths.add(path);

    await (_db.update(
      _db.recordingSessions,
    )..where((t) => t.id.equals(sessionId))).write(
      RecordingSessionsCompanion(
        segmentPathsJson: Value(jsonEncode(paths)),
        totalDurationSeconds: Value(
          session.totalDurationSeconds + segmentDurationSeconds,
        ),
        lastCheckpointAt: Value(DateTime.now()),
        lastSegmentIndex: Value(session.lastSegmentIndex + 1),
      ),
    );
  }

  Future<void> setPaused(String sessionId, bool paused) async {
    await (_db.update(_db.recordingSessions)
          ..where((t) => t.id.equals(sessionId)))
        .write(RecordingSessionsCompanion(isPaused: Value(paused)));
  }

  Future<void> markCompleted(String sessionId) async {
    await _setStatus(sessionId, 'completed');
  }

  Future<void> markCrashed(String sessionId) async {
    await _setStatus(sessionId, 'crashed');
  }

  Future<void> markRecovered(String sessionId) async {
    await _setStatus(sessionId, 'recovered');
  }

  Future<void> markDiscarded(String sessionId) async {
    await _setStatus(sessionId, 'discarded');
  }

  Future<void> _setStatus(String sessionId, String status) async {
    await (_db.update(_db.recordingSessions)
          ..where((t) => t.id.equals(sessionId)))
        .write(RecordingSessionsCompanion(status: Value(status)));
  }

  Future<void> deleteSession(String sessionId) async {
    await (_db.delete(
      _db.recordingSessions,
    )..where((t) => t.id.equals(sessionId))).go();
  }

  List<String> decodeSegmentPaths(RecordingSession session) {
    return _decodeSegments(session.segmentPathsJson);
  }

  List<String> _decodeSegments(String json) {
    if (json.isEmpty) return <String>[];
    final decoded = jsonDecode(json);
    if (decoded is! List) return <String>[];
    return decoded.whereType<String>().toList();
  }
}
