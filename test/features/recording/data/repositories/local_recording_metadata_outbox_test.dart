/// The metadata outbox's persisted state (ENG-403).
///
/// An edit made offline is written to the local row and used to stop there.
/// These pin the columns that remember the server is still owed it: what is
/// owed, the retry bookkeeping, and the terminal states that take a row out of
/// the queue for good.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/config/upload_retry_policy.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/pending_metadata_field.dart';

void main() {
  late AppDatabase db;
  late LocalRecordingRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);
  });
  tearDown(() => db.close());

  Future<void> seed({
    String id = 'rec-1',
    String? serverId = 'srv-1',
    DateTime? createdAt,
  }) async {
    await repo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(id),
        projectId: const Value('proj'),
        genreId: const Value('genre-1'),
        localFilePath: Value('/audio/$id.m4a'),
        serverId: Value(serverId),
        uploadStatus: const Value('verified'),
        recordedAt: Value(DateTime.utc(2026, 5, 1)),
        createdAt: Value(createdAt ?? DateTime.utc(2026, 5, 1)),
      ),
    );
  }

  group('marking an edit as owed', () {
    test('names the fields and queues the row', () async {
      await seed();

      await repo.markMetadataPending('rec-1', {
        PendingMetadataField.cleaningStatus,
      });

      final row = (await repo.getRecordingById('rec-1'))!;
      expect(row.metadataSyncStatus, MetadataSyncStatus.pending);
      expect(decodePendingMetadataFields(row.pendingMetadataJson), {
        PendingMetadataField.cleaningStatus,
      });
    });

    test('survives a restart', () async {
      await seed();
      await repo.markMetadataPending('rec-1', {PendingMetadataField.title});

      // A fresh repository over the same database is what the next launch
      // sees: the pendency is a column, not something held in memory.
      final afterRestart = LocalRecordingRepository(db);
      final row = (await afterRestart.getRecordingById('rec-1'))!;

      expect(row.metadataSyncStatus, MetadataSyncStatus.pending);
      expect(decodePendingMetadataFields(row.pendingMetadataJson), {
        PendingMetadataField.title,
      });
      expect(await afterRestart.getPendingMetadataSyncs(), hasLength(1));
    });

    test('unions successive edits instead of replacing them', () async {
      await seed();

      await repo.markMetadataPending('rec-1', {PendingMetadataField.title});
      await repo.markMetadataPending('rec-1', {
        PendingMetadataField.description,
      });

      final row = (await repo.getRecordingById('rec-1'))!;
      expect(decodePendingMetadataFields(row.pendingMetadataJson), {
        PendingMetadataField.title,
        PendingMetadataField.description,
      });
    });

    test('hands a re-edited row a fresh retry budget', () async {
      // A new edit is a new intent: it must lift a terminal status and make the
      // row drainable again. This is the exit from a title clash — the rename
      // is what clears it.
      await seed();
      await repo.markMetadataPending('rec-1', {PendingMetadataField.title});
      await repo.markMetadataSyncTerminal(
        'rec-1',
        status: MetadataSyncStatus.failedConflict,
      );

      await repo.markMetadataPending('rec-1', {PendingMetadataField.title});

      final row = (await repo.getRecordingById('rec-1'))!;
      expect(row.metadataSyncStatus, MetadataSyncStatus.pending);
      expect(row.metadataRetryCount, 0);
      expect(row.metadataLastRetryAt, isNull);
    });
  });

  group('what the drain selects', () {
    test('only rows that owe something, oldest first', () async {
      await seed(id: 'newer', createdAt: DateTime.utc(2026, 5, 2));
      await seed(id: 'older', createdAt: DateTime.utc(2026, 5, 1));
      await seed(id: 'quiet');
      await repo.markMetadataPending('newer', {PendingMetadataField.title});
      await repo.markMetadataPending('older', {PendingMetadataField.title});

      final pending = await repo.getPendingMetadataSyncs();

      expect(pending.map((r) => r.id), ['older', 'newer']);
    });

    test('never a row the server has never seen', () async {
      // Without a serverId there is nothing to PATCH — the metadata rides along
      // on the upload's create call instead.
      await seed(id: 'rec-1', serverId: null);
      await repo.markMetadataPending('rec-1', {PendingMetadataField.title});

      expect(await repo.getPendingMetadataSyncs(), isEmpty);
    });

    test('never a row parked in a terminal state', () async {
      await seed();
      await repo.markMetadataPending('rec-1', {PendingMetadataField.title});
      await repo.markMetadataSyncTerminal(
        'rec-1',
        status: MetadataSyncStatus.failedForbidden,
      );

      expect(await repo.getPendingMetadataSyncs(), isEmpty);
    });
  });

  group('clearing what the server took', () {
    test(
      'drops the pushed fields and leaves the row out of the queue',
      () async {
        await seed();
        await repo.markMetadataPending('rec-1', {PendingMetadataField.title});

        await repo.clearPendingMetadataFields('rec-1', {
          PendingMetadataField.title,
        });

        final row = (await repo.getRecordingById('rec-1'))!;
        expect(row.metadataSyncStatus, MetadataSyncStatus.synced);
        expect(row.pendingMetadataJson, '[]');
        expect(await repo.getPendingMetadataSyncs(), isEmpty);
      },
    );

    test('keeps the row queued while something is still owed', () async {
      await seed();
      await repo.markMetadataPending('rec-1', {
        PendingMetadataField.title,
        PendingMetadataField.cleaningStatus,
      });

      await repo.clearPendingMetadataFields('rec-1', {
        PendingMetadataField.title,
      });

      final row = (await repo.getRecordingById('rec-1'))!;
      expect(row.metadataSyncStatus, MetadataSyncStatus.pending);
      expect(decodePendingMetadataFields(row.pendingMetadataJson), {
        PendingMetadataField.cleaningStatus,
      });
    });
  });

  group('spending the retry budget', () {
    test('counts one attempt and stamps the time', () async {
      await seed();
      await repo.markMetadataPending('rec-1', {PendingMetadataField.title});

      await repo.markMetadataSyncFailed('rec-1');

      final row = (await repo.getRecordingById('rec-1'))!;
      expect(row.metadataSyncStatus, MetadataSyncStatus.pending);
      expect(row.metadataRetryCount, 1);
      expect(row.metadataLastRetryAt, isNotNull);
    });

    test('retires the row on the attempt that spends the last one', () async {
      await seed();
      await repo.markMetadataPending('rec-1', {PendingMetadataField.title});

      for (var i = 0; i < kMaxUploadRetries; i++) {
        await repo.markMetadataSyncFailed('rec-1');
      }

      final row = (await repo.getRecordingById('rec-1'))!;
      expect(row.metadataSyncStatus, MetadataSyncStatus.failedExhausted);
      expect(row.metadataRetryCount, kMaxUploadRetries);
      // The edit itself is kept: the user still typed it, and the row is what
      // the screen reads to say what is stuck.
      expect(decodePendingMetadataFields(row.pendingMetadataJson), {
        PendingMetadataField.title,
      });
      expect(await repo.getPendingMetadataSyncs(), isEmpty);
    });
  });
}
