/// Tests for LocalRecordingRepository.cacheDownloadedAudio.
///
/// Reproduces and guards against ENG-64: when the user opens a server-only
/// recording and triggers a download (e.g. tapping "Edit"), every metadata
/// field on the in-memory recording must end up on the persisted row, not
/// just a hand-picked subset.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/domain/entities/review_flag.dart';

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

  LocalRecordingEntity buildIncoming({
    String id = 'rec-1',
    String? description = 'A story told on a Sunday',
    String? storytellerId = 'storyteller-7',
    String? userId = 'user-42',
    String? secondaryGenreId = 'genre-secondary',
    String? secondarySubcategoryId = 'subcat-secondary',
    String? secondaryRegisterId = 'register-secondary',
    String genreId = 'genre-primary',
    String? subcategoryId = 'subcat-primary',
    String? registerId = 'register-primary',
    String? splitFromId,
    int? splitIndex,
    int? splitSegmentCount,
    String localFilePath = '',
    List<ReviewFlag> reviewFlags = const [],
  }) {
    final now = DateTime.utc(2026, 5, 1, 10);
    return LocalRecordingEntity(
      id: id,
      projectId: 'project-1',
      genreId: genreId,
      subcategoryId: subcategoryId,
      registerId: registerId,
      secondaryGenreId: secondaryGenreId,
      secondarySubcategoryId: secondarySubcategoryId,
      secondaryRegisterId: secondaryRegisterId,
      storytellerId: storytellerId,
      userId: userId,
      title: 'Recording title',
      description: description,
      durationSeconds: 90.0,
      fileSizeBytes: 555000,
      format: 'm4a',
      localFilePath: localFilePath,
      uploadStatus: 'verified',
      serverId: id,
      gcsUrl: 'https://gcs.example/$id.m4a',
      cleaningStatus: 'cleaned',
      recordedAt: now,
      createdAt: now,
      retryCount: 0,
      uploadedBytes: 0,
      splitFromId: splitFromId,
      splitIndex: splitIndex,
      splitSegmentCount: splitSegmentCount,
      reviewFlags: reviewFlags,
    );
  }

  test('persists every metadata field when the recording is not yet local '
      '(reproduces ENG-64)', () async {
    final incoming = buildIncoming();

    await repo.cacheDownloadedAudio(
      recording: incoming,
      localFilePath: '/local/cache/rec-1.m4a',
    );

    final saved = await repo.getRecordingById('rec-1');
    expect(saved, isNotNull);
    expect(saved!.localFilePath, '/local/cache/rec-1.m4a');
    expect(saved.description, 'A story told on a Sunday');
    expect(saved.storytellerId, 'storyteller-7');
    expect(saved.userId, 'user-42');
    expect(saved.secondaryGenreId, 'genre-secondary');
    expect(saved.secondarySubcategoryId, 'subcat-secondary');
    expect(saved.secondaryRegisterId, 'register-secondary');
    expect(saved.genreId, 'genre-primary');
    expect(saved.subcategoryId, 'subcat-primary');
    expect(saved.registerId, 'register-primary');
    expect(saved.title, 'Recording title');
    expect(saved.serverId, 'rec-1');
    expect(saved.gcsUrl, 'https://gcs.example/rec-1.m4a');
    expect(saved.uploadStatus, 'verified');
    expect(saved.cleaningStatus, 'cleaned');
    expect(saved.durationSeconds, 90.0);
    expect(saved.fileSizeBytes, 555000);
    expect(saved.format, 'm4a');
  });

  test('preserves null metadata fields as null on the persisted row', () async {
    final incoming = buildIncoming(
      description: null,
      storytellerId: null,
      userId: null,
      secondaryGenreId: null,
      secondarySubcategoryId: null,
      secondaryRegisterId: null,
    );

    await repo.cacheDownloadedAudio(
      recording: incoming,
      localFilePath: '/local/cache/rec-1.m4a',
    );

    final saved = await repo.getRecordingById('rec-1');
    expect(saved, isNotNull);
    expect(saved!.description, isNull);
    expect(saved.storytellerId, isNull);
    expect(saved.userId, isNull);
    expect(saved.secondaryGenreId, isNull);
    expect(saved.secondarySubcategoryId, isNull);
    expect(saved.secondaryRegisterId, isNull);
  });

  test('when the row already exists locally, only localFilePath is updated; '
      'pre-existing local edits are preserved', () async {
    final original = buildIncoming(
      description: 'edited offline',
      storytellerId: 's-local-edit',
      secondaryGenreId: 'g-local-edit',
    );
    await repo.cacheDownloadedAudio(
      recording: original,
      localFilePath: '/old/path.m4a',
    );

    final fromServer = buildIncoming(
      description: 'stale server description',
      storytellerId: 's-server-stale',
      secondaryGenreId: 'g-server-stale',
    );

    await repo.cacheDownloadedAudio(
      recording: fromServer,
      localFilePath: '/new/path.m4a',
    );

    final saved = await repo.getRecordingById('rec-1');
    expect(saved, isNotNull);
    expect(saved!.localFilePath, '/new/path.m4a');
    expect(saved.description, 'edited offline');
    expect(saved.storytellerId, 's-local-edit');
    expect(saved.secondaryGenreId, 'g-local-edit');
  });

  test('propagates split lineage fields when present on incoming', () async {
    final incoming = buildIncoming(
      splitFromId: 'parent-99',
      splitIndex: 2,
      splitSegmentCount: 5,
    );

    await repo.cacheDownloadedAudio(
      recording: incoming,
      localFilePath: '/local/cache/rec-1.m4a',
    );

    final saved = await repo.getRecordingById('rec-1');
    expect(saved, isNotNull);
    expect(saved!.splitFromId, 'parent-99');
    expect(saved.splitIndex, 2);
    expect(saved.splitSegmentCount, 5);
  });

  test('what the recording still owes reaches the row, so it survives '
      'offline', () async {
    final incoming = buildIncoming(
      reviewFlags: const [
        ReviewFlag(code: 'missing_classification', origin: 'system'),
        ReviewFlag(code: 'missing_storyteller', origin: 'system'),
      ],
    );

    await repo.cacheDownloadedAudio(
      recording: incoming,
      localFilePath: '/local/cache/rec-1.m4a',
    );

    final saved = await repo.getRecordingEntityById('rec-1');
    expect(saved, isNotNull);
    expect(saved!.reviewFlags, incoming.reviewFlags);
  });

  test('a row whose flags are no longer readable still yields the '
      'recording', () async {
    await repo.cacheDownloadedAudio(
      recording: buildIncoming(
        reviewFlags: const [
          ReviewFlag(code: 'missing_storyteller', origin: 'system'),
        ],
      ),
      localFilePath: '/local/cache/rec-1.m4a',
    );

    await db.customStatement(
      "UPDATE local_recordings SET review_flags_json = 'not json at all' "
      "WHERE id = 'rec-1'",
    );

    final saved = await repo.getRecordingEntityById('rec-1');
    expect(saved, isNotNull);
    expect(saved!.title, 'Recording title');
    expect(saved.reviewFlags, isEmpty);
  });

  test('is idempotent across repeated calls with different paths', () async {
    final incoming = buildIncoming();

    await repo.cacheDownloadedAudio(
      recording: incoming,
      localFilePath: '/local/cache/first.m4a',
    );
    await repo.cacheDownloadedAudio(
      recording: incoming,
      localFilePath: '/local/cache/second.m4a',
    );

    final saved = await repo.getRecordingById('rec-1');
    expect(saved, isNotNull);
    expect(saved!.localFilePath, '/local/cache/second.m4a');
    expect(saved.description, 'A story told on a Sunday');
  });
}
