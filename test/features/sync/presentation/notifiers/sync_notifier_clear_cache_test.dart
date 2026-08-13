/// ENG-407: clearing the local cache must not destroy a recording the server
/// does not have. A field report cost an hour-long story this way.
///
/// These run SyncNotifier over the REAL LocalRecordingRepository (in-memory
/// Drift) with real files in the system temp dir, so every assertion is about
/// what survives on the device — which files are still there and which rows are
/// still in the database — never about which repository methods were called.
library;

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/platform/file_ops.dart' as file_ops;
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/pending_metadata_field.dart';
import 'package:oral_collector/features/sync/data/providers.dart';
import 'package:oral_collector/features/sync/domain/repositories/connectivity_service.dart';
import 'package:oral_collector/features/sync/domain/repositories/sync_engine.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockConnectivity extends Mock implements ConnectivityService {}

class _MockSyncEngine extends Mock implements SyncEngine {}

/// One seeded recording: the row's id and the file the row points at.
typedef _Seed = ({String id, File file});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalRecordingRepository repo;
  late ProviderContainer container;
  late Directory dir;
  late List<Override> baseOverrides;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);
    dir = Directory.systemTemp.createTempSync('clear_local_cache');

    final connectivity = _MockConnectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(() => connectivity.isOnWifi).thenAnswer((_) async => true);
    when(
      () => connectivity.onConnectivityChanged,
    ).thenAnswer((_) => const Stream.empty());

    baseOverrides = [
      connectivityServiceProvider.overrideWithValue(connectivity),
      syncEngineProvider.overrideWithValue(_MockSyncEngine()),
      localRecordingRepositoryProvider.overrideWithValue(repo),
    ];
    container = ProviderContainer(overrides: baseOverrides);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<_Seed> seed(
    String id, {
    required String uploadStatus,
    String? serverId,
    String metadataSyncStatus = MetadataSyncStatus.synced,
    Set<PendingMetadataField> owes = const {},
  }) async {
    final file = File('${dir.path}/$id.m4a')
      ..writeAsBytesSync(List.filled(8, 0));
    await repo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(id),
        projectId: const Value('proj-1'),
        genreId: const Value('genre-1'),
        title: Value(id),
        localFilePath: Value(file.path),
        uploadStatus: Value(uploadStatus),
        serverId: Value(serverId),
        recordedAt: Value(DateTime.utc(2026, 8, 1)),
        metadataSyncStatus: Value(metadataSyncStatus),
        pendingMetadataJson: Value(encodePendingMetadataFields(owes)),
      ),
    );
    return (id: id, file: file);
  }

  /// The notifier after its build() continuations have settled.
  Future<SyncNotifier> notifier() async {
    final n = container.read(syncNotifierProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    return n;
  }

  Future<void> expectSurvived(_Seed s) async {
    expect(s.file.existsSync(), isTrue, reason: '${s.id}: file was deleted');
    expect(
      await repo.getRecordingById(s.id),
      isNotNull,
      reason: '${s.id}: row',
    );
  }

  Future<void> expectDiscarded(_Seed s) async {
    expect(s.file.existsSync(), isFalse, reason: '${s.id}: file survived');
    expect(await repo.getRecordingById(s.id), isNull, reason: '${s.id}: row');
  }

  test('a recording the server does not have survives the clear', () async {
    final onServer = await seed(
      'on-server',
      uploadStatus: 'verified',
      serverId: 'srv-1',
    );
    final onlyOnDevice = await seed('only-on-device', uploadStatus: 'failed');

    await (await notifier()).clearLocalCache();

    await expectDiscarded(onServer);
    await expectSurvived(onlyOnDevice);
  });

  test('the criterion needs both an uploaded status and a server id', () async {
    // `uploaded` with no id is the case that names the criterion: markAsUploaded
    // writes the status and the id together, so a row missing the id never
    // completed the round trip and the server may not have the audio at all.
    const survivors = <(String, String?)>[
      ('local', null),
      ('uploading', null),
      ('failed', null),
      ('failed_exhausted', null),
      ('uploaded', null),
      ('uploaded', ''),
    ];
    const discarded = <(String, String?)>[
      ('uploaded', 'srv-uploaded'),
      ('verified', 'srv-verified'),
    ];

    final kept = <_Seed>[];
    for (var i = 0; i < survivors.length; i++) {
      kept.add(
        await seed(
          'keep-${survivors[i].$1}-$i',
          uploadStatus: survivors[i].$1,
          serverId: survivors[i].$2,
        ),
      );
    }
    final dropped = <_Seed>[];
    for (var i = 0; i < discarded.length; i++) {
      dropped.add(
        await seed(
          'drop-${discarded[i].$1}-$i',
          uploadStatus: discarded[i].$1,
          serverId: discarded[i].$2,
        ),
      );
    }

    await (await notifier()).clearLocalCache();

    for (final s in kept) {
      await expectSurvived(s);
    }
    for (final s in dropped) {
      await expectDiscarded(s);
    }
  });

  test('reports how many recordings stayed on the device', () async {
    await seed('a', uploadStatus: 'failed');
    await seed('b', uploadStatus: 'local');
    await seed('c', uploadStatus: 'verified', serverId: 'srv-c');

    final outcome = await (await notifier()).clearLocalCache();

    expect(outcome.keptUnsent, 2);
    expect(outcome.keptUndeletable, 0);
    expect(
      outcome.keptUnsent + outcome.keptUndeletable,
      (await repo.getAllLocalRecordings()).length,
    );
  });

  test('reports nothing kept when the server already had everything', () async {
    await seed('a', uploadStatus: 'verified', serverId: 'srv-a');
    await seed('b', uploadStatus: 'uploaded', serverId: 'srv-b');

    final outcome = await (await notifier()).clearLocalCache();

    expect(outcome.keptUnsent, 0);
    expect(outcome.keptUndeletable, 0);
    expect(await repo.getAllLocalRecordings(), isEmpty);
  });

  test('keeps everything when the server had nothing', () async {
    final a = await seed('a', uploadStatus: 'local');
    final b = await seed('b', uploadStatus: 'failed_exhausted');

    final outcome = await (await notifier()).clearLocalCache();

    expect(outcome.keptUnsent, 2);
    expect(outcome.keptUndeletable, 0);
    await expectSurvived(a);
    await expectSurvived(b);
  });

  test(
    'a file that will not delete keeps its row rather than orphaning',
    () async {
      // A row is the only thing that can find the file again — the storage
      // figure and any later clear both walk the rows. Dropping the row after a
      // failed delete strands the audio on disk forever and reports space that
      // was never freed.
      final stuck = await seed(
        'stuck',
        uploadStatus: 'verified',
        serverId: 'srv-stuck',
      );
      final fine = await seed(
        'fine',
        uploadStatus: 'verified',
        serverId: 'srv-fine',
      );

      final failing = ProviderContainer(
        overrides: [
          ...baseOverrides,
          deleteFileProvider.overrideWithValue((path) async {
            if (path == stuck.file.path) {
              throw const FileSystemException('permission denied');
            }
            await file_ops.deleteFile(path);
          }),
        ],
      );
      addTearDown(failing.dispose);

      final n = failing.read(syncNotifierProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      final outcome = await n.clearLocalCache();

      await expectSurvived(stuck);
      await expectDiscarded(fine);
      // The server has this recording, so nothing about it is unsent: what kept
      // it is the delete that failed, and that is the half the screen has to
      // report as space it did not free (ENG-417).
      expect(outcome.keptUndeletable, 1);
      expect(outcome.keptUnsent, 0);
    },
  );

  test('a recording owing an unsent edit survives the clear', () async {
    // ENG-416: the server has the audio, so the old criterion discarded this
    // row — but the edit the user typed exists on this device and nowhere
    // else, and dropping the row destroys it.
    final owesEdit = await seed(
      'owes-edit',
      uploadStatus: 'verified',
      serverId: 'srv-owes',
      metadataSyncStatus: MetadataSyncStatus.pending,
      owes: {PendingMetadataField.title},
    );
    final owesNothing = await seed(
      'owes-nothing',
      uploadStatus: 'verified',
      serverId: 'srv-nothing',
    );

    final outcome = await (await notifier()).clearLocalCache();

    await expectSurvived(owesEdit);
    await expectDiscarded(owesNothing);
    expect(outcome.keptUnsent, 1);
    expect(outcome.keptUndeletable, 0);
  });

  test(
    'an edit the server refused for permission does not keep the copy',
    () async {
      // `failed_forbidden` is the one terminal edit with no way out from this
      // device: the user cannot grant themselves permission, so the edit has no
      // destination — the same reason a 404 lets the heal path erase a row.
      // Keeping the copy for it would make a recording the clear can never
      // discard.
      final forbidden = await seed(
        'forbidden',
        uploadStatus: 'verified',
        serverId: 'srv-forbidden',
        metadataSyncStatus: MetadataSyncStatus.failedForbidden,
        owes: {PendingMetadataField.title},
      );

      final outcome = await (await notifier()).clearLocalCache();

      await expectDiscarded(forbidden);
      expect(outcome.keptUnsent, 0);
      expect(outcome.keptUndeletable, 0);
    },
  );

  test('a terminal edit the user can still push survives the clear', () async {
    // Both of these are recoverable from the phone — a rename lifts the clash,
    // a fresh edit revives the spent budget — so the edit can still reach the
    // server and the clear must not destroy it first.
    final conflict = await seed(
      'conflict',
      uploadStatus: 'verified',
      serverId: 'srv-conflict',
      metadataSyncStatus: MetadataSyncStatus.failedConflict,
      owes: {PendingMetadataField.title},
    );
    final exhausted = await seed(
      'exhausted',
      uploadStatus: 'verified',
      serverId: 'srv-exhausted',
      metadataSyncStatus: MetadataSyncStatus.failedExhausted,
      owes: {PendingMetadataField.description},
    );

    final outcome = await (await notifier()).clearLocalCache();

    await expectSurvived(conflict);
    await expectSurvived(exhausted);
    expect(outcome.keptUnsent, 2);
    expect(outcome.keptUndeletable, 0);
  });

  test('the pending count reflects what stayed behind', () async {
    await seed('kept-failed', uploadStatus: 'failed');
    await seed('kept-local', uploadStatus: 'local');
    await seed('gone', uploadStatus: 'verified', serverId: 'srv-gone');

    await (await notifier()).clearLocalCache();

    final remaining = await repo.getAllLocalRecordings();
    // Every surviving row is in a pending state here, so the number of rows
    // left is an independent oracle for the count the header shows.
    expect(container.read(syncNotifierProvider).pendingCount, remaining.length);
    // Without this the assertion above would hold vacuously at zero.
    expect(remaining, hasLength(2));
  });
}
