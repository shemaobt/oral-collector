/// Tests for LocalRecordingRepository's typed classification/metadata writes
/// (ENG-194). These methods replace the inline `LocalRecordingsCompanion`
/// construction that recording_detail_screen did in the presentation layer.
///
/// They pin the exact column semantics the screen relied on — in particular the
/// three writes that must NOT be unified: `classify` omits `registerId` when
/// null (preserve), while `moveCategory(clearSecondary:)` and
/// `updateSecondaryClassification` write null (clear).
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

  /// Seeds a fully-populated row so clear-to-null behavior is observable.
  Future<void> seed({String id = 'rec-1'}) async {
    await repo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(id),
        projectId: const Value('proj-1'),
        genreId: const Value('genre-initial'),
        subcategoryId: const Value('sub-initial'),
        registerId: const Value('reg-initial'),
        secondaryGenreId: const Value('sg-initial'),
        secondarySubcategoryId: const Value('ss-initial'),
        secondaryRegisterId: const Value('sr-initial'),
        storytellerId: const Value('st-initial'),
        title: const Value('Initial Title'),
        description: const Value('initial desc'),
        cleaningStatus: const Value('none'),
        durationSeconds: const Value(10),
        fileSizeBytes: const Value(1024),
        format: const Value('m4a'),
        localFilePath: const Value('/tmp/rec-1.m4a'),
        recordedAt: Value(DateTime.utc(2026, 5, 1, 10)),
      ),
    );
  }

  group('setStoryteller', () {
    test('sets the storyteller id', () async {
      await seed();
      await repo.setStoryteller('rec-1', storytellerId: 'st-2');
      final row = await repo.getRecordingById('rec-1');
      expect(row!.storytellerId, 'st-2');
    });

    test('clears the storyteller id when null', () async {
      await seed();
      await repo.setStoryteller('rec-1', storytellerId: null);
      final row = await repo.getRecordingById('rec-1');
      expect(row!.storytellerId, isNull);
    });
  });

  test('updateDescription sets the description', () async {
    await seed();
    await repo.updateDescription('rec-1', 'a new note');
    final row = await repo.getRecordingById('rec-1');
    expect(row!.description, 'a new note');
  });

  test('updateCleaningStatus flips the cleaning status', () async {
    await seed();
    await repo.updateCleaningStatus('rec-1', 'needs_cleaning');
    final row = await repo.getRecordingById('rec-1');
    expect(row!.cleaningStatus, 'needs_cleaning');
  });

  group('moveCategory', () {
    test('updates primary and keeps secondary when not clearing', () async {
      await seed();
      await repo.moveCategory(
        'rec-1',
        genreId: 'genre-2',
        subcategoryId: 'sub-2',
        clearSecondary: false,
        secondaryGenreId: 'sg-2',
        secondarySubcategoryId: 'ss-2',
        secondaryRegisterId: 'sr-2',
      );
      final row = await repo.getRecordingById('rec-1');
      expect(row!.genreId, 'genre-2');
      expect(row.subcategoryId, 'sub-2');
      expect(row.secondaryGenreId, 'sg-2');
      expect(row.secondarySubcategoryId, 'ss-2');
      expect(row.secondaryRegisterId, 'sr-2');
    });

    test('clears all secondary fields when clearSecondary is true', () async {
      await seed();
      await repo.moveCategory(
        'rec-1',
        genreId: 'genre-2',
        subcategoryId: 'sub-2',
        clearSecondary: true,
      );
      final row = await repo.getRecordingById('rec-1');
      expect(row!.genreId, 'genre-2');
      expect(row.subcategoryId, 'sub-2');
      expect(row.secondaryGenreId, isNull);
      expect(row.secondarySubcategoryId, isNull);
      expect(row.secondaryRegisterId, isNull);
    });
  });

  group('classify', () {
    test('writes primary, register and secondary', () async {
      await seed();
      await repo.classify(
        'rec-1',
        genreId: 'genre-2',
        subcategoryId: 'sub-2',
        registerId: 'reg-2',
        secondaryGenreId: 'sg-2',
        secondarySubcategoryId: 'ss-2',
        secondaryRegisterId: 'sr-2',
      );
      final row = await repo.getRecordingById('rec-1');
      expect(row!.genreId, 'genre-2');
      expect(row.subcategoryId, 'sub-2');
      expect(row.registerId, 'reg-2');
      expect(row.secondaryGenreId, 'sg-2');
      expect(row.secondarySubcategoryId, 'ss-2');
      expect(row.secondaryRegisterId, 'sr-2');
    });

    test('preserves existing register when registerId is null', () async {
      await seed();
      await repo.classify(
        'rec-1',
        genreId: 'genre-2',
        subcategoryId: 'sub-2',
        registerId: null,
        secondaryGenreId: 'sg-2',
        secondarySubcategoryId: 'ss-2',
        secondaryRegisterId: 'sr-2',
      );
      final row = await repo.getRecordingById('rec-1');
      // registerId uses Value.absent() when null — the column is left untouched,
      // NOT cleared (this is the key difference vs moveCategory/secondary).
      expect(row!.registerId, 'reg-initial');
    });
  });

  group('updateSecondaryClassification', () {
    test('sets the secondary fields', () async {
      await seed();
      await repo.updateSecondaryClassification(
        'rec-1',
        genreId: 'sg-2',
        subcategoryId: 'ss-2',
        registerId: 'sr-2',
      );
      final row = await repo.getRecordingById('rec-1');
      expect(row!.secondaryGenreId, 'sg-2');
      expect(row.secondarySubcategoryId, 'ss-2');
      expect(row.secondaryRegisterId, 'sr-2');
    });

    test('clears the secondary fields when all null', () async {
      await seed();
      await repo.updateSecondaryClassification(
        'rec-1',
        genreId: null,
        subcategoryId: null,
        registerId: null,
      );
      final row = await repo.getRecordingById('rec-1');
      expect(row!.secondaryGenreId, isNull);
      expect(row.secondarySubcategoryId, isNull);
      expect(row.secondaryRegisterId, isNull);
    });
  });
}
