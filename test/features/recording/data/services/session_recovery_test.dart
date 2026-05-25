import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/repositories/recording_session_repository.dart';
import 'package:oral_collector/features/recording/data/services/session_recovery.dart';

Future<void> _insertActiveSession(
  AppDatabase db, {
  required String id,
  required List<String> segmentPaths,
  double totalDurationSeconds = 60.0,
}) async {
  await db
      .into(db.recordingSessions)
      .insert(
        RecordingSessionsCompanion.insert(
          id: id,
          projectId: 'p1',
          genreId: 'g1',
          startedAt: DateTime(2025, 1, 1),
          status: const Value('active'),
          segmentPathsJson: Value(
            '[${segmentPaths.map((p) => '"$p"').join(',')}]',
          ),
          totalDurationSeconds: Value(totalDurationSeconds),
        ),
      );
}

void main() {
  late Directory tmp;
  late AppDatabase db;
  late RecordingSessionRepository repo;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('session_recovery_test_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RecordingSessionRepository(db);
  });

  tearDown(() async {
    await db.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('returns null when session does not exist in repo', () async {
    final result = await recoverSessionFromDisk(
      repo: repo,
      sessionId: 'nonexistent',
      documentsDir: tmp,
    );
    expect(result, isNull);
  });

  test('returns null when no segment files exist on disk', () async {
    await _insertActiveSession(
      db,
      id: 'sess-1',
      segmentPaths: ['${tmp.path}/missing.wav'],
    );
    final result = await recoverSessionFromDisk(
      repo: repo,
      sessionId: 'sess-1',
      documentsDir: tmp,
    );
    expect(result, isNull);
  });

  test(
    'returns existing DB-listed segments and marks session recovered',
    () async {
      final s1 = '${tmp.path}/rec_sess-1_001.wav';
      final s2 = '${tmp.path}/rec_sess-1_002.wav';
      await File(s1).writeAsBytes([0, 1, 2]);
      await File(s2).writeAsBytes([3, 4, 5]);
      await _insertActiveSession(db, id: 'sess-1', segmentPaths: [s1, s2]);

      final result = await recoverSessionFromDisk(
        repo: repo,
        sessionId: 'sess-1',
        documentsDir: tmp,
      );

      expect(result, isNotNull);
      expect(result!.segmentPaths, containsAll([s1, s2]));
      expect(result.sessionId, 'sess-1');

      final session = await repo.getById('sess-1');
      expect(session?.status, 'recovered');
    },
  );

  test('picks up orphan segments on disk not in DB', () async {
    final dbSeg = '${tmp.path}/rec_sess-2_001.wav';
    final orphan = '${tmp.path}/rec_sess-2_002.wav';
    await File(dbSeg).writeAsBytes([0, 1, 2]);
    await File(orphan).writeAsBytes([3, 4, 5]);
    // DB only knows about segment 001
    await _insertActiveSession(db, id: 'sess-2', segmentPaths: [dbSeg]);

    final result = await recoverSessionFromDisk(
      repo: repo,
      sessionId: 'sess-2',
      documentsDir: tmp,
    );

    expect(result, isNotNull);
    expect(result!.segmentPaths, containsAll([dbSeg, orphan]));
  });

  test('does not include orphans for a different session', () async {
    final mine = '${tmp.path}/rec_sess-3_001.wav';
    final other = '${tmp.path}/rec_sess-other_001.wav';
    await File(mine).writeAsBytes([0, 1, 2]);
    await File(other).writeAsBytes([3, 4, 5]);
    await _insertActiveSession(db, id: 'sess-3', segmentPaths: [mine]);

    final result = await recoverSessionFromDisk(
      repo: repo,
      sessionId: 'sess-3',
      documentsDir: tmp,
    );

    expect(result, isNotNull);
    expect(result!.segmentPaths, contains(mine));
    expect(result.segmentPaths, isNot(contains(other)));
  });

  test('sorts segments by index ascending', () async {
    final s3 = '${tmp.path}/rec_sess-4_003.wav';
    final s1 = '${tmp.path}/rec_sess-4_001.wav';
    final s2 = '${tmp.path}/rec_sess-4_002.wav';
    await File(s3).writeAsBytes([0]);
    await File(s1).writeAsBytes([1]);
    await File(s2).writeAsBytes([2]);
    // DB lists them out of order
    await _insertActiveSession(db, id: 'sess-4', segmentPaths: [s3, s1, s2]);

    final result = await recoverSessionFromDisk(
      repo: repo,
      sessionId: 'sess-4',
      documentsDir: tmp,
    );

    expect(result, isNotNull);
    expect(result!.segmentPaths, [s1, s2, s3]);
  });

  test('deduplicates segments present in both DB and disk', () async {
    final s1 = '${tmp.path}/rec_sess-5_001.wav';
    await File(s1).writeAsBytes([0, 1, 2]);
    await _insertActiveSession(db, id: 'sess-5', segmentPaths: [s1]);

    final result = await recoverSessionFromDisk(
      repo: repo,
      sessionId: 'sess-5',
      documentsDir: tmp,
    );

    expect(result, isNotNull);
    expect(result!.segmentPaths.length, 1);
    expect(result.segmentPaths.first, s1);
  });

  test('uses totalDurationSeconds from DB', () async {
    final s1 = '${tmp.path}/rec_sess-6_001.wav';
    await File(s1).writeAsBytes([0]);
    await _insertActiveSession(
      db,
      id: 'sess-6',
      segmentPaths: [s1],
      totalDurationSeconds: 12.5,
    );

    final result = await recoverSessionFromDisk(
      repo: repo,
      sessionId: 'sess-6',
      documentsDir: tmp,
    );

    expect(result!.totalDuration, const Duration(milliseconds: 12500));
  });
}
