/// ENG-418: a metadata edit that has not gone up yet is pending work, so the
/// header counts it — and only the audio still waiting to transfer counts
/// towards the queue's byte total.
///
/// These run SyncNotifier over the REAL LocalRecordingRepository (in-memory
/// Drift), so every assertion is about the numbers the screen shows for rows
/// that really are in the database, never about which repository methods were
/// called.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/pending_metadata_field.dart';
import 'package:oral_collector/features/sync/data/providers.dart';
import 'package:oral_collector/features/sync/data/services/upload_foreground_service.dart';
import 'package:oral_collector/features/sync/domain/repositories/connectivity_service.dart';
import 'package:oral_collector/features/sync/domain/repositories/sync_engine.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockConnectivity extends Mock implements ConnectivityService {}

class _MockSyncEngine extends Mock implements SyncEngine {}

class _NoopForegroundService implements UploadForegroundService {
  @override
  bool get isRunning => false;

  @override
  Future<void> start({
    required Future<String> Function() titleResolver,
    required String body,
  }) async {}

  @override
  Future<void> updateProgress({
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> stop() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalRecordingRepository repo;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);

    final connectivity = _MockConnectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(() => connectivity.isOnWifi).thenAnswer((_) async => true);
    when(
      () => connectivity.onConnectivityChanged,
    ).thenAnswer((_) => const Stream.empty());

    final engine = _MockSyncEngine();
    when(
      () => engine.processQueue(
        deleteAfterUpload: any(named: 'deleteAfterUpload'),
        wifiOnly: any(named: 'wifiOnly'),
        maxConcurrency: any(named: 'maxConcurrency'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((_) async {});
    when(() => engine.processPendingMetadata()).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        connectivityServiceProvider.overrideWithValue(connectivity),
        syncEngineProvider.overrideWithValue(engine),
        localRecordingRepositoryProvider.overrideWithValue(repo),
        uploadForegroundServiceProvider.overrideWithValue(
          _NoopForegroundService(),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<String> seed(
    String id, {
    required String uploadStatus,
    String? serverId,
    int fileSizeBytes = 1024,
    String metadataSyncStatus = MetadataSyncStatus.synced,
    Set<PendingMetadataField> owes = const {},
  }) async {
    await repo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(id),
        projectId: const Value('proj-1'),
        genreId: const Value('genre-1'),
        title: Value(id),
        localFilePath: Value('/tmp/$id.m4a'),
        uploadStatus: Value(uploadStatus),
        serverId: Value(serverId),
        fileSizeBytes: Value(fileSizeBytes),
        recordedAt: Value(DateTime.utc(2026, 8, 1)),
        metadataSyncStatus: Value(metadataSyncStatus),
        pendingMetadataJson: Value(encodePendingMetadataFields(owes)),
      ),
    );
    return id;
  }

  /// The notifier after its build() continuations — including the first count
  /// refresh — have settled.
  Future<SyncNotifier> notifier() async {
    final n = container.read(syncNotifierProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    return n;
  }

  int pendingCount() => container.read(syncNotifierProvider).pendingCount;
  int totalQueueSizeBytes() =>
      container.read(syncNotifierProvider).totalQueueSizeBytes;

  test('a recording that owes only an edit is counted', () async {
    await seed(
      'owes-an-edit',
      uploadStatus: 'verified',
      serverId: 'srv-1',
      metadataSyncStatus: MetadataSyncStatus.pending,
      owes: {PendingMetadataField.title},
    );

    await notifier();

    expect(pendingCount(), 1);
  });

  test('a recording owing both an upload and an edit is counted once', () async {
    // The overlap is the shape replaceAudioAndQueueResend writes (ENG-402): the
    // row goes back to `local` for the new bytes *and* owes the server the new
    // duration/size before they arrive.
    final owed = {
      await seed('upload-only', uploadStatus: 'local'),
      await seed(
        'edit-only',
        uploadStatus: 'verified',
        serverId: 'srv-edit',
        metadataSyncStatus: MetadataSyncStatus.pending,
        owes: {PendingMetadataField.description},
      ),
      await seed(
        'both',
        uploadStatus: 'local',
        serverId: 'srv-both',
        metadataSyncStatus: MetadataSyncStatus.pending,
        owes: {PendingMetadataField.audio},
      ),
    };

    await notifier();

    expect(pendingCount(), owed.length);
  });

  test('the count returns to zero once the last edit goes up', () async {
    final id = await seed(
      'owes-an-edit',
      uploadStatus: 'verified',
      serverId: 'srv-1',
      metadataSyncStatus: MetadataSyncStatus.pending,
      owes: {PendingMetadataField.title},
    );
    final n = await notifier();
    expect(
      pendingCount(),
      1,
      reason: 'the seeded edit must count to begin with',
    );

    await repo.clearPendingMetadataFields(id, {PendingMetadataField.title});
    await n.processQueue();

    expect(pendingCount(), 0);
  });

  test('the count follows the edits that go up while uploads wait', () async {
    // The Wi-Fi-only gate holds back the uploads, not the outbox (ENG-403): the
    // edits really do go up on that pass, so the number they were counted in
    // has to be recomputed before it returns.
    final id = await seed(
      'owes-an-edit',
      uploadStatus: 'verified',
      serverId: 'srv-1',
      metadataSyncStatus: MetadataSyncStatus.pending,
      owes: {PendingMetadataField.title},
    );
    final connectivity = _MockConnectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(() => connectivity.isOnWifi).thenAnswer((_) async => false);
    when(
      () => connectivity.onConnectivityChanged,
    ).thenAnswer((_) => const Stream.empty());
    final engine = _MockSyncEngine();
    when(() => engine.processPendingMetadata()).thenAnswer((_) async {
      await repo.clearPendingMetadataFields(id, {PendingMetadataField.title});
    });
    final cellular = ProviderContainer(
      overrides: [
        connectivityServiceProvider.overrideWithValue(connectivity),
        syncEngineProvider.overrideWithValue(engine),
        localRecordingRepositoryProvider.overrideWithValue(repo),
        uploadForegroundServiceProvider.overrideWithValue(
          _NoopForegroundService(),
        ),
      ],
    );
    addTearDown(cellular.dispose);

    final n = cellular.read(syncNotifierProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    expect(
      cellular.read(syncNotifierProvider).pendingCount,
      1,
      reason: 'the seeded edit must count to begin with',
    );
    await n.processQueue();

    expect(cellular.read(syncNotifierProvider).pendingCount, 0);
  });

  test('an edit adds to the count but not to the bytes to transfer', () async {
    // totalQueueSizeBytes describes audio still to transfer, and drives the
    // "how much is left" figure on screen. A PATCH is a few hundred bytes, so
    // adding this recording's audio size to it would inflate that figure by a
    // file that is already on the server.
    await seed('upload-only', uploadStatus: 'local', fileSizeBytes: 1024);
    await seed(
      'edit-only',
      uploadStatus: 'verified',
      serverId: 'srv-edit',
      fileSizeBytes: 8 * 1024 * 1024,
      metadataSyncStatus: MetadataSyncStatus.pending,
      owes: {PendingMetadataField.title},
    );

    await notifier();

    expect(pendingCount(), 2);
    expect(totalQueueSizeBytes(), 1024);
  });
}
