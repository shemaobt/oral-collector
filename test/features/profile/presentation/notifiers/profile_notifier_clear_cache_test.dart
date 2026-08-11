/// ENG-407: the count of kept recordings has to survive the trip from
/// SyncNotifier to the profile screen. A dropped return value here would leave
/// the screen announcing plain success over a device that freed nothing, and
/// every test of the two ends in isolation would still pass.
library;

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/sync/data/providers.dart';
import 'package:oral_collector/features/sync/domain/repositories/connectivity_service.dart';
import 'package:oral_collector/features/sync/domain/repositories/sync_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockConnectivity extends Mock implements ConnectivityService {}

class _MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalRecordingRepository repo;
  late ProviderContainer container;
  late Directory dir;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);
    dir = Directory.systemTemp.createTempSync('profile_clear_cache');

    final connectivity = _MockConnectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(() => connectivity.isOnWifi).thenAnswer((_) async => true);
    when(
      () => connectivity.onConnectivityChanged,
    ).thenAnswer((_) => const Stream.empty());

    container = ProviderContainer(
      overrides: [
        connectivityServiceProvider.overrideWithValue(connectivity),
        syncEngineProvider.overrideWithValue(_MockSyncEngine()),
        localRecordingRepositoryProvider.overrideWithValue(repo),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<void> seed(
    String id, {
    required String uploadStatus,
    String? serverId,
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
      ),
    );
  }

  test('clearCacheAndRefresh reports the recordings it kept', () async {
    await seed('unsent-1', uploadStatus: 'local');
    await seed('unsent-2', uploadStatus: 'failed');
    await seed('on-server', uploadStatus: 'verified', serverId: 'srv-1');

    final kept = await container
        .read(profileNotifierProvider.notifier)
        .clearCacheAndRefresh();

    expect(kept, (await repo.getAllLocalRecordings()).length);
    expect(kept, 2);
  });
}
