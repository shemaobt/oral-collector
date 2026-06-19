/// Behavioral tests for the one-shot entity reads getRecordingEntityById and
/// getRecordingEntityByServerId (ENG-202). They wrap the Drift-row getters and
/// project to LocalRecordingEntity via the shared row mapper, returning null
/// when nothing matches. The trim editor's load path consumes these so the
/// presentation layer never touches a Drift row.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';

void main() {
  late AppDatabase db;
  late LocalRecordingRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertRec(
    String id, {
    String title = 'Story',
    String? serverId,
  }) {
    return repo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(id),
        projectId: const Value('proj-1'),
        genreId: const Value('genre-1'),
        title: Value(title),
        localFilePath: const Value('/tmp/audio.m4a'),
        serverId: Value(serverId),
        recordedAt: Value(DateTime.utc(2026, 5, 1, 10)),
      ),
    );
  }

  test(
    'getRecordingEntityById returns the stored recording as an entity',
    () async {
      await insertRec('A', title: 'My Story');

      final entity = await repo.getRecordingEntityById('A');

      expect(entity?.id, 'A');
      expect(entity?.title, 'My Story');
      // Another projected field round-trips, proving _fromRow ran rather than
      // the lookup passing a bare id through.
      expect(entity?.localFilePath, '/tmp/audio.m4a');
    },
  );

  test('getRecordingEntityById returns null when the id is absent', () async {
    await insertRec('A');

    expect(await repo.getRecordingEntityById('missing'), isNull);
  });

  test('getRecordingEntityByServerId resolves by server id', () async {
    await insertRec('A', serverId: 'srv-1');

    final entity = await repo.getRecordingEntityByServerId('srv-1');

    expect(entity?.id, 'A');
    expect(entity?.serverId, 'srv-1');
  });

  test(
    'getRecordingEntityByServerId returns null when the server id is absent',
    () async {
      await insertRec('A', serverId: 'srv-1');

      expect(await repo.getRecordingEntityByServerId('nope'), isNull);
    },
  );
}
