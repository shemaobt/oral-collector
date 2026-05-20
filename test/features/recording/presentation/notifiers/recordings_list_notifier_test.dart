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

  final activeProject = Project(id: 'proj-1', name: 'Test', languageId: 'en');

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
    test('offline skips API, isLoadingMore returns to false', () async {
      final container = makeContainer(online: false);
      addTearDown(container.dispose);

      final notifier = container.read(recordingsListNotifierProvider.notifier);
      await notifier.loadMore();

      final state = container.read(recordingsListNotifierProvider);
      expect(state.isLoadingMore, isFalse);
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
    });
  });

  group('RecordingsListNotifier.clearStaleRecordings — offline', () {
    test('offline returns null without touching server or local', () async {
      final container = makeContainer(online: false);
      addTearDown(container.dispose);

      final result = await container
          .read(recordingsListNotifierProvider.notifier)
          .clearStaleRecordings();

      expect(result, isNull,
          reason: 'null distinguishes "offline no-op" from a real "0 deleted" success');
      verifyNever(() => api.clearStaleRecordings(any()));
      verifyNever(() => local.deleteStaleRecordings(any()));
    });
  });

  group('RecordingsListNotifier.fetchRecordings — online', () {
    test(
      'online merges server + local-only recordings, ordered by recordedAt desc',
      () async {
        when(() => api.listRecordings(
              'proj-1',
              offset: 0,
              limit: any(named: 'limit'),
              userId: any(named: 'userId'),
              storytellerId: any(named: 'storytellerId'),
            )).thenAnswer(
          (_) async => [_makeServerRecording('srv-1')],
        );
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
        verify(() => api.listRecordings(
              'proj-1',
              offset: 0,
              limit: any(named: 'limit'),
              userId: any(named: 'userId'),
              storytellerId: any(named: 'storytellerId'),
            )).called(1);
      },
    );
  });

  group(
    'RecordingsListNotifier.fetchRecordings — offline → online transition',
    () {
      test(
        'first fetch offline falls back to local; second fetch (post-flip) hits the API',
        () async {
          when(() => local.getAllRecordings('proj-1')).thenAnswer(
            (_) async => [_makeRecording('local-1')],
          );
          when(() => api.listRecordings(
                'proj-1',
                offset: 0,
                limit: any(named: 'limit'),
                userId: any(named: 'userId'),
                storytellerId: any(named: 'storytellerId'),
              )).thenAnswer((_) async => [_makeServerRecording('srv-1')]);

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
            container.read(recordingsListNotifierProvider).recordings.map((r) => r.id),
            ['local-1'],
          );
          verifyNever(() => api.listRecordings(
                any(),
                offset: any(named: 'offset'),
                limit: any(named: 'limit'),
                userId: any(named: 'userId'),
                storytellerId: any(named: 'storytellerId'),
              ));

          fakeSync.setOnline(true);
          await notifier.fetchRecordings();

          verify(() => api.listRecordings(
                'proj-1',
                offset: 0,
                limit: any(named: 'limit'),
                userId: any(named: 'userId'),
                storytellerId: any(named: 'storytellerId'),
              )).called(1);
          final state = container.read(recordingsListNotifierProvider);
          expect(state.recordings.any((r) => r.id == 'srv-1'), isTrue);
        },
      );
    },
  );
}
