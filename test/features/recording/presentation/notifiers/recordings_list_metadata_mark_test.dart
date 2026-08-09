/// ENG-405: the mark the list puts on a recording with an unsent edit has to
/// be a reading of the database, not a snapshot taken at fetch time.
///
/// Two ways it could lie, both exercised here against a real Drift database and
/// the real repository, so the transitions are made by production code:
///
///   1. The list shows the *server's* copy of any recording the server knows
///      about, and that projection is `synced` by construction. Every recording
///      that can owe a metadata edit has a `serverId`, so this is every one of
///      them — the mark would simply never appear once online.
///   2. The list refetches when `lastSyncAt` changes, and the metadata drain
///      deliberately does not touch `lastSyncAt` when the Wi-Fi gate holds the
///      uploads back (ENG-355/ENG-403: that field asserts the upload queue ran,
///      and it did not). On mobile data the edit goes up, the row returns to
///      `synced`, and the mark stays on screen.
///
/// A mark that sticks is worse than no mark: it teaches the user not to trust
/// it.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/database/database_provider.dart';
import 'package:oral_collector/core/observability/error_reporter.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/pending_metadata_field.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recordings_list_notifier.dart';
import 'package:oral_collector/features/sync/data/providers.dart';
import 'package:oral_collector/features/sync/domain/repositories/connectivity_service.dart';
import 'package:oral_collector/features/sync/domain/repositories/sync_engine.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApi extends Mock implements RecordingApiRepository {}

class _MockConnectivity extends Mock implements ConnectivityService {}

/// A sync engine whose metadata drain does what the real one's does to the
/// database — settle the owed field through the real repository — and nothing
/// else. The round trip is what is stubbed out; the state transition under test
/// is still made by production code.
class _DrainingSyncEngine extends Mock implements SyncEngine {
  _DrainingSyncEngine(this._repo, this._recordingId);

  final LocalRecordingRepository _repo;
  final String _recordingId;

  var drains = 0;

  @override
  Future<void> processPendingMetadata() async {
    drains++;
    await _repo.clearPendingMetadataFields(_recordingId, const {
      PendingMetadataField.title,
    });
  }

  @override
  Future<void> processQueue({
    bool deleteAfterUpload = false,
    bool wifiOnly = false,
    int maxConcurrency = 1,
    void Function(String recordingId, int sent, int total)? onProgress,
  }) async {}
}

class _RecordingReporter implements ErrorReporter {
  final List<Object> reported = [];

  @override
  void reportError(
    Object error,
    StackTrace? stackTrace, {
    Map<String, String>? tags,
    Map<String, Object?>? context,
    ErrorLevel level = ErrorLevel.error,
  }) => reported.add(error);

  @override
  void addBreadcrumb(
    String message, {
    String? category,
    ErrorLevel level = ErrorLevel.info,
    Map<String, Object?>? data,
  }) {}

  @override
  void setUser({
    String? id,
    String? username,
    String? email,
    Map<String, Object?>? data,
  }) {}

  @override
  void clearUser() {}

  @override
  void setTag(String key, String value) {}
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

LocalRecordingsCompanion _pendingRow() => LocalRecordingsCompanion.insert(
  id: _localId,
  projectId: _project.id,
  genreId: 'genre-1',
  title: const Value('Renamed while offline'),
  durationSeconds: const Value(30.0),
  fileSizeBytes: const Value(1024),
  format: const Value('m4a'),
  localFilePath: '/tmp/rec-1.m4a',
  recordedAt: DateTime(2026, 1, 1),
  uploadStatus: const Value('uploaded'),
  serverId: const Value(_serverId),
  cleaningStatus: const Value('none'),
  // The shape ENG-403 leaves behind after an edit the server could not be
  // told about: the new title is on the row, and the row remembers it is owed.
  metadataSyncStatus: const Value(MetadataSyncStatus.pending),
  pendingMetadataJson: Value(
    encodePendingMetadataFields(const {PendingMetadataField.title}),
  ),
);

ServerRecording _serverCopy({String id = _serverId}) => ServerRecording(
  id: id,
  projectId: _project.id,
  genreId: 'genre-1',
  // The server still holds the name from before the offline rename.
  title: 'Original name',
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
  late _MockConnectivity connectivity;
  late _DrainingSyncEngine engine;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);
    await repo.insertRecording(_pendingRow());

    api = _MockApi();
    when(
      () => api.listRecordings(
        any(),
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
        userId: any(named: 'userId'),
        storytellerId: any(named: 'storytellerId'),
        reviewFlag: any(named: 'reviewFlag'),
      ),
    ).thenAnswer((_) async => [_serverCopy()]);

    connectivity = _MockConnectivity();
    // Online, but on mobile data — which is what arms the Wi-Fi gate.
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(() => connectivity.isOnWifi).thenAnswer((_) async => false);
    when(
      () => connectivity.onConnectivityChanged,
    ).thenAnswer((_) => const Stream.empty());

    engine = _DrainingSyncEngine(repo, _localId);

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        recordingApiRepositoryProvider.overrideWithValue(api),
        connectivityServiceProvider.overrideWithValue(connectivity),
        syncEngineProvider.overrideWithValue(engine),
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

  String markOn(ProviderContainer c) => c
      .read(recordingsListNotifierProvider)
      .recordings
      .single
      .metadataSyncStatus;

  test(
    'a recording the server already knows still carries its unsent edit',
    () async {
      await loadList();

      // The list renders the server's projection of this recording, and the
      // server does not know about the rename. Reading the outbox state off that
      // projection would report `synced` on the one recording that is not.
      expect(markOn(container), MetadataSyncStatus.pending);
    },
  );

  test(
    'the mark goes when the drain settles the edit behind the Wi-Fi gate',
    () async {
      await loadList();
      expect(
        markOn(container),
        MetadataSyncStatus.pending,
        reason: 'precondition: the mark is on screen',
      );

      await container.read(syncNotifierProvider.notifier).syncAll();
      await _pumpUntil(() => markOn(container) == MetadataSyncStatus.synced);

      // No refetch, no navigation, no pull-to-refresh: the edit reached the
      // server and the list stopped saying otherwise on its own.
      expect(engine.drains, 1);
      expect(markOn(container), MetadataSyncStatus.synced);
    },
  );

  test('a recording that only turns up on page two is marked too', () async {
    // The first page is full, so the list keeps paginating; the owed recording
    // is on the second. `loadMore` converts server recordings through the same
    // helper the first fetch does, and today that is the only reason it works —
    // inline the conversion there and the mark disappears from page two with
    // the rest of the suite still green.
    final firstPage = [
      for (var i = 0; i < 50; i++) _serverCopy(id: 'other-$i'),
    ];
    when(
      () => api.listRecordings(
        any(),
        offset: 0,
        limit: any(named: 'limit'),
        userId: any(named: 'userId'),
        storytellerId: any(named: 'storytellerId'),
        reviewFlag: any(named: 'reviewFlag'),
      ),
    ).thenAnswer((_) async => firstPage);
    when(
      () => api.listRecordings(
        any(),
        offset: 50,
        limit: any(named: 'limit'),
        userId: any(named: 'userId'),
        storytellerId: any(named: 'storytellerId'),
        reviewFlag: any(named: 'reviewFlag'),
      ),
    ).thenAnswer((_) async => [_serverCopy()]);

    await loadList();
    final list = container.read(recordingsListNotifierProvider.notifier);
    expect(container.read(recordingsListNotifierProvider).hasMore, isTrue);

    await list.loadMore();

    final owed = container
        .read(recordingsListNotifierProvider)
        .recordings
        .firstWhere((r) => r.serverId == _serverId);
    expect(owed.metadataSyncStatus, MetadataSyncStatus.pending);
  });

  test(
    'a broken outbox stream stays off the screen but not off the wire',
    () async {
      final reporter = _RecordingReporter();
      final broken = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          recordingApiRepositoryProvider.overrideWithValue(api),
          connectivityServiceProvider.overrideWithValue(connectivity),
          syncEngineProvider.overrideWithValue(engine),
          errorReporterProvider.overrideWithValue(reporter),
          projectNotifierProvider.overrideWith(
            () => _FakeProjectNotifier(
              const ProjectState(activeProject: _project),
            ),
          ),
          metadataOutboxProvider.overrideWith(
            (_) => Stream.error(StateError('outbox stream is broken')),
          ),
        ],
      );
      addTearDown(broken.dispose);

      broken.read(syncNotifierProvider);
      await _pumpUntil(() => broken.read(syncNotifierProvider).isOnline);
      await broken
          .read(recordingsListNotifierProvider.notifier)
          .fetchRecordings();
      await _pumpUntil(() => reporter.reported.isNotEmpty);

      // Quiet on screen is the right call — a mark nobody can act on is worse
      // than none — but quiet everywhere is how this feature's own bug looked.
      expect(markOn(broken), MetadataSyncStatus.synced);
      expect(reporter.reported.single, isA<StateError>());
    },
  );

  test('the drain still does not pretend the upload queue ran', () async {
    await loadList();

    await container.read(syncNotifierProvider.notifier).syncAll();
    await _pumpUntil(() => markOn(container) == MetadataSyncStatus.synced);

    // The fix must not have been bought by reusing the upload queue's stamp:
    // ENG-355 removed exactly that lie, and the uploads really are still
    // waiting for Wi-Fi.
    final sync = container.read(syncNotifierProvider);
    expect(sync.lastSyncAt, isNull);
    expect(sync.syncProgress, 0);
    expect(sync.blockReason, SyncBlockReason.wifiOnly);
  });
}
