import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
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

class _SwitchableProjectNotifier extends ProjectNotifier {
  _SwitchableProjectNotifier(this._initial);

  final ProjectState _initial;

  @override
  ProjectState build() => _initial;

  void switchTo(Project project) {
    state = ProjectState(activeProject: project);
  }
}

LocalRecording _makeRecording(String id) => LocalRecording(
  id: id,
  reviewFlagsJson: '[]',
  // The metadata outbox defaults (ENG-403): this row owes the server no edit.
  metadataSyncStatus: 'synced',
  pendingMetadataJson: '[]',
  metadataRetryCount: 0,
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

/// Pumps the event loop until [done], failing fast instead of hanging until the
/// suite timeout when a regression means it never will.
Future<void> pumpUntil(bool Function() done, {int maxTurns = 200}) async {
  for (var turn = 0; turn < maxTurns && !done(); turn++) {
    await Future<void>.delayed(Duration.zero);
  }
  if (!done()) fail('condition still false after $maxTurns event-loop turns');
}

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

  group('RecordingsListNotifier.patchRecordingTitle', () {
    test(
      'renames only the targeted recording, preserving its other fields',
      () async {
        when(
          () => local.getAllRecordings('proj-1'),
        ).thenAnswer((_) async => [_makeRecording('r1'), _makeRecording('r2')]);

        final container = makeContainer(online: false);
        addTearDown(container.dispose);
        final notifier = container.read(
          recordingsListNotifierProvider.notifier,
        );
        await notifier.fetchRecordings();

        notifier.patchRecordingTitle('r1', 'Renamed');

        final recordings = container
            .read(recordingsListNotifierProvider)
            .recordings;
        final r1 = recordings.firstWhere((r) => r.id == 'r1');
        final r2 = recordings.firstWhere((r) => r.id == 'r2');
        expect(r1.title, 'Renamed');
        expect(r1.uploadStatus, 'local', reason: 'other fields are preserved');
        expect(r2.title, 'Recording r2', reason: 'siblings are untouched');
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

  group('RecordingsListNotifier.fetchRecordings — server-side deletion', () {
    late Directory tmpDir;
    late AppDatabase db;
    late LocalRecordingRepository realLocal;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('eng45_heal_');
      db = AppDatabase.forTesting(NativeDatabase.memory());
      realLocal = LocalRecordingRepository(db);
    });

    tearDown(() async {
      await db.close();
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    });

    // Real Drift repo (in-memory): the reconciliation has to hit the actual row
    // and its audio file, which a mocked repo would only pretend to do.
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

    Future<File> insertRow({
      required String id,
      required String? serverId,
      required String uploadStatus,
    }) async {
      final file = File('${tmpDir.path}/$id.m4a')
        ..writeAsStringSync('audio-bytes');
      await realLocal.insertRecording(
        LocalRecordingsCompanion.insert(
          id: id,
          projectId: 'proj-1',
          genreId: 'genre-1',
          localFilePath: file.path,
          recordedAt: DateTime(2026, 1, 1),
          serverId: Value(serverId),
          uploadStatus: Value(uploadStatus),
        ),
      );
      return file;
    }

    void stubServerPage(List<ServerRecording> page) {
      when(
        () => api.listRecordings(
          'proj-1',
          offset: 0,
          limit: any(named: 'limit'),
          userId: any(named: 'userId'),
          storytellerId: any(named: 'storytellerId'),
          reviewFlag: any(named: 'reviewFlag'),
        ),
      ).thenAnswer((_) async => page);
    }

    // Absence from a listing only makes a row a candidate; the direct read is
    // what condemns it. Each test stubs the answer its story implies, so no row
    // survives merely because the confirmation was never set up.
    void stubServerDropped(String serverId) {
      when(
        () => api.getRecording(serverId),
      ).thenThrow(const ValidationException(statusCode: 404));
    }

    void stubServerStillHas(String serverId) {
      when(
        () => api.getRecording(serverId),
      ).thenAnswer((_) async => _makeServerRecording(serverId));
    }

    test(
      'a complete unfiltered sweep drops an uploaded row the server no longer '
      'has, row and audio file included',
      () async {
        final file = await insertRow(
          id: 'local-uuid',
          serverId: 'srv-gone',
          uploadStatus: 'uploaded',
        );
        stubServerPage([_makeServerRecording('srv-live')]);
        stubServerDropped('srv-gone');

        final container = realContainer();
        addTearDown(container.dispose);
        await container
            .read(recordingsListNotifierProvider.notifier)
            .fetchRecordings();

        expect(
          container
              .read(recordingsListNotifierProvider)
              .recordings
              .map((r) => r.id),
          ['srv-live'],
        );
        expect(await realLocal.getRecordingById('local-uuid'), isNull);
        expect(file.existsSync(), isFalse);
      },
    );

    test(
      'a row that never finished uploading survives the same sweep',
      () async {
        // serverId + a non-uploaded status is the shape a reset/retry leaves
        // behind; this device may hold the only copy of the audio (PR #193).
        final file = await insertRow(
          id: 'never-landed',
          serverId: 'srv-gone',
          uploadStatus: 'failed',
        );
        stubServerPage([_makeServerRecording('srv-live')]);
        stubServerDropped('srv-gone');

        final container = realContainer();
        addTearDown(container.dispose);
        await container
            .read(recordingsListNotifierProvider.notifier)
            .fetchRecordings();

        expect(
          container
              .read(recordingsListNotifierProvider)
              .recordings
              .map((r) => r.id),
          contains('never-landed'),
        );
        expect(await realLocal.getRecordingById('never-landed'), isNotNull);
        expect(file.existsSync(), isTrue);
      },
    );

    test(
      'a full page means the sweep is partial: nothing is dropped',
      () async {
        final file = await insertRow(
          id: 'local-uuid',
          serverId: 'srv-gone',
          uploadStatus: 'uploaded',
        );
        stubServerPage(List.generate(50, (i) => _makeServerRecording('s$i')));
        stubServerDropped('srv-gone');

        final container = realContainer();
        addTearDown(container.dispose);
        await container
            .read(recordingsListNotifierProvider.notifier)
            .fetchRecordings();

        final state = container.read(recordingsListNotifierProvider);
        expect(state.hasMore, isTrue);
        expect(state.recordings.map((r) => r.id), contains('local-uuid'));
        expect(await realLocal.getRecordingById('local-uuid'), isNotNull);
        expect(file.existsSync(), isTrue);
      },
    );

    test('an empty server answer is too ambiguous to erase anything', () async {
      // A 200 with an empty list looks the same whether the project is really
      // empty, the caller lost access, or the backend scoped the query wrong.
      final file = await insertRow(
        id: 'local-uuid',
        serverId: 'srv-gone',
        uploadStatus: 'uploaded',
      );
      stubServerPage(const []);
      stubServerDropped('srv-gone');

      final container = realContainer();
      addTearDown(container.dispose);
      await container
          .read(recordingsListNotifierProvider.notifier)
          .fetchRecordings();

      expect(
        container
            .read(recordingsListNotifierProvider)
            .recordings
            .map((r) => r.id),
        contains('local-uuid'),
      );
      expect(await realLocal.getRecordingById('local-uuid'), isNotNull);
      expect(file.existsSync(), isTrue);
    });

    test('a filtered answer that lands after the filter was cleared erases '
        'nothing', () async {
      // The user filters, changes their mind and clears on a slow link. The
      // narrow response arrives last: judged against the filters in state by
      // then (none) it would read as a complete sweep, and the recording it
      // merely excluded would be erased — while still on the server.
      final file = await insertRow(
        id: 'local-uuid',
        serverId: 'srv-gone',
        uploadStatus: 'uploaded',
      );

      final filteredGate = Completer<List<ServerRecording>>();
      when(
        () => api.listRecordings(
          'proj-1',
          offset: 0,
          limit: any(named: 'limit'),
          userId: any(named: 'userId'),
          storytellerId: 'st-1',
          reviewFlag: any(named: 'reviewFlag'),
        ),
      ).thenAnswer((_) => filteredGate.future);
      when(
        () => api.listRecordings(
          'proj-1',
          offset: 0,
          limit: any(named: 'limit'),
          userId: any(named: 'userId'),
          storytellerId: null,
          reviewFlag: any(named: 'reviewFlag'),
        ),
      ).thenAnswer((_) async => [_makeServerRecording('srv-gone')]);
      stubServerStillHas('srv-gone');

      final container = realContainer();
      addTearDown(container.dispose);
      final notifier = container.read(recordingsListNotifierProvider.notifier);

      final filtered = notifier.setStorytellerFilter('st-1');
      final cleared = notifier.setStorytellerFilter(null);
      await cleared;
      // The stale filtered page resolves last, with no filter left in state.
      filteredGate.complete([_makeServerRecording('srv-other')]);
      await filtered;

      expect(await realLocal.getRecordingById('local-uuid'), isNotNull);
      expect(file.existsSync(), isTrue);
      // The stale filtered page never put the row on trial in the first place.
      verifyNever(() => api.getRecording(any()));
      expect(
        container
            .read(recordingsListNotifierProvider)
            .recordings
            .map((r) => r.id),
        ['srv-gone'],
      );
    });

    test('an active filter narrows the answer: nothing is dropped', () async {
      final file = await insertRow(
        id: 'local-uuid',
        serverId: 'srv-gone',
        uploadStatus: 'uploaded',
      );
      stubServerPage([_makeServerRecording('srv-live')]);
      stubServerStillHas('srv-gone');

      final container = realContainer();
      addTearDown(container.dispose);
      await container
          .read(recordingsListNotifierProvider.notifier)
          .setStorytellerFilter('st-1');

      expect(
        container
            .read(recordingsListNotifierProvider)
            .recordings
            .map((r) => r.id),
        contains('local-uuid'),
      );
      expect(await realLocal.getRecordingById('local-uuid'), isNotNull);
      expect(file.existsSync(), isTrue);
      // A filtered answer does not even put the rows it excluded on trial.
      verifyNever(() => api.getRecording(any()));
    });
  });

  group('RecordingsListNotifier — paginated server-side deletion', () {
    late Directory tmpDir;
    late AppDatabase db;
    late LocalRecordingRepository realLocal;
    late _SwitchableProjectNotifier projects;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('eng400_heal_');
      db = AppDatabase.forTesting(NativeDatabase.memory());
      realLocal = LocalRecordingRepository(db);
      projects = _SwitchableProjectNotifier(
        ProjectState(activeProject: activeProject),
      );
    });

    tearDown(() async {
      await db.close();
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    });

    // Real Drift repo (in-memory): the reconciliation has to hit the actual row
    // and its audio file, which a mocked repo would only pretend to do.
    ProviderContainer realContainer() => ProviderContainer(
      overrides: [
        recordingApiRepositoryProvider.overrideWithValue(api),
        localRecordingRepositoryProvider.overrideWithValue(realLocal),
        projectNotifierProvider.overrideWith(() => projects),
        syncNotifierProvider.overrideWith(
          () => _FakeSyncNotifier(initialOnline: true),
        ),
        errorReporterProvider.overrideWithValue(reporter),
      ],
    );

    Future<File> insertRow({
      required String id,
      required String? serverId,
      required String uploadStatus,
      String projectId = 'proj-1',
    }) async {
      final file = File('${tmpDir.path}/$id.m4a')
        ..writeAsStringSync('audio-bytes');
      await realLocal.insertRecording(
        LocalRecordingsCompanion.insert(
          id: id,
          projectId: projectId,
          genreId: 'genre-1',
          localFilePath: file.path,
          recordedAt: DateTime(2026, 1, 1),
          serverId: Value(serverId),
          uploadStatus: Value(uploadStatus),
        ),
      );
      return file;
    }

    List<ServerRecording> fullPage(String prefix) =>
        List.generate(50, (i) => _makeServerRecording('$prefix$i'));

    void stubPage(
      int offset,
      Future<List<ServerRecording>> Function() answer, {
      String projectId = 'proj-1',
    }) {
      when(
        () => api.listRecordings(
          projectId,
          offset: offset,
          limit: any(named: 'limit'),
          userId: any(named: 'userId'),
          storytellerId: any(named: 'storytellerId'),
          reviewFlag: any(named: 'reviewFlag'),
        ),
      ).thenAnswer((_) => answer());
    }

    // The sweep only suspects; the direct read is what decides. Every test here
    // stubs it, so a row that survives does so because a guard held, not
    // because the confirmation happened to be unstubbed.
    void stubServerDropped(String serverId) {
      when(
        () => api.getRecording(serverId),
      ).thenThrow(const ValidationException(statusCode: 404));
    }

    void stubServerStillHas(String serverId) {
      when(
        () => api.getRecording(serverId),
      ).thenAnswer((_) async => _makeServerRecording(serverId));
    }

    test(
      'pagination to the last page erases an uploaded row no page showed',
      () async {
        final file = await insertRow(
          id: 'local-uuid',
          serverId: 'srv-gone',
          uploadStatus: 'uploaded',
        );
        stubPage(0, () async => fullPage('s'));
        stubPage(
          50,
          () async =>
              List.generate(10, (i) => _makeServerRecording('s${50 + i}')),
        );
        stubServerDropped('srv-gone');

        final container = realContainer();
        addTearDown(container.dispose);
        final notifier = container.read(
          recordingsListNotifierProvider.notifier,
        );

        await notifier.fetchRecordings();
        await notifier.loadMore();

        expect(await realLocal.getRecordingById('local-uuid'), isNull);
        expect(file.existsSync(), isFalse);
        // A confirmed delete is the feature working, not a failure to report.
        expect(reporter.reported, isEmpty);
        expect(
          container
              .read(recordingsListNotifierProvider)
              .recordings
              .map((r) => r.id),
          isNot(contains('local-uuid')),
        );
      },
    );

    test(
      'a full page mid-pagination erases nothing: more pages may hold it',
      () async {
        final file = await insertRow(
          id: 'local-uuid',
          serverId: 'srv-gone',
          uploadStatus: 'uploaded',
        );
        stubPage(0, () async => fullPage('s'));
        stubPage(50, () async => fullPage('t'));
        stubServerDropped('srv-gone');

        final container = realContainer();
        addTearDown(container.dispose);
        final notifier = container.read(
          recordingsListNotifierProvider.notifier,
        );

        await notifier.fetchRecordings();
        await notifier.loadMore();

        expect(container.read(recordingsListNotifierProvider).hasMore, isTrue);
        expect(await realLocal.getRecordingById('local-uuid'), isNotNull);
        expect(file.existsSync(), isTrue);
      },
    );

    test(
      'a filtered pagination cannot close the sweep the unfiltered page opened',
      () async {
        final file = await insertRow(
          id: 'local-uuid',
          serverId: 'srv-gone',
          uploadStatus: 'uploaded',
        );
        // Unfiltered first page, then the user filters: the filtered pagination
        // that follows never covers the whole project, so the ids collected
        // before the filter must not be reused to judge it.
        when(
          () => api.listRecordings(
            'proj-1',
            offset: 0,
            limit: any(named: 'limit'),
            userId: any(named: 'userId'),
            storytellerId: null,
            reviewFlag: any(named: 'reviewFlag'),
          ),
        ).thenAnswer((_) async => fullPage('s'));
        when(
          () => api.listRecordings(
            'proj-1',
            offset: 0,
            limit: any(named: 'limit'),
            userId: any(named: 'userId'),
            storytellerId: 'st-1',
            reviewFlag: any(named: 'reviewFlag'),
          ),
        ).thenAnswer((_) async => fullPage('f'));
        stubPage(
          50,
          () async =>
              List.generate(5, (i) => _makeServerRecording('f${50 + i}')),
        );
        stubServerDropped('srv-gone');

        final container = realContainer();
        addTearDown(container.dispose);
        final notifier = container.read(
          recordingsListNotifierProvider.notifier,
        );

        await notifier.fetchRecordings();
        await notifier.setStorytellerFilter('st-1');
        await notifier.loadMore();

        expect(await realLocal.getRecordingById('local-uuid'), isNotNull);
        expect(file.existsSync(), isTrue);
      },
    );

    test(
      'a project switch mid-pagination puts no row of the new project on trial',
      () async {
        final file = await insertRow(
          id: 'other-project-row',
          serverId: 'srv-p2',
          uploadStatus: 'uploaded',
          projectId: 'proj-2',
        );
        stubServerStillHas('srv-p2');
        stubPage(0, () async => fullPage('s'));
        stubPage(
          50,
          () async => [_makeServerRecording('p2-a')],
          projectId: 'proj-2',
        );

        final container = realContainer();
        addTearDown(container.dispose);
        final notifier = container.read(
          recordingsListNotifierProvider.notifier,
        );

        await notifier.fetchRecordings();
        projects.switchTo(
          const Project(id: 'proj-2', name: 'Other', languageId: 'en'),
        );
        await notifier.loadMore();

        expect(
          await realLocal.getRecordingById('other-project-row'),
          isNotNull,
        );
        expect(file.existsSync(), isTrue);
        verifyNever(() => api.getRecording(any()));
      },
    );

    test(
      'a row that never finished uploading survives the paginated sweep',
      () async {
        final file = await insertRow(
          id: 'never-landed',
          serverId: 'srv-gone',
          uploadStatus: 'failed',
        );
        stubPage(0, () async => fullPage('s'));
        stubPage(50, () async => [_makeServerRecording('s50')]);
        stubServerDropped('srv-gone');

        final container = realContainer();
        addTearDown(container.dispose);
        final notifier = container.read(
          recordingsListNotifierProvider.notifier,
        );

        await notifier.fetchRecordings();
        await notifier.loadMore();

        expect(await realLocal.getRecordingById('never-landed'), isNotNull);
        expect(file.existsSync(), isTrue);
      },
    );

    test('an empty last page still closes the sweep the earlier pages '
        'proved', () async {
      // A project whose count is an exact multiple of the page size always ends
      // on an empty page, so refusing to close on one would leave it forever
      // unhealable. Unlike an empty page zero, this one follows a substantive
      // page in the same scope: the server already showed the query is
      // authorised and well scoped.
      final file = await insertRow(
        id: 'local-uuid',
        serverId: 'srv-gone',
        uploadStatus: 'uploaded',
      );
      stubPage(0, () async => fullPage('s'));
      stubPage(50, () async => const []);
      stubServerDropped('srv-gone');

      final container = realContainer();
      addTearDown(container.dispose);
      final notifier = container.read(recordingsListNotifierProvider.notifier);

      await notifier.fetchRecordings();
      await notifier.loadMore();

      expect(await realLocal.getRecordingById('local-uuid'), isNull);
      expect(file.existsSync(), isFalse);
    });

    test('a superseded fetch does not hand its page to the live sweep', () async {
      // Two refreshes overlap; the stale one resolves last. Its list is already
      // discarded by the generation check, but its ids must not become the
      // sweep the live pagination is completing — the recordings only the newer
      // page listed would then read as deleted.
      final file = await insertRow(
        id: 'local-uuid',
        serverId: 'srv-only-in-newer',
        uploadStatus: 'uploaded',
      );
      final staleGate = Completer<List<ServerRecording>>();
      final firstPages = <Future<List<ServerRecording>>>[
        staleGate.future,
        Future.value([
          _makeServerRecording('srv-only-in-newer'),
          ...List.generate(49, (i) => _makeServerRecording('b$i')),
        ]),
      ];
      var call = 0;
      stubPage(0, () => firstPages[call++]);
      stubPage(50, () async => [_makeServerRecording('b50')]);
      stubServerStillHas('srv-only-in-newer');

      final container = realContainer();
      addTearDown(container.dispose);
      final notifier = container.read(recordingsListNotifierProvider.notifier);

      final stale = notifier.fetchRecordings();
      final live = notifier.fetchRecordings();
      await live;
      staleGate.complete(fullPage('a'));
      await stale;

      await notifier.loadMore();

      expect(await realLocal.getRecordingById('local-uuid'), isNotNull);
      expect(file.existsSync(), isTrue);
      verifyNever(() => api.getRecording(any()));
    });

    test('a refresh during the sweep leaves the erase to the next one', () async {
      // The generation moves synchronously at the top of fetchRecordings, while
      // the erase runs on for a local read plus a round trip per candidate. The
      // list this loadMore is building is already condemned by the refresh, so
      // erasing now would take rows off the device that the screen goes on
      // showing until something else reloads it.
      final row = LocalRecording(
        id: 'local-uuid',
        reviewFlagsJson: '[]',
        // The metadata outbox defaults (ENG-403): this row owes the server no edit.
        metadataSyncStatus: 'synced',
        pendingMetadataJson: '[]',
        metadataRetryCount: 0,
        projectId: 'proj-1',
        genreId: 'genre-1',
        durationSeconds: 30.0,
        fileSizeBytes: 1024,
        format: 'm4a',
        localFilePath: '',
        uploadStatus: 'uploaded',
        serverId: 'srv-gone',
        cleaningStatus: 'none',
        recordedAt: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        retryCount: 0,
        uploadedBytes: 0,
      );
      var localReads = 0;
      final sweepRead = Completer<List<LocalRecording>>();
      when(() => local.getAllRecordings('proj-1')).thenAnswer((_) {
        localReads++;
        // The second read is the sweep's own, the one the refresh interrupts.
        return localReads == 2 ? sweepRead.future : Future.value([row]);
      });
      when(() => local.deleteRecording(any())).thenAnswer((_) async => true);
      stubPage(0, () async => fullPage('s'));
      stubPage(50, () async => [_makeServerRecording('s50')]);
      stubServerDropped('srv-gone');

      final container = makeContainer(online: true);
      addTearDown(container.dispose);
      final notifier = container.read(recordingsListNotifierProvider.notifier);

      await notifier.fetchRecordings();
      final paging = notifier.loadMore();
      await pumpUntil(() => localReads >= 2);
      final refresh = notifier.fetchRecordings();
      sweepRead.complete([row]);
      await paging;
      await refresh;

      verifyNever(() => local.deleteRecording(any()));
    });

    test('a candidate the server could not be reached about is kept', () async {
      // Only a 404 is an answer. A link that drops mid-confirmation says
      // nothing about the recording, and guessing costs the row.
      final file = await insertRow(
        id: 'local-uuid',
        serverId: 'srv-gone',
        uploadStatus: 'uploaded',
      );
      stubPage(0, () async => fullPage('s'));
      stubPage(50, () async => [_makeServerRecording('s50')]);
      when(
        () => api.getRecording('srv-gone'),
      ).thenThrow(const NetworkException());

      final container = realContainer();
      addTearDown(container.dispose);
      final notifier = container.read(recordingsListNotifierProvider.notifier);

      await notifier.fetchRecordings();
      await notifier.loadMore();

      expect(await realLocal.getRecordingById('local-uuid'), isNotNull);
      expect(file.existsSync(), isTrue);
      // Silence here would switch healing off for good with nothing in
      // telemetry to say so (ENG-102).
      expect(reporter.reported, contains(isA<NetworkException>()));
    });

    test(
      'a refresh mid-confirmation drops the confirmations still queued',
      () async {
        // The confirmations are bounded, so a backlog waits its turn; a refresh
        // means this sweep's work is already discarded, and on a link with no
        // response timeout that queue is what turns a spinner into minutes.
        final rows = <File>[];
        for (var i = 0; i < 8; i++) {
          rows.add(
            await insertRow(
              id: 'cand-$i',
              serverId: 'srv-c$i',
              uploadStatus: 'uploaded',
            ),
          );
        }
        stubPage(0, () async => fullPage('s'));
        stubPage(50, () async => [_makeServerRecording('s50')]);
        var asked = 0;
        final held = Completer<ServerRecording>();
        when(() => api.getRecording(any())).thenAnswer((_) {
          asked++;
          return held.future;
        });

        final container = realContainer();
        addTearDown(container.dispose);
        final notifier = container.read(
          recordingsListNotifierProvider.notifier,
        );

        await notifier.fetchRecordings();
        final paging = notifier.loadMore();
        await pumpUntil(() => asked > 0);
        final inFlight = asked;

        final refresh = notifier.fetchRecordings();
        // The in-flight confirmations come back positive, so the refresh is the
        // only thing standing between these rows and deletion.
        held.completeError(const ValidationException(statusCode: 404));
        await paging;
        await refresh;

        // Whatever was already in flight finishes; the rest is never asked.
        expect(asked, inFlight);
        expect(asked, lessThan(rows.length));
        for (var i = 0; i < rows.length; i++) {
          expect(await realLocal.getRecordingById('cand-$i'), isNotNull);
          expect(rows[i].existsSync(), isTrue);
        }
      },
    );

    test(
      'an upload that lands mid-pagination is not read as a deletion',
      () async {
        // The queue finishes while the user scrolls. The row gains its serverId
        // after page 0 was already read, and the server sorts newest first, so
        // the recording belongs to a window that has been consumed: it shows up
        // on no page of this sweep while being perfectly present on the server.
        final file = await insertRow(
          id: 'just-uploaded',
          serverId: null,
          uploadStatus: 'uploading',
        );
        stubPage(0, () async => fullPage('s'));
        stubPage(
          50,
          () async =>
              List.generate(10, (i) => _makeServerRecording('s${50 + i}')),
        );
        stubServerStillHas('srv-late');

        final container = realContainer();
        addTearDown(container.dispose);
        final notifier = container.read(
          recordingsListNotifierProvider.notifier,
        );

        await notifier.fetchRecordings();
        await realLocal.updateRecording(
          'just-uploaded',
          const LocalRecordingsCompanion(
            serverId: Value('srv-late'),
            uploadStatus: Value('uploaded'),
          ),
        );
        await notifier.loadMore();

        expect(await realLocal.getRecordingById('just-uploaded'), isNotNull);
        expect(file.existsSync(), isTrue);
      },
    );

    test('a row the offset window skipped is not read as a deletion', () async {
      // An admin deletes srv-7 between the two requests, so everything after it
      // shifts one position and the offset=50 window opens at srv-51. srv-50 is
      // never returned by any page, and it was never deleted.
      final file = await insertRow(
        id: 'skipped-row',
        serverId: 'srv-50',
        uploadStatus: 'uploaded',
      );
      stubPage(
        0,
        () async => List.generate(50, (i) => _makeServerRecording('srv-$i')),
      );
      stubPage(
        50,
        () async =>
            List.generate(9, (i) => _makeServerRecording('srv-${51 + i}')),
      );
      stubServerStillHas('srv-50');

      final container = realContainer();
      addTearDown(container.dispose);
      final notifier = container.read(recordingsListNotifierProvider.notifier);

      await notifier.fetchRecordings();
      await notifier.loadMore();

      expect(await realLocal.getRecordingById('skipped-row'), isNotNull);
      expect(file.existsSync(), isTrue);
    });

    test('a sweep left open by an earlier visit cannot condemn what arrived '
        'since', () async {
      // The notifier outlives the screen (no autoDispose) and the screen reuses
      // its State across tab switches and deep links, so initState does not run
      // again: a sweep opened on one visit is still open on the next, and the
      // page that closes it can be pages and minutes apart from the one that
      // opened it. A recording made in between belongs to the consumed window.
      stubPage(0, () async => fullPage('s'));
      stubPage(50, () async => fullPage('t'));

      final container = realContainer();
      addTearDown(container.dispose);
      final notifier = container.read(recordingsListNotifierProvider.notifier);

      await notifier.fetchRecordings();
      await notifier.loadMore();

      // The user leaves, records and uploads, and comes back to the same State.
      final file = await insertRow(
        id: 'recorded-between-visits',
        serverId: 'srv-new',
        uploadStatus: 'uploaded',
      );
      stubServerStillHas('srv-new');
      stubPage(100, () async => [_makeServerRecording('u0')]);

      await notifier.loadMore();

      expect(
        await realLocal.getRecordingById('recorded-between-visits'),
        isNotNull,
      );
      expect(file.existsSync(), isTrue);
    });
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
