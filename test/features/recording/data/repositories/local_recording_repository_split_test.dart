/// Tests for LocalRecordingRepository.splitRecordingReplacingParent.
///
/// Asserts the field-propagation contract documented in
/// `docs/recording-split-semantics.md` (ENG-64) plus the atomic
/// parent-replacement behavior (ENG-125).
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/local_recording_to_entity.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/classification.dart';
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

  Future<LocalRecordingEntity> seedParent({
    String id = 'parent-1',
    String? description = 'A story told on a Sunday',
    String? storytellerId = 'storyteller-7',
    String? userId = 'user-42',
    String? secondaryGenreId = 'genre-secondary',
    String? secondarySubcategoryId = 'subcat-secondary',
    String? secondaryRegisterId = 'register-secondary',
    String genreId = 'genre-primary',
    String? subcategoryId = 'subcat-primary',
    String? registerId = 'register-primary',
    String cleaningStatus = 'cleaned',
    String format = 'm4a',
  }) async {
    await repo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(id),
        projectId: const Value('project-1'),
        genreId: Value(genreId),
        subcategoryId: Value(subcategoryId),
        registerId: Value(registerId),
        secondaryGenreId: Value(secondaryGenreId),
        secondarySubcategoryId: Value(secondarySubcategoryId),
        secondaryRegisterId: Value(secondaryRegisterId),
        storytellerId: Value(storytellerId),
        userId: Value(userId),
        title: const Value('Original recording'),
        description: Value(description),
        format: Value(format),
        localFilePath: const Value('/orig/path.m4a'),
        uploadStatus: const Value('verified'),
        serverId: const Value('server-orig'),
        gcsUrl: const Value('https://gcs.example/orig.m4a'),
        durationSeconds: const Value(60.0),
        fileSizeBytes: const Value(123456),
        cleaningStatus: Value(cleaningStatus),
        recordedAt: Value(DateTime.utc(2026, 5, 1, 10)),
      ),
    );
    final parent = await repo.getRecordingById(id);
    return localRecordingToEntity(parent!);
  }

  SplitSegmentSpec spec({
    required String id,
    String title = 'segment',
    String localFilePath = '/out/seg.m4a',
    double durationSeconds = 20.0,
    int fileSizeBytes = 40000,
    String? genreOverride,
    String? subcategoryOverride,
    String? registerOverride,
  }) {
    return SplitSegmentSpec(
      id: id,
      title: title,
      localFilePath: localFilePath,
      durationSeconds: durationSeconds,
      fileSizeBytes: fileSizeBytes,
      genreOverride: genreOverride,
      subcategoryOverride: subcategoryOverride,
      registerOverride: registerOverride,
    );
  }

  test('inherits description, storyteller, user, and secondary classification '
      'to every child', () async {
    final parent = await seedParent();

    await repo.splitRecordingReplacingParent(
      parent: parent,
      segments: [
        spec(id: 'c1', title: 'Recording (1/3)', localFilePath: '/o/1.m4a'),
        spec(id: 'c2', title: 'Recording (2/3)', localFilePath: '/o/2.m4a'),
        spec(id: 'c3', title: 'Recording (3/3)', localFilePath: '/o/3.m4a'),
      ],
    );

    for (final childId in ['c1', 'c2', 'c3']) {
      final child = await repo.getRecordingById(childId);
      expect(child, isNotNull, reason: 'child $childId should exist');
      expect(child!.description, 'A story told on a Sunday');
      expect(child.storytellerId, 'storyteller-7');
      expect(child.userId, 'user-42');
      expect(child.secondaryGenreId, 'genre-secondary');
      expect(child.secondarySubcategoryId, 'subcat-secondary');
      expect(child.secondaryRegisterId, 'register-secondary');
    }
  });

  test('resets cleaningStatus to "none" on every child', () async {
    final parent = await seedParent(cleaningStatus: 'cleaned');

    await repo.splitRecordingReplacingParent(
      parent: parent,
      segments: [
        spec(id: 'c1'),
        spec(id: 'c2'),
      ],
    );

    final c1 = await repo.getRecordingById('c1');
    final c2 = await repo.getRecordingById('c2');
    expect(c1!.cleaningStatus, 'none');
    expect(c2!.cleaningStatus, 'none');
  });

  test('each child carries its own segment-specific localFilePath, '
      'durationSeconds, fileSizeBytes, and title', () async {
    final parent = await seedParent();

    await repo.splitRecordingReplacingParent(
      parent: parent,
      segments: [
        spec(
          id: 'c1',
          title: 'first half',
          localFilePath: '/out/first.m4a',
          durationSeconds: 12.5,
          fileSizeBytes: 22222,
        ),
        spec(
          id: 'c2',
          title: 'second half',
          localFilePath: '/out/second.m4a',
          durationSeconds: 47.5,
          fileSizeBytes: 88888,
        ),
      ],
    );

    final c1 = await repo.getRecordingById('c1');
    final c2 = await repo.getRecordingById('c2');
    expect(c1!.title, 'first half');
    expect(c1.localFilePath, '/out/first.m4a');
    expect(c1.durationSeconds, 12.5);
    expect(c1.fileSizeBytes, 22222);
    expect(c2!.title, 'second half');
    expect(c2.localFilePath, '/out/second.m4a');
    expect(c2.durationSeconds, 47.5);
    expect(c2.fileSizeBytes, 88888);
  });

  test('each child is local-only (no serverId, no gcsUrl, uploadStatus=local, '
      'md5/uploadedBytes/resumable cleared)', () async {
    final parent = await seedParent();

    await repo.splitRecordingReplacingParent(
      parent: parent,
      segments: [spec(id: 'c1')],
    );

    final c1 = await repo.getRecordingById('c1');
    expect(c1!.uploadStatus, 'local');
    expect(c1.serverId, isNull);
    expect(c1.gcsUrl, isNull);
    expect(c1.md5Hash, isNull);
    expect(c1.uploadedBytes, 0);
    expect(c1.resumableSessionUri, isNull);
    expect(c1.retryCount, 0);
    expect(c1.lastRetryAt, isNull);
  });

  test('children leave splitFromId / splitIndex / splitSegmentCount unset '
      '(client deletes parent, so a back-link would dangle)', () async {
    final parent = await seedParent();

    await repo.splitRecordingReplacingParent(
      parent: parent,
      segments: [
        spec(id: 'c1'),
        spec(id: 'c2'),
      ],
    );

    final c1 = await repo.getRecordingById('c1');
    final c2 = await repo.getRecordingById('c2');
    expect(c1!.splitFromId, isNull);
    expect(c1.splitIndex, isNull);
    expect(c1.splitSegmentCount, isNull);
    expect(c2!.splitFromId, isNull);
    expect(c2.splitIndex, isNull);
    expect(c2.splitSegmentCount, isNull);
  });

  test('removes the parent row, leaving only the children', () async {
    final parent = await seedParent();

    await repo.splitRecordingReplacingParent(
      parent: parent,
      segments: [
        spec(id: 'c1'),
        spec(id: 'c2'),
      ],
    );

    expect(await repo.getRecordingById(parent.id), isNull);
    expect(await repo.getRecordingById('c1'), isNotNull);
    expect(await repo.getRecordingById('c2'), isNotNull);
  });

  test('null fields on parent stay null on children', () async {
    final parent = await seedParent(
      description: null,
      storytellerId: null,
      userId: null,
      secondaryGenreId: null,
      secondarySubcategoryId: null,
      secondaryRegisterId: null,
    );

    await repo.splitRecordingReplacingParent(
      parent: parent,
      segments: [spec(id: 'c1')],
    );

    final c1 = await repo.getRecordingById('c1');
    expect(c1!.description, isNull);
    expect(c1.storytellerId, isNull);
    expect(c1.userId, isNull);
    expect(c1.secondaryGenreId, isNull);
    expect(c1.secondarySubcategoryId, isNull);
    expect(c1.secondaryRegisterId, isNull);
  });

  test('per-segment classification override wins over parent for that child '
      'only', () async {
    final parent = await seedParent(
      genreId: 'parent-genre',
      subcategoryId: 'parent-subcat',
      registerId: 'parent-register',
    );

    await repo.splitRecordingReplacingParent(
      parent: parent,
      segments: [
        spec(
          id: 'c1',
          genreOverride: 'child1-genre',
          subcategoryOverride: 'child1-subcat',
          registerOverride: 'child1-register',
        ),
        spec(id: 'c2'),
      ],
    );

    final c1 = await repo.getRecordingById('c1');
    final c2 = await repo.getRecordingById('c2');
    expect(c1!.genreId, 'child1-genre');
    expect(c1.subcategoryId, 'child1-subcat');
    expect(c1.registerId, 'child1-register');
    expect(c2!.genreId, 'parent-genre');
    expect(c2.subcategoryId, 'parent-subcat');
    expect(c2.registerId, 'parent-register');
  });

  test('children inherit parent classification when no per-segment override is '
      'provided', () async {
    final parent = await seedParent(
      genreId: 'g',
      subcategoryId: 's',
      registerId: 'r',
    );

    await repo.splitRecordingReplacingParent(
      parent: parent,
      segments: [
        spec(id: 'c1'),
        spec(id: 'c2'),
      ],
    );

    final c1 = await repo.getRecordingById('c1');
    final c2 = await repo.getRecordingById('c2');
    expect(c1!.genreId, 'g');
    expect(c1.subcategoryId, 's');
    expect(c1.registerId, 'r');
    expect(c2!.genreId, 'g');
    expect(c2.subcategoryId, 's');
    expect(c2.registerId, 'r');
  });

  test('children carry parent recordedAt, projectId, and format', () async {
    final parent = await seedParent(format: 'wav');

    await repo.splitRecordingReplacingParent(
      parent: parent,
      segments: [spec(id: 'c1')],
    );

    final c1 = await repo.getRecordingById('c1');
    expect(c1!.projectId, parent.projectId);
    expect(c1.recordedAt, parent.recordedAt);
    expect(c1.format, 'wav');
  });

  test('returns the ids of the inserted children in order', () async {
    final parent = await seedParent();

    final ids = await repo.splitRecordingReplacingParent(
      parent: parent,
      segments: [
        spec(id: 'first'),
        spec(id: 'second'),
        spec(id: 'third'),
      ],
    );

    expect(ids, ['first', 'second', 'third']);
  });

  test('throws SegmentClassificationCollisionException and persists nothing '
      'when a segment resolves to the parent secondary triple', () async {
    final parent = await seedParent(
      secondaryRegisterId: 'register-conflict',
      secondaryGenreId: 'genre-conflict',
      secondarySubcategoryId: 'subcat-conflict',
    );

    await expectLater(
      repo.splitRecordingReplacingParent(
        parent: parent,
        segments: [
          spec(
            id: 'c1',
            registerOverride: 'register-conflict',
            genreOverride: 'genre-conflict',
            subcategoryOverride: 'subcat-conflict',
          ),
        ],
      ),
      throwsA(isA<SegmentClassificationCollisionException>()),
    );

    expect(await repo.getRecordingById('c1'), isNull);
    expect(await repo.getRecordingById('parent-1'), isNotNull);
  });

  test('persists the child when a segment shares the parent secondary genre '
      'but differs in subcategory', () async {
    final parent = await seedParent(
      secondaryRegisterId: 'register-conflict',
      secondaryGenreId: 'genre-conflict',
      secondarySubcategoryId: 'subcat-myth',
    );

    await repo.splitRecordingReplacingParent(
      parent: parent,
      segments: [
        spec(
          id: 'c1',
          registerOverride: 'register-conflict',
          genreOverride: 'genre-conflict',
          subcategoryOverride: 'subcat-legend',
        ),
      ],
    );

    final c1 = await repo.getRecordingById('c1');
    expect(c1, isNotNull);
    expect(c1!.genreId, 'genre-conflict');
    expect(c1.subcategoryId, 'subcat-legend');
    expect(c1.registerId, 'register-conflict');
  });

  test('does NOT throw when every override differs from the parent secondary '
      'triple', () async {
    final parent = await seedParent(
      secondaryGenreId: 'genre-secondary',
      secondarySubcategoryId: 'subcat-secondary',
      secondaryRegisterId: 'register-secondary',
    );

    await repo.splitRecordingReplacingParent(
      parent: parent,
      segments: [
        spec(
          id: 'c1',
          genreOverride: 'genre-other',
          subcategoryOverride: 'subcat-other',
          registerOverride: 'register-other',
        ),
      ],
    );

    final c1 = await repo.getRecordingById('c1');
    expect(c1, isNotNull);
    expect(c1!.genreId, 'genre-other');
    expect(c1.subcategoryId, 'subcat-other');
    expect(c1.registerId, 'register-other');
  });

  test('does NOT throw when the parent has no secondary genre set', () async {
    final parent = await seedParent(secondaryGenreId: null);

    await repo.splitRecordingReplacingParent(
      parent: parent,
      segments: [spec(id: 'c1', genreOverride: 'any-genre')],
    );

    final c1 = await repo.getRecordingById('c1');
    expect(c1, isNotNull);
    expect(c1!.genreId, 'any-genre');
  });
}
