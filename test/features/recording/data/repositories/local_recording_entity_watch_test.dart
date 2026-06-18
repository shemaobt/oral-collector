/// Behavioral tests for watchRecordingEntityById.
///
/// The stream maps each Drift row to LocalRecordingEntity and then applies
/// `.distinct()`, so dedup is driven entirely by the entity's value equality.
/// These tests pin that contract: a write touching only fields the entity
/// drops (`md5Hash`/`lastRetryAt`) must NOT re-emit — proving value (not
/// identity) equality and that the dropped fields are absent from `==` — while
/// a change to a carried content or operational field MUST re-emit. See ENG-195.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';

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
    String title = 'orig',
    String localFilePath = '/tmp/audio.m4a',
    int uploadedBytes = 0,
  }) {
    return repo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(id),
        projectId: const Value('proj-1'),
        genreId: const Value('genre-1'),
        localFilePath: Value(localFilePath),
        title: Value(title),
        uploadedBytes: Value(uploadedBytes),
        recordedAt: Value(DateTime.utc(2026, 5, 1, 10)),
      ),
    );
  }

  test(
    'does not re-emit when only dropped fields (md5Hash, lastRetryAt) change',
    () async {
      await insertRec('A');

      final emissions = <LocalRecordingEntity?>[];
      final sub = repo.watchRecordingEntityById('A').listen(emissions.add);
      await pumpEventQueue();

      // Neither md5Hash nor lastRetryAt is part of the entity: the row changes
      // but the entity does not, so .distinct() suppresses the re-emission.
      await repo.updateRecording(
        'A',
        LocalRecordingsCompanion(
          md5Hash: const Value('abc123'),
          lastRetryAt: Value(DateTime.utc(2026, 1, 2)),
        ),
      );
      await pumpEventQueue();

      await sub.cancel();

      expect(emissions, hasLength(1));
      expect(emissions.single?.id, 'A');
    },
  );

  test('re-emits when a content field of the watched row changes', () async {
    await insertRec('A', title: 'orig');

    final emissions = <LocalRecordingEntity?>[];
    final sub = repo.watchRecordingEntityById('A').listen(emissions.add);
    await pumpEventQueue();

    await repo.updateRecording(
      'A',
      const LocalRecordingsCompanion(title: Value('changed')),
    );
    await pumpEventQueue();

    await sub.cancel();

    expect(emissions.map((e) => e?.title).toList(), ['orig', 'changed']);
  });

  test('re-emits when the operational uploadedBytes field changes', () async {
    await insertRec('A', uploadedBytes: 0);

    final emissions = <LocalRecordingEntity?>[];
    final sub = repo.watchRecordingEntityById('A').listen(emissions.add);
    await pumpEventQueue();

    await repo.updateRecording(
      'A',
      const LocalRecordingsCompanion(uploadedBytes: Value(100)),
    );
    await pumpEventQueue();

    await sub.cancel();

    expect(emissions.map((e) => e?.uploadedBytes).toList(), [0, 100]);
  });

  test(
    'reflects localFilePath going empty (file no longer on this device)',
    () async {
      await insertRec('A', localFilePath: '/tmp/audio.m4a');

      final emissions = <LocalRecordingEntity?>[];
      final sub = repo.watchRecordingEntityById('A').listen(emissions.add);
      await pumpEventQueue();

      await repo.updateRecording(
        'A',
        const LocalRecordingsCompanion(localFilePath: Value('')),
      );
      await pumpEventQueue();

      await sub.cancel();

      expect(emissions.map((e) => e?.localFilePath).toList(), [
        '/tmp/audio.m4a',
        '',
      ]);
    },
  );
}
