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

  Future<List<RecordingSession>> findCrashedSessions() {
    return (_db.select(_db.recordingSessions)
          ..where((t) => t.status.equals('crashed'))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
  }

  /// Sessions that reached the end of a recording and may still owe the user
  /// something: stopped normally, or ended by being recovered. Both can hold
  /// finalized audio that was never saved (ENG-420).
  Future<List<RecordingSession>> findFinishedSessions() {
    return (_db.select(_db.recordingSessions)
          ..where((t) => t.status.isIn(const ['completed', 'recovered']))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
  }

  Future<void> markActive(String sessionId) async {
    await _setStatus(sessionId, 'active');
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

  /// Anchors the session to the audio it produced, then marks it completed
  /// (ENG-420).
  ///
  /// The two writes live together because the order between them is the whole
  /// point: a `completed` row must never exist without a pointer to its
  /// artifact. Dying between them leaves the session anchored but not
  /// completed, which is the harmless direction.
  Future<void> completeWithFinalizedAudio(
    String sessionId, {
    required String filePath,
    required double durationSeconds,
  }) async {
    await _anchorThen(sessionId, filePath, durationSeconds, 'completed');
  }

  /// The same, for a session that ends by being recovered rather than stopped
  /// normally — resuming an interrupted recording and stopping it, or the user
  /// confirming a recovery. Both produce real finalized audio, so both owe the
  /// row a pointer; without it the sweep cannot tell them from a session that
  /// never finalized at all.
  Future<void> recoverWithFinalizedAudio(
    String sessionId, {
    required String filePath,
    required double durationSeconds,
  }) async {
    await _anchorThen(sessionId, filePath, durationSeconds, 'recovered');
  }

  Future<void> _anchorThen(
    String sessionId,
    String filePath,
    double durationSeconds,
    String status,
  ) async {
    await (_db.update(
      _db.recordingSessions,
    )..where((t) => t.id.equals(sessionId))).write(
      RecordingSessionsCompanion(
        finalizedAudioPath: Value(filePath),
        finalizedDurationSeconds: Value(durationSeconds),
      ),
    );
    await _setStatus(sessionId, status);
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
