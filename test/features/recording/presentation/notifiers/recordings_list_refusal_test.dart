import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/database/database_provider.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recordings_list_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recordings_list_state.dart';
import 'package:oral_collector/features/sync/data/providers.dart';
import 'package:oral_collector/features/sync/domain/repositories/connectivity_service.dart';
import 'package:oral_collector/features/sync/domain/repositories/sync_engine.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApi extends Mock implements RecordingApiRepository {}

class _MockConnectivity extends Mock implements ConnectivityService {}

class _IdleSyncEngine extends Mock implements SyncEngine {
  @override
  Future<void> processQueue({
    bool deleteAfterUpload = false,
    bool wifiOnly = false,
    int maxConcurrency = 1,
    void Function(String recordingId, int sent, int total)? onProgress,
  }) async {}
}

class _FakeProjectNotifier extends ProjectNotifier {
  _FakeProjectNotifier(this._state);
  final ProjectState _state;

  @override
  ProjectState build() => _state;
}

const _project = Project(id: 'proj-1', name: 'Test', languageId: 'en');
const _serverId = 'srv-1';
const _localId = 'rec-1';

LocalRecordingsCompanion _publishedRow(
  String uploadStatus, {
  String id = _localId,
  String serverId = _serverId,
  String? gcsUrl = 'gs://bucket/rec-1.m4a',
}) => LocalRecordingsCompanion.insert(
  id: id,
  projectId: _project.id,
  genreId: 'genre-1',
  durationSeconds: const Value(30.0),
  fileSizeBytes: const Value(1024),
  format: const Value('m4a'),
  localFilePath: '/tmp/rec-1.m4a',
  recordedAt: DateTime(2026, 1, 1),
  uploadStatus: Value(uploadStatus),
  serverId: Value(serverId),
  gcsUrl: Value(gcsUrl),
  cleaningStatus: const Value('none'),
);

ServerRecording _serverCopy({String id = _serverId}) => ServerRecording(
  id: id,
  projectId: _project.id,
  genreId: 'genre-1',
  title: 'Server title',
  durationSeconds: 30,
  fileSizeBytes: 1024,
  format: 'm4a',
  uploadStatus: 'uploaded',
  cleaningStatus: 'none',
  recordedAt: DateTime(2026, 1, 1),
);

Future<void> _pumpUntil(bool Function() done, {int maxTurns = 200}) async {
  for (var turn = 0; turn < maxTurns && !done(); turn++) {
    await Future<void>.delayed(Duration.zero);
  }
  if (!done()) fail('condition still false after $maxTurns event-loop turns');
}

void main() {
  late AppDatabase db;
  late LocalRecordingRepository repo;
  late _MockApi api;
  late ProviderContainer container;

  void serverLists(int offset, List<ServerRecording> page) => when(
    () => api.listRecordings(
      any(),
      offset: offset,
      limit: any(named: 'limit'),
      userId: any(named: 'userId'),
      storytellerId: any(named: 'storytellerId'),
      reviewFlag: any(named: 'reviewFlag'),
    ),
  ).thenAnswer((_) async => page);

  Future<void> deviceStatus(String status, {String id = _localId}) =>
      (db.update(db.localRecordings)..where((t) => t.id.equals(id))).write(
        LocalRecordingsCompanion(uploadStatus: Value(status)),
      );

  Future<void> settle() async {
    for (var turn = 0; turn < 60; turn++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  List<String> filtered(StatusFilter filter) {
    container
        .read(recordingsListNotifierProvider.notifier)
        .setStatusFilter(filter);
    return container
        .read(recordingsListNotifierProvider)
        .filteredRecordings
        .map((r) => r.id)
        .toList();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);
    api = _MockApi();
    serverLists(0, [_serverCopy()]);

    final connectivity = _MockConnectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(() => connectivity.isOnWifi).thenAnswer((_) async => false);
    when(
      () => connectivity.onConnectivityChanged,
    ).thenAnswer((_) => const Stream.empty());

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        recordingApiRepositoryProvider.overrideWithValue(api),
        connectivityServiceProvider.overrideWithValue(connectivity),
        syncEngineProvider.overrideWithValue(_IdleSyncEngine()),
        projectNotifierProvider.overrideWith(
          () =>
              _FakeProjectNotifier(const ProjectState(activeProject: _project)),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> loadList() async {
    container.read(syncNotifierProvider);
    await _pumpUntil(() => container.read(syncNotifierProvider).isOnline);
    await container
        .read(recordingsListNotifierProvider.notifier)
        .fetchRecordings();
  }

  String statusOf(String serverId) => container
      .read(recordingsListNotifierProvider)
      .recordings
      .firstWhere((r) => r.serverId == serverId)
      .uploadStatus;

  String statusOfId(String id) => container
      .read(recordingsListNotifierProvider)
      .recordings
      .firstWhere((r) => r.id == id)
      .uploadStatus;

  test(
    'a published recording whose edit was refused shows the refusal on its list card',
    () async {
      await repo.insertRecording(_publishedRow('failed_refused_size_mismatch'));

      await loadList();

      expect(filtered(StatusFilter.uploaded), isEmpty);
      expect(statusOf(_serverId), 'failed_refused_size_mismatch');
    },
  );

  test(
    'a published recording whose edit was refused appears under the pending filter',
    () async {
      await repo.insertRecording(_publishedRow('failed_refused_size_mismatch'));
      await loadList();

      container
          .read(recordingsListNotifierProvider.notifier)
          .setStatusFilter(StatusFilter.pending);

      expect(
        container
            .read(recordingsListNotifierProvider)
            .filteredRecordings
            .map((r) => r.serverId),
        [_serverId],
      );
    },
  );

  test(
    'a published recording with no refusal on the device keeps the server status in the list',
    () async {
      await repo.insertRecording(_publishedRow('uploaded'));

      await loadList();

      expect(statusOf(_serverId), 'uploaded');
    },
  );

  test(
    'a refusal written on the device while the list is open reaches the card',
    () async {
      await repo.insertRecording(_publishedRow('uploaded'));
      await loadList();
      expect(statusOf(_serverId), 'uploaded');

      await deviceStatus('failed_refused_checksum_mismatch');
      await _pumpUntil(
        () => statusOf(_serverId) == 'failed_refused_checksum_mismatch',
      );

      await deviceStatus('uploaded');
      await _pumpUntil(() => statusOf(_serverId) == 'uploaded');
    },
  );

  test(
    'a recording on a later page whose edit was refused shows the refusal too',
    () async {
      await repo.insertRecording(_publishedRow('failed_refused_size_mismatch'));
      serverLists(0, [
        for (var i = 0; i < 50; i++) _serverCopy(id: 'other-$i'),
      ]);
      serverLists(50, [_serverCopy()]);
      await loadList();
      expect(container.read(recordingsListNotifierProvider).hasMore, isTrue);

      await container.read(recordingsListNotifierProvider.notifier).loadMore();

      expect(statusOf(_serverId), 'failed_refused_size_mismatch');
    },
  );

  test(
    'a device copy the server no longer lists keeps its own status when a refusal lands on another recording',
    () async {
      await repo.insertRecording(
        _publishedRow(
          'local',
          id: 'cached-1',
          serverId: 'cached-1',
          gcsUrl: null,
        ),
      );
      await repo.insertRecording(_publishedRow('uploaded'));
      serverLists(0, [_serverCopy(id: 'cached-1'), _serverCopy()]);
      await loadList();
      serverLists(0, [_serverCopy()]);
      await container
          .read(recordingsListNotifierProvider.notifier)
          .fetchRecordings();
      expect(statusOfId('cached-1'), 'local');

      await deviceStatus('failed_refused_size_mismatch');
      await settle();

      expect(statusOfId('cached-1'), 'local');
      expect(filtered(StatusFilter.pending), contains('cached-1'));
    },
  );

  test(
    'a refusal that lands while the next page is loading is not undone by it',
    () async {
      await repo.insertRecording(_publishedRow('uploaded'));
      await repo.insertRecording(
        _publishedRow('uploaded', id: 'ghost', serverId: 'ghost-srv'),
      );
      serverLists(0, [
        for (var i = 0; i < 50; i++) _serverCopy(id: 'other-$i'),
      ]);
      serverLists(50, [_serverCopy()]);
      final asked = Completer<void>();
      final answer = Completer<ServerRecording>();
      when(() => api.getRecording('ghost-srv')).thenAnswer((_) {
        asked.complete();
        return answer.future;
      });
      await loadList();

      final loading = container
          .read(recordingsListNotifierProvider.notifier)
          .loadMore();
      await asked.future;
      await deviceStatus('failed_refused_size_mismatch');
      await settle();
      answer.complete(_serverCopy(id: 'ghost-srv'));
      await loading;

      expect(statusOf(_serverId), 'failed_refused_size_mismatch');
    },
  );

  test(
    'a refused edit stays pending on the list while its retry is queued',
    () async {
      await repo.insertRecording(_publishedRow('failed_refused_size_mismatch'));
      await loadList();

      await repo.resetRetryCount(_localId);
      await settle();

      expect(filtered(StatusFilter.pending), [_serverId]);
      expect(filtered(StatusFilter.uploaded), isEmpty);
    },
  );

  test('a refused edit whose retry failed stays pending on the list', () async {
    await repo.insertRecording(_publishedRow('failed_refused_size_mismatch'));
    await loadList();

    await repo.resetRetryCount(_localId);
    await deviceStatus('failed_exhausted');
    await settle();

    expect(filtered(StatusFilter.pending), [_serverId]);
    expect(filtered(StatusFilter.uploaded), isEmpty);
  });
}
