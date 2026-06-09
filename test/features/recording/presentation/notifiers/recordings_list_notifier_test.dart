import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
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

class _FakeSyncNotifier extends SyncNotifier {
  _FakeSyncNotifier({required this.initialOnline});

  final bool initialOnline;

  @override
  SyncState build() => SyncState(isOnline: initialOnline);

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
    ],
  );

  setUp(() {
    api = _MockApi();
    local = _MockLocal();
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
}
