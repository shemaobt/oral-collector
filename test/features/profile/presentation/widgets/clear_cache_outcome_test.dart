/// ENG-417: a clear that could not delete a file freed no space, and the person
/// has to learn that. "The server does not have it yet" is a reassurance;
/// "I could not delete it" is a report of space that was asked for and not got.
/// One number cannot say both, so the screen must not fold them together.
///
/// These run the REAL SyncNotifier over the REAL LocalRecordingRepository
/// (in-memory Drift) with real files in the system temp dir, and then read the
/// snackbar the profile screen shows for that outcome. Every assertion is about
/// the sentence a person reads, never about which methods were called.
library;

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/platform/file_ops.dart' as file_ops;
import 'package:oral_collector/features/profile/presentation/widgets/clear_cache_snack_bar.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/pending_metadata_field.dart';
import 'package:oral_collector/features/sync/data/providers.dart';
import 'package:oral_collector/features/sync/domain/repositories/connectivity_service.dart';
import 'package:oral_collector/features/sync/domain/repositories/sync_engine.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/text_scale.dart';

class _MockConnectivity extends Mock implements ConnectivityService {}

class _MockSyncEngine extends Mock implements SyncEngine {}

/// One seeded recording: the row's id and the file the row points at.
typedef _Seed = ({String id, File file});

void main() {
  final AppLocalizations l10n = AppLocalizationsEn();

  late AppDatabase db;
  late LocalRecordingRepository repo;
  late Directory dir;
  late List<Override> baseOverrides;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);
    dir = Directory.systemTemp.createTempSync('clear_cache_outcome');

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
  });

  tearDown(() async {
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

  /// Clears the cache with every path in [stuck] refusing to delete, then shows
  /// the snackbar the profile screen shows for whatever the clear reported.
  ///
  /// The outcome is handed straight from the notifier to the snackbar, which is
  /// the trip the screen makes — so the test never states what shape that
  /// outcome has, only what the person ends up reading.
  Future<void> clearAndShow(
    WidgetTester tester, {
    Set<String> stuck = const {},
  }) async {
    final container = ProviderContainer(
      overrides: [
        ...baseOverrides,
        deleteFileProvider.overrideWithValue((path) async {
          if (stuck.contains(path)) {
            throw const FileSystemException('permission denied');
          }
          await file_ops.deleteFile(path);
        }),
      ],
    );
    addTearDown(container.dispose);

    // The clear talks to a real database and real files, and the notifier's
    // build settles on a timer. Widget tests run on a fake clock where a timer
    // only fires between pumps, so this half has to run on the real one.
    final outcome = (await tester.runAsync(() async {
      container.read(syncNotifierProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      return container.read(syncNotifierProvider.notifier).clearLocalCache();
    }))!;

    await pumpAtTextScale(
      tester,
      child: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showClearCacheResultSnackBar(
            ScaffoldMessenger.of(context),
            AppLocalizations.of(context),
            outcome,
          ),
          child: const Text('trigger'),
        ),
      ),
    );
    await tester.tap(find.text('trigger'));
    await tester.pump(); // schedule the snackbar
    await tester.pump(const Duration(milliseconds: 400)); // entry animation
  }

  testWidgets('a file that would not delete is reported as space not freed', (
    tester,
  ) async {
    final stuck = await seed(
      'stuck',
      uploadStatus: 'verified',
      serverId: 'srv-stuck',
    );

    await clearAndShow(tester, stuck: {stuck.file.path});

    expect(find.text(l10n.profile_cacheNotFreed(1)), findsOneWidget);
    // The reassuring reason is a lie here: this recording is on the server, and
    // what kept it was a delete that failed.
    expect(find.text(l10n.profile_cacheClearedKept(1)), findsNothing);
  });

  testWidgets(
    'a clear that freed nothing does not claim the cache was cleared',
    (tester) async {
      final a = await seed('a', uploadStatus: 'verified', serverId: 'srv-a');
      final b = await seed('b', uploadStatus: 'verified', serverId: 'srv-b');

      await clearAndShow(tester, stuck: {a.file.path, b.file.path});

      expect(find.text(l10n.profile_cacheNotFreed(2)), findsOneWidget);
      // "Local cache cleared" alongside "nothing was freed" is a contradiction,
      // and it is the prefix both success sentences open with.
      expect(find.textContaining(l10n.profile_cacheCleared), findsNothing);
    },
  );

  testWidgets('both reasons are named when a clear runs into each', (
    tester,
  ) async {
    final stuck = await seed(
      'stuck',
      uploadStatus: 'verified',
      serverId: 'srv-stuck',
    );
    await seed('unsent', uploadStatus: 'local');

    await clearAndShow(tester, stuck: {stuck.file.path});

    expect(
      find.textContaining(l10n.profile_cacheKeptUnsent(1)),
      findsOneWidget,
    );
    expect(find.textContaining(l10n.profile_cacheNotFreed(1)), findsOneWidget);
  });

  testWidgets('an unsent recording is still the reason the clear names', (
    tester,
  ) async {
    await seed('unsent-a', uploadStatus: 'local');
    await seed('unsent-b', uploadStatus: 'failed');
    await seed('gone', uploadStatus: 'verified', serverId: 'srv-gone');

    await clearAndShow(tester);

    expect(find.text(l10n.profile_cacheClearedKept(2)), findsOneWidget);
  });

  testWidgets('a clear with nothing left behind reports plain success', (
    tester,
  ) async {
    await seed('gone', uploadStatus: 'verified', serverId: 'srv-gone');

    await clearAndShow(tester);

    expect(find.text(l10n.profile_cacheCleared), findsOneWidget);
  });

  testWidgets('an unsent edit reads as unsent, not as a failed delete', (
    tester,
  ) async {
    // ENG-416 keeps this row because the edit lives only here. The audio is on
    // the server and the file deleted fine, so nothing about space is wrong.
    await seed(
      'owes-edit',
      uploadStatus: 'verified',
      serverId: 'srv-owes',
      metadataSyncStatus: MetadataSyncStatus.pending,
      owes: {PendingMetadataField.title},
    );

    await clearAndShow(tester);

    expect(find.text(l10n.profile_cacheClearedKept(1)), findsOneWidget);
    expect(find.textContaining(l10n.profile_cacheNotFreed(1)), findsNothing);
  });
}
