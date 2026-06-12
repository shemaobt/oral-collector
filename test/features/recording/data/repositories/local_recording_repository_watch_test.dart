/// Tests for watchRecordingById's emission behavior.
///
/// Drift invalidates query streams at the table level: any write to
/// local_recordings re-runs the query and would re-push an identical value.
/// `.distinct()` suppresses those duplicate emissions so an unrelated write
/// does not churn subscribers, while real changes still propagate. See ENG-121.
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

  Future<void> insertRec(String id, {String title = 'orig'}) {
    return repo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(id),
        projectId: const Value('proj-1'),
        genreId: const Value('genre-1'),
        localFilePath: Value('/tmp/$id.m4a'),
        title: Value(title),
        recordedAt: Value(DateTime.utc(2026, 5, 1, 10)),
      ),
    );
  }

  test(
    'does not re-emit when an unrelated row in the same table changes',
    () async {
      await insertRec('A');

      final emissions = <LocalRecording?>[];
      final sub = repo.watchRecordingById('A').listen(emissions.add);
      await pumpEventQueue();

      await insertRec('B'); // unrelated write to the same table
      await pumpEventQueue();

      await sub.cancel();

      expect(emissions, hasLength(1));
      expect(emissions.single?.id, 'A');
    },
  );

  test('emits again when the watched row actually changes', () async {
    await insertRec('A', title: 'orig');

    final emissions = <LocalRecording?>[];
    final sub = repo.watchRecordingById('A').listen(emissions.add);
    await pumpEventQueue();

    await repo.updateRecording(
      'A',
      const LocalRecordingsCompanion(title: Value('changed')),
    );
    await pumpEventQueue();

    await sub.cancel();

    expect(emissions.map((r) => r?.title).toList(), ['orig', 'changed']);
  });
}
