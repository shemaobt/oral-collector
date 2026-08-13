/// ENG-422: the queue sheet shows a number and the list that number is about,
/// side by side. Since ENG-418 the header's pending count also counts a
/// recording that owes nothing but a metadata edit, and the sheet lists only
/// uploads — so a device owing edits read a number larger than the rows under
/// it.
///
/// These mount the real sheet over the REAL LocalRecordingRepository (in-memory
/// Drift) and the real SyncNotifier, so the number and the rows come from the
/// same seeded device. Every assertion is about what the two say to each other.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
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
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';
import 'package:oral_collector/shared/widgets/upload_queue_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/text_scale.dart';

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
  final AppLocalizations l10n = AppLocalizationsEn();

  late AppDatabase db;
  late LocalRecordingRepository repo;
  late List<Override> overrides;

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

    overrides = [
      connectivityServiceProvider.overrideWithValue(connectivity),
      syncEngineProvider.overrideWithValue(engine),
      localRecordingRepositoryProvider.overrideWithValue(repo),
      uploadForegroundServiceProvider.overrideWithValue(
        _NoopForegroundService(),
      ),
    ];
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seed(
    String id, {
    required String uploadStatus,
    String? serverId,
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
        fileSizeBytes: const Value(1024),
        recordedAt: Value(DateTime.utc(2026, 8, 1)),
        metadataSyncStatus: Value(metadataSyncStatus),
        pendingMetadataJson: Value(encodePendingMetadataFields(owes)),
      ),
    );
  }

  Future<void> openSheet(WidgetTester tester) async {
    await pumpAtTextScale(
      tester,
      overrides: overrides,
      child: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showUploadQueueSheet(context),
          child: const Text('open'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// A recording the server holds whose only outstanding work is an edit. It is
  /// pending work, so ENG-418 counts it — but no byte of it is going up, so the
  /// upload queue never lists it.
  Future<void> seedOwingOnlyAnEdit(String id) => seed(
    id,
    uploadStatus: 'verified',
    serverId: 'srv-$id',
    metadataSyncStatus: MetadataSyncStatus.pending,
    owes: {PendingMetadataField.title},
  );

  testWidgets('a device owing only edits lists nothing and counts nothing', (
    tester,
  ) async {
    await seedOwingOnlyAnEdit('edit-a');
    await seedOwingOnlyAnEdit('edit-b');

    await openSheet(tester);

    expect(find.text(l10n.recording_noPendingUploads), findsOneWidget);
    expect(find.text(l10n.sync_pending(0)), findsOneWidget);
  });

  testWidgets('the header counts the rows the sheet lists, not every pending', (
    tester,
  ) async {
    await seed('up-a', uploadStatus: 'local');
    await seedOwingOnlyAnEdit('edit-a');
    await seedOwingOnlyAnEdit('edit-b');

    await openSheet(tester);

    expect(find.text('up-a'), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text(l10n.sync_pending(1)), findsOneWidget);
  });

  testWidgets('a device with pending uploads sees each of them counted', (
    tester,
  ) async {
    await seed('up-a', uploadStatus: 'local');
    await seed('up-b', uploadStatus: 'failed');
    await seed('done', uploadStatus: 'verified', serverId: 'srv-done');

    await openSheet(tester);

    expect(find.text('up-a'), findsOneWidget);
    expect(find.text('up-b'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(find.text(l10n.sync_pending(2)), findsOneWidget);
  });
}
