import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
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
    test('offline returns 0 without touching server or local', () async {
      final container = makeContainer(online: false);
      addTearDown(container.dispose);

      final result = await container
          .read(recordingsListNotifierProvider.notifier)
          .clearStaleRecordings();

      expect(result, 0);
      verifyNever(() => api.clearStaleRecordings(any()));
      verifyNever(() => local.deleteStaleRecordings(any()));
    });
  });
}
