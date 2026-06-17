import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/errors/api_exception.dart';
import 'package:oral_collector/core/observability/error_reporter.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recordings_list_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';

class _MockApi extends Mock implements RecordingApiRepository {}

class _MockLocal extends Mock implements LocalRecordingRepository {}

class _RecordingReporter implements ErrorReporter {
  final List<Object> reported = [];
  final List<StackTrace?> stackTraces = [];

  @override
  void reportError(
    Object error,
    StackTrace? stackTrace, {
    Map<String, String>? tags,
    Map<String, Object?>? context,
    ErrorLevel level = ErrorLevel.error,
  }) {
    reported.add(error);
    stackTraces.add(stackTrace);
  }

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

class _FakeSyncNotifier extends SyncNotifier {
  _FakeSyncNotifier({required bool initialOnline})
    : _initialOnline = initialOnline;

  final bool _initialOnline;

  @override
  SyncState build() => SyncState(isOnline: _initialOnline);

  void setOnline(bool online) {
    state = state.copyWith(isOnline: online);
  }
}

class _FakeProjectNotifier extends ProjectNotifier {
  _FakeProjectNotifier(this._state);

  final ProjectState _state;

  @override
  ProjectState build() => _state;
}

LocalRecording _makeRecording(String id) => LocalRecording(
  id: id,
  projectId: 'proj-1',
  genreId: 'genre-1',
  title: 'Recording $id',
  durationSeconds: 30.0,
  fileSizeBytes: 1024,
  format: 'm4a',
  localFilePath: '/tmp/$id.m4a',
  uploadStatus: 'local',
  cleaningStatus: 'none',
  recordedAt: DateTime(2026, 1, 1),
  createdAt: DateTime(2026, 1, 1),
  retryCount: 0,
  uploadedBytes: 0,
);

ServerRecording _makeServerRecording(String id) => ServerRecording(
  id: id,
  projectId: 'proj-1',
  genreId: 'genre-1',
  title: 'Server $id',
  durationSeconds: 30.0,
  fileSizeBytes: 2048,
  format: 'm4a',
  uploadStatus: 'uploaded',
  cleaningStatus: 'none',
  recordedAt: DateTime(2026, 2, 1),
);

void main() {
  late _MockApi api;
  late _MockLocal local;
  late _RecordingReporter reporter;

  final activeProject = const Project(
    id: 'proj-1',
    name: 'Test',
    languageId: 'en',
  );

  ProviderContainer makeContainer({required bool online}) => ProviderContainer(
    overrides: [
      recordingApiRepositoryProvider.overrideWithValue(api),
      localRecordingRepositoryProvider.overrideWithValue(local),
      projectNotifierProvider.overrideWith(
        () => _FakeProjectNotifier(ProjectState(activeProject: activeProject)),
      ),
      syncNotifierProvider.overrideWith(
        () => _FakeSyncNotifier(initialOnline: online),
      ),
      errorReporterProvider.overrideWithValue(reporter),
    ],
  );

  setUp(() {
    api = _MockApi();
    local = _MockLocal();
    reporter = _RecordingReporter();
  });

  group('RecordingsListNotifier.fetchRecordings — offline', () {
    test(
      'offline renders local recordings, no API call, not loading',
      () async {
        final localRecs = [_makeRecording('r1'), _makeRecording('r2')];
        when(
          () => local.getAllRecordings('proj-1'),
        ).thenAnswer((_) async => localRecs);

        final container = makeContainer(online: false);
        addTearDown(container.dispose);

        await container
            .read(recordingsListNotifierProvider.notifier)
            .fetchRecordings();

        final state = container.read(recordingsListNotifierProvider);
        expect(state.recordings.map((r) => r.id), ['r1', 'r2']);
        expect(state.isLoading, isFalse);
        verifyNever(
          () => api.listRecordings(
            any(),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
            userId: any(named: 'userId'),
            storytellerId: any(named: 'storytellerId'),
            uploadStatus: any(named: 'uploadStatus'),
          ),
        );
      },
    );
  });

  group('RecordingsListNotifier.loadMore — offline', () {
    test(
      'offline skips the page request, isLoadingMore returns to false',
      () async {
        // Load a full first page online so the list is paginatable
        // (isLoading false, hasMore true), then drop offline before paginating —
        // loadMore only reaches its offline branch once a load has completed.
        when(
          () => api.listRecordings(
            'proj-1',
            offset: 0,
            limit: any(named: 'limit'),
            userId: any(named: 'userId'),
            storytellerId: any(named: 'storytellerId'),
          ),
        ).thenAnswer(
          (_) async => List.generate(50, (i) => _makeServerRecording('s$i')),
        );
        when(
          () => local.getAllRecordings('proj-1'),
        ).thenAnswer((_) async => const []);

        final fakeSync = _FakeSyncNotifier(initialOnline: true);
        final container = ProviderContainer(
          overrides: [
            recordingApiRepositoryProvider.overrideWithValue(api),
            localRecordingRepositoryProvider.overrideWithValue(local),
            projectNotifierProvider.overrideWith(
              () => _FakeProjectNotifier(
                ProjectState(activeProject: activeProject),
              ),
            ),
            syncNotifierProvider.overrideWith(() => fakeSync),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(
          recordingsListNotifierProvider.notifier,
        );
        await notifier
            .fetchRecordings(); // isLoading false, hasMore true, offset 50
        fakeSync.setOnline(false);

        await notifier.loadMore();

        final state = container.read(recordingsListNotifierProvider);
        expect(state.isLoadingMore, isFalse);
        verifyNever(
          () => api.listRecordings(
            'proj-1',
            offset: 50,
            limit: any(named: 'limit'),
            userId: any(named: 'userId'),
            storytellerId: any(named: 'storytellerId'),
          ),
        );
      },
    );
  });

  group('RecordingsListNotifier.clearStaleRecordings — offline', () {
    test('offline returns null without touching server or local', () async {
      final container = makeContainer(online: false);
      addTearDown(container.dispose);

      final result = await container
          .read(recordingsListNotifierProvider.notifier)
          .clearStaleRecordings();

      expect(
        result,
        isNull,
        reason:
            'null distinguishes "offline no-op" from a real "0 deleted" success',
      );
      verifyNever(() => api.clearStaleRecordings(any()));
      verifyNever(() => local.deleteStaleRecordings(any()));
    });
  });

  group('RecordingsListNotifier.fetchRecordings — online', () {
    test(
      'online merges server + local-only recordings, ordered by recordedAt desc',
      () async {
        when(
          () => api.listRecordings(
            'proj-1',
            offset: 0,
            limit: any(named: 'limit'),
            userId: any(named: 'userId'),
            storytellerId: any(named: 'storytellerId'),
          ),
        ).thenAnswer((_) async => [_makeServerRecording('srv-1')]);
        when(() => local.getAllRecordings('proj-1')).thenAnswer(
          (_) async => [_makeRecording('local-1')], // older, no serverId
        );

        final container = makeContainer(online: true);
        addTearDown(container.dispose);

        await container
            .read(recordingsListNotifierProvider.notifier)
            .fetchRecordings();

        final state = container.read(recordingsListNotifierProvider);
        expect(state.isLoading, isFalse);
        // server recording is from 2026-02-01, local from 2026-01-01 → server first
        expect(state.recordings.map((r) => r.id), ['srv-1', 'local-1']);
        verify(
          () => api.listRecordings(
            'proj-1',
            offset: 0,
            limit: any(named: 'limit'),
            userId: any(named: 'userId'),
            storytellerId: any(named: 'storytellerId'),
          ),
        ).called(1);
      },
    );
  });

  group(
    'RecordingsListNotifier.fetchRecordings — offline → online transition',
    () {
      test(
        'first fetch offline falls back to local; second fetch (post-flip) hits the API',
        () async {
          when(
            () => local.getAllRecordings('proj-1'),
          ).thenAnswer((_) async => [_makeRecording('local-1')]);
          when(
            () => api.listRecordings(
              'proj-1',
              offset: 0,
              limit: any(named: 'limit'),
              userId: any(named: 'userId'),
              storytellerId: any(named: 'storytellerId'),
            ),
          ).thenAnswer((_) async => [_makeServerRecording('srv-1')]);

          final fakeSync = _FakeSyncNotifier(initialOnline: false);
          final container = ProviderContainer(
            overrides: [
              recordingApiRepositoryProvider.overrideWithValue(api),
              localRecordingRepositoryProvider.overrideWithValue(local),
              projectNotifierProvider.overrideWith(
                () => _FakeProjectNotifier(
                  ProjectState(activeProject: activeProject),
                ),
              ),
              syncNotifierProvider.overrideWith(() => fakeSync),
            ],
          );
          addTearDown(container.dispose);

          final notifier = container.read(
            recordingsListNotifierProvider.notifier,
          );

          // Offline: fallback to local.
          await notifier.fetchRecordings();
          expect(
            container
                .read(recordingsListNotifierProvider)
                .recordings
                .map((r) => r.id),
            ['local-1'],
          );
          verifyNever(
            () => api.listRecordings(
              any(),
              offset: any(named: 'offset'),
              limit: any(named: 'limit'),
              userId: any(named: 'userId'),
              storytellerId: any(named: 'storytellerId'),
            ),
          );

          fakeSync.setOnline(true);
          await notifier.fetchRecordings();

          verify(
            () => api.listRecordings(
              'proj-1',
              offset: 0,
              limit: any(named: 'limit'),
              userId: any(named: 'userId'),
              storytellerId: any(named: 'storytellerId'),
            ),
          ).called(1);
          final state = container.read(recordingsListNotifierProvider);
          expect(state.recordings.any((r) => r.id == 'srv-1'), isTrue);
        },
      );
    },
  );

  group('race guards', () {
    test('a stale fetch does not overwrite a newer fetch', () async {
      final fetchAGate = Completer<List<ServerRecording>>();
      final fetchBGate = Completer<List<ServerRecording>>();
      when(
        () => api.listRecordings(
          'proj-1',
          offset: 0,
          limit: any(named: 'limit'),
          userId: 'A',
          storytellerId: any(named: 'storytellerId'),
        ),
      ).thenAnswer((_) => fetchAGate.future);
      when(
        () => api.listRecordings(
          'proj-1',
          offset: 0,
          limit: any(named: 'limit'),
          userId: 'B',
          storytellerId: any(named: 'storytellerId'),
        ),
      ).thenAnswer((_) => fetchBGate.future);
      when(
        () => local.getAllRecordings('proj-1'),
      ).thenAnswer((_) async => const []);

      final container = makeContainer(online: true);
      addTearDown(container.dispose);
      final notifier = container.read(recordingsListNotifierProvider.notifier);

      final fetchA = notifier.setUserFilter('A');
      final fetchB = notifier.setUserFilter('B');

      // B is the latest request; it resolves first, then the stale A resolves.
      fetchBGate.complete([_makeServerRecording('srv-B')]);
      await fetchB;
      fetchAGate.complete([_makeServerRecording('srv-A')]);
      await fetchA;

      final state = container.read(recordingsListNotifierProvider);
      expect(state.recordings.map((r) => r.id), contains('srv-B'));
      expect(state.recordings.map((r) => r.id), isNot(contains('srv-A')));
      expect(state.selectedUserId, 'B');
      expect(state.isLoading, isFalse);
    });

    test('an in-flight loadMore is discarded by a superseding fetch', () async {
      when(
        () => api.listRecordings(
          'proj-1',
          offset: 0,
          limit: any(named: 'limit'),
          userId: any(named: 'userId'),
          storytellerId: any(named: 'storytellerId'),
        ),
      ).thenAnswer(
        (_) async => List.generate(50, (i) => _makeServerRecording('p0-$i')),
      );
      when(
        () => local.getAllRecordings('proj-1'),
      ).thenAnswer((_) async => const []);

      final container = makeContainer(online: true);
      addTearDown(container.dispose);
      final notifier = container.read(recordingsListNotifierProvider.notifier);

      await notifier.fetchRecordings();

      final loadMoreGate = Completer<List<ServerRecording>>();
      when(
        () => api.listRecordings(
          'proj-1',
          offset: 50,
          limit: any(named: 'limit'),
          userId: any(named: 'userId'),
          storytellerId: any(named: 'storytellerId'),
        ),
      ).thenAnswer((_) => loadMoreGate.future);
      final loadMore = notifier.loadMore();

      final fetchGate = Completer<List<ServerRecording>>();
      when(
        () => api.listRecordings(
          'proj-1',
          offset: 0,
          limit: any(named: 'limit'),
          userId: any(named: 'userId'),
          storytellerId: any(named: 'storytellerId'),
        ),
      ).thenAnswer((_) => fetchGate.future);
      final fetch = notifier.fetchRecordings();

      // The fresh fetch resolves and applies first.
      fetchGate.complete([
        _makeServerRecording('new-0'),
        _makeServerRecording('new-1'),
      ]);
      await fetch;
      // The superseded loadMore resolves last; its stale page must be dropped.
      loadMoreGate.complete(
        List.generate(50, (i) => _makeServerRecording('p1-$i')),
      );
      await loadMore;

      final state = container.read(recordingsListNotifierProvider);
      expect(
        state.recordings.map((r) => r.id),
        unorderedEquals(['new-0', 'new-1']),
      );
      expect(state.recordings.any((r) => r.id.startsWith('p1-')), isFalse);
      expect(state.hasMore, isFalse);
      expect(state.isLoadingMore, isFalse);
    });

    test(
      'fetchRecordings clears isLoadingMore left by a superseded loadMore',
      () async {
        when(
          () => api.listRecordings(
            'proj-1',
            offset: 0,
            limit: any(named: 'limit'),
            userId: any(named: 'userId'),
            storytellerId: any(named: 'storytellerId'),
          ),
        ).thenAnswer(
          (_) async => List.generate(50, (i) => _makeServerRecording('p0-$i')),
        );
        when(
          () => local.getAllRecordings('proj-1'),
        ).thenAnswer((_) async => const []);

        final container = makeContainer(online: true);
        addTearDown(container.dispose);
        final notifier = container.read(
          recordingsListNotifierProvider.notifier,
        );

        await notifier.fetchRecordings();

        final loadMoreGate = Completer<List<ServerRecording>>();
        when(
          () => api.listRecordings(
            'proj-1',
            offset: 50,
            limit: any(named: 'limit'),
            userId: any(named: 'userId'),
            storytellerId: any(named: 'storytellerId'),
          ),
        ).thenAnswer((_) => loadMoreGate.future);
        final loadMore = notifier.loadMore();

        expect(
          container.read(recordingsListNotifierProvider).isLoadingMore,
          isTrue,
        );

        final fetchGate = Completer<List<ServerRecording>>();
        when(
          () => api.listRecordings(
            'proj-1',
            offset: 0,
            limit: any(named: 'limit'),
            userId: any(named: 'userId'),
            storytellerId: any(named: 'storytellerId'),
          ),
        ).thenAnswer((_) => fetchGate.future);
        final fetch = notifier.fetchRecordings();

        expect(
          container.read(recordingsListNotifierProvider).isLoadingMore,
          isFalse,
        );

        fetchGate.complete(const []);
        await fetch;
        loadMoreGate.complete(const []);
        await loadMore;
      },
    );

    test(
      'loadMore does not start while a fetchRecordings is in flight',
      () async {
        when(
          () => api.listRecordings(
            'proj-1',
            offset: 0,
            limit: any(named: 'limit'),
            userId: any(named: 'userId'),
            storytellerId: any(named: 'storytellerId'),
          ),
        ).thenAnswer(
          (_) async => List.generate(50, (i) => _makeServerRecording('p0-$i')),
        );
        when(
          () => local.getAllRecordings('proj-1'),
        ).thenAnswer((_) async => const []);
        // If loadMore wrongly proceeds it hits this page-2 stub against the
        // soon-to-be-reset offset; the assertion below catches that.
        when(
          () => api.listRecordings(
            'proj-1',
            offset: 50,
            limit: any(named: 'limit'),
            userId: any(named: 'userId'),
            storytellerId: any(named: 'storytellerId'),
          ),
        ).thenAnswer((_) async => const []);

        final container = makeContainer(online: true);
        addTearDown(container.dispose);
        final notifier = container.read(
          recordingsListNotifierProvider.notifier,
        );

        await notifier
            .fetchRecordings(); // isLoading false, hasMore true, offset 50

        // A fresh fetch is in flight (isLoading true) but has not applied yet.
        final fetchGate = Completer<List<ServerRecording>>();
        when(
          () => api.listRecordings(
            'proj-1',
            offset: 0,
            limit: any(named: 'limit'),
            userId: any(named: 'userId'),
            storytellerId: any(named: 'storytellerId'),
          ),
        ).thenAnswer((_) => fetchGate.future);
        final fetch = notifier.fetchRecordings();

        await notifier.loadMore();
        verifyNever(
          () => api.listRecordings(
            'proj-1',
            offset: 50,
            limit: any(named: 'limit'),
            userId: any(named: 'userId'),
            storytellerId: any(named: 'storytellerId'),
          ),
        );

        fetchGate.complete([_makeServerRecording('new-0')]);
        await fetch;
      },
    );
  });

  group('RecordingsListNotifier.deleteRecording', () {
    late Directory tmpDir;
    late AppDatabase db;
    late LocalRecordingRepository realLocal;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('eng120_del_');
      db = AppDatabase.forTesting(NativeDatabase.memory());
      realLocal = LocalRecordingRepository(db);
    });

    tearDown(() async {
      await db.close();
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    });

    // Real Drift repo (in-memory) + mock API: exercises the actual row lookup
    // and delete, so an id/serverId mismatch surfaces instead of being mocked
    // away.
    ProviderContainer realContainer() => ProviderContainer(
      overrides: [
        recordingApiRepositoryProvider.overrideWithValue(api),
        localRecordingRepositoryProvider.overrideWithValue(realLocal),
        projectNotifierProvider.overrideWith(
          () =>
              _FakeProjectNotifier(ProjectState(activeProject: activeProject)),
        ),
        syncNotifierProvider.overrideWith(
          () => _FakeSyncNotifier(initialOnline: true),
        ),
        errorReporterProvider.overrideWithValue(reporter),
      ],
    );

    File seedFile(String name) =>
        File('${tmpDir.path}/$name')..writeAsStringSync('audio-bytes');

    Future<void> insertRow({
      required String id,
      String? serverId,
      required String localFilePath,
    }) {
      return realLocal.insertRecording(
        LocalRecordingsCompanion.insert(
          id: id,
          projectId: 'proj-1',
          genreId: 'genre-1',
          localFilePath: localFilePath,
          recordedAt: DateTime(2026, 1, 1),
          serverId: Value(serverId),
          uploadStatus: Value(serverId == null ? 'local' : 'uploaded'),
        ),
      );
    }

    Future<RecordingsListNotifier> seeded(
      ProviderContainer container,
      List<ServerRecording> server,
    ) async {
      when(
        () => api.listRecordings(
          'proj-1',
          offset: 0,
          limit: any(named: 'limit'),
          userId: any(named: 'userId'),
          storytellerId: any(named: 'storytellerId'),
        ),
      ).thenAnswer((_) async => server);
      final notifier = container.read(recordingsListNotifierProvider.notifier);
      await notifier.fetchRecordings();
      return notifier;
    }

    test(
      'synced from the list (local id differs from serverId): deletes the real '
      'row and its audio file, no resurrection',
      () async {
        final file = seedFile('rec.m4a');
        // A locally-created+uploaded row keeps its local uuid; serverId is the
        // server's id. The list shows the server copy (id == serverId, empty
        // localFilePath).
        await insertRow(
          id: 'local-uuid',
          serverId: 'srv-1',
          localFilePath: file.path,
        );
        when(() => api.deleteRecording('srv-1')).thenAnswer((_) async => true);

        final container = realContainer();
        addTearDown(container.dispose);
        final notifier = await seeded(container, [
          _makeServerRecording('srv-1'),
        ]);
        final listed = container
            .read(recordingsListNotifierProvider)
            .recordings
            .single;
        expect(listed.id, 'srv-1');
        expect(listed.localFilePath, isEmpty);

        final result = await notifier.deleteRecording(listed);

        expect(result, DeleteRecordingResult.ok);
        verify(() => api.deleteRecording('srv-1')).called(1);
        expect(file.existsSync(), isFalse);
        expect(await realLocal.getRecordingByServerId('srv-1'), isNull);
        expect(await realLocal.getAllRecordings('proj-1'), isEmpty);
        expect(
          container.read(recordingsListNotifierProvider).recordings,
          isEmpty,
        );
      },
    );

    test(
      'local-only (no serverId): skips the API, deletes the row and the file',
      () async {
        final file = seedFile('local.m4a');
        await insertRow(id: 'loc-1', localFilePath: file.path);

        final container = realContainer();
        addTearDown(container.dispose);
        final notifier = await seeded(container, const []);
        final listed = container
            .read(recordingsListNotifierProvider)
            .recordings
            .single;

        final result = await notifier.deleteRecording(listed);

        expect(result, DeleteRecordingResult.ok);
        verifyNever(() => api.deleteRecording(any()));
        expect(file.existsSync(), isFalse);
        expect(await realLocal.getAllRecordings('proj-1'), isEmpty);
        expect(
          container.read(recordingsListNotifierProvider).recordings,
          isEmpty,
        );
      },
    );

    test('forbidden: keeps the row, the file, and the list item', () async {
      final file = seedFile('rec.m4a');
      await insertRow(id: 'srv-3', serverId: 'srv-3', localFilePath: file.path);
      when(
        () => api.deleteRecording('srv-3'),
      ).thenThrow(const ForbiddenException());

      final container = realContainer();
      addTearDown(container.dispose);
      final notifier = await seeded(container, [_makeServerRecording('srv-3')]);
      final listed = container
          .read(recordingsListNotifierProvider)
          .recordings
          .single;

      final result = await notifier.deleteRecording(listed);

      expect(result, DeleteRecordingResult.forbidden);
      expect(file.existsSync(), isTrue);
      expect(await realLocal.getRecordingByServerId('srv-3'), isNotNull);
      expect(
        container
            .read(recordingsListNotifierProvider)
            .recordings
            .map((r) => r.id),
        ['srv-3'],
      );
    });

    test(
      'remote failure: keeps the row, the file, and the list item',
      () async {
        final file = seedFile('rec.m4a');
        await insertRow(
          id: 'srv-4',
          serverId: 'srv-4',
          localFilePath: file.path,
        );
        final netErr = Exception('network');
        when(() => api.deleteRecording('srv-4')).thenThrow(netErr);

        final container = realContainer();
        addTearDown(container.dispose);
        final notifier = await seeded(container, [
          _makeServerRecording('srv-4'),
        ]);
        final listed = container
            .read(recordingsListNotifierProvider)
            .recordings
            .single;

        final result = await notifier.deleteRecording(listed);

        expect(result, DeleteRecordingResult.failed);
        expect(file.existsSync(), isTrue);
        expect(await realLocal.getRecordingByServerId('srv-4'), isNotNull);
        expect(reporter.reported, contains(netErr));
      },
    );

    test(
      'missing audio file path: the file delete is a no-op, the row is still '
      'deleted',
      () async {
        await insertRow(
          id: 'loc-5',
          localFilePath: '${tmpDir.path}/never-created.m4a',
        );

        final container = realContainer();
        addTearDown(container.dispose);
        final notifier = await seeded(container, const []);
        final listed = container
            .read(recordingsListNotifierProvider)
            .recordings
            .single;

        final result = await notifier.deleteRecording(listed);

        expect(result, DeleteRecordingResult.ok);
        expect(await realLocal.getAllRecordings('proj-1'), isEmpty);
      },
    );
  });

  group('error reporting', () {
    test(
      'reports the server-fetch failure before falling back to local',
      () async {
        final boom = Exception('server boom');
        when(
          () => api.listRecordings(
            'proj-1',
            offset: 0,
            limit: any(named: 'limit'),
            userId: any(named: 'userId'),
            storytellerId: any(named: 'storytellerId'),
          ),
        ).thenThrow(boom);
        when(
          () => local.getAllRecordings('proj-1'),
        ).thenAnswer((_) async => [_makeRecording('local-1')]);

        final container = makeContainer(online: true);
        addTearDown(container.dispose);
        await container
            .read(recordingsListNotifierProvider.notifier)
            .fetchRecordings();

        final state = container.read(recordingsListNotifierProvider);
        expect(state.recordings.map((r) => r.id), ['local-1']);
        expect(reporter.reported, contains(boom));
        expect(reporter.stackTraces.last, isNotNull);
      },
    );

    test('reports an unexpected server-fetch failure but suppresses '
        'UnauthorizedException', () async {
      // Control: a non-401 failure on this path IS reported.
      when(
        () => api.listRecordings(
          'proj-1',
          offset: 0,
          limit: any(named: 'limit'),
          userId: any(named: 'userId'),
          storytellerId: any(named: 'storytellerId'),
        ),
      ).thenThrow(Exception('boom'));
      when(
        () => local.getAllRecordings('proj-1'),
      ).thenAnswer((_) async => const []);

      final container = makeContainer(online: true);
      addTearDown(container.dispose);
      final notifier = container.read(recordingsListNotifierProvider.notifier);
      await notifier.fetchRecordings();
      expect(reporter.reported, isNotEmpty);

      // A 401 on the same path is suppressed — not vacuously: we just proved
      // the path reports.
      reporter.reported.clear();
      when(
        () => api.listRecordings(
          'proj-1',
          offset: 0,
          limit: any(named: 'limit'),
          userId: any(named: 'userId'),
          storytellerId: any(named: 'storytellerId'),
        ),
      ).thenThrow(const UnauthorizedException());
      await notifier.fetchRecordings();
      expect(reporter.reported, isEmpty);
    });

    test('reports a loadMore pagination failure', () async {
      when(
        () => api.listRecordings(
          'proj-1',
          offset: 0,
          limit: any(named: 'limit'),
          userId: any(named: 'userId'),
          storytellerId: any(named: 'storytellerId'),
        ),
      ).thenAnswer(
        (_) async => List.generate(50, (i) => _makeServerRecording('s$i')),
      );
      when(
        () => local.getAllRecordings('proj-1'),
      ).thenAnswer((_) async => const []);

      final container = makeContainer(online: true);
      addTearDown(container.dispose);
      final notifier = container.read(recordingsListNotifierProvider.notifier);
      await notifier.fetchRecordings();

      final boom = Exception('page boom');
      when(
        () => api.listRecordings(
          'proj-1',
          offset: 50,
          limit: any(named: 'limit'),
          userId: any(named: 'userId'),
          storytellerId: any(named: 'storytellerId'),
        ),
      ).thenThrow(boom);
      await notifier.loadMore();

      expect(reporter.reported, contains(boom));
      expect(
        container.read(recordingsListNotifierProvider).isLoadingMore,
        isFalse,
      );
    });

    test('reports a local-read failure during the online merge', () async {
      final boom = Exception('local read boom');
      when(
        () => api.listRecordings(
          'proj-1',
          offset: 0,
          limit: any(named: 'limit'),
          userId: any(named: 'userId'),
          storytellerId: any(named: 'storytellerId'),
        ),
      ).thenAnswer((_) async => [_makeServerRecording('srv-1')]);
      when(() => local.getAllRecordings('proj-1')).thenThrow(boom);

      final container = makeContainer(online: true);
      addTearDown(container.dispose);
      await container
          .read(recordingsListNotifierProvider.notifier)
          .fetchRecordings();

      final state = container.read(recordingsListNotifierProvider);
      expect(state.recordings.any((r) => r.id == 'srv-1'), isTrue);
      expect(reporter.reported, contains(boom));
    });

    test('reports a local-read failure while offline', () async {
      final boom = Exception('offline local boom');
      when(() => local.getAllRecordings('proj-1')).thenThrow(boom);

      final container = makeContainer(online: false);
      addTearDown(container.dispose);
      await container
          .read(recordingsListNotifierProvider.notifier)
          .fetchRecordings();

      expect(reporter.reported, contains(boom));
      expect(container.read(recordingsListNotifierProvider).isLoading, isFalse);
    });
  });
}
