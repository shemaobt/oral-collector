/// Filtering the recordings list by review flag (ENG-381).
///
/// The filter has to reach the server. Gênero, status and search filter the
/// page already in memory, which would silently hide every flagged recording
/// past the first page — and would make the list disagree with the counter
/// that sent the user here, which is the ENG-377 bug shape.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/observability/error_reporter.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/review_pendency.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recordings_list_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';

class _MockApi extends Mock implements RecordingApiRepository {}

class _MockLocal extends Mock implements LocalRecordingRepository {}

class _SilentReporter implements ErrorReporter {
  @override
  void reportError(
    Object error,
    StackTrace? stackTrace, {
    Map<String, String>? tags,
    Map<String, Object?>? context,
    ErrorLevel level = ErrorLevel.error,
  }) {}

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
}

class _FakeProjectNotifier extends ProjectNotifier {
  _FakeProjectNotifier(this._state);

  final ProjectState _state;

  @override
  ProjectState build() => _state;
}

LocalRecording _localOnly(String id) => LocalRecording(
  id: id,
  reviewFlagsJson: '[]',
  projectId: 'proj-1',
  genreId: 'genre-1',
  title: 'Local $id',
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

ServerRecording _flagged(String id) => ServerRecording(
  id: id,
  projectId: 'proj-1',
  genreId: 'unclassified',
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

  const activeProject = Project(id: 'proj-1', name: 'Test', languageId: 'en');

  ProviderContainer makeContainer({required bool online}) => ProviderContainer(
    overrides: [
      recordingApiRepositoryProvider.overrideWithValue(api),
      localRecordingRepositoryProvider.overrideWithValue(local),
      projectNotifierProvider.overrideWith(
        () => _FakeProjectNotifier(
          const ProjectState(activeProject: activeProject),
        ),
      ),
      syncNotifierProvider.overrideWith(
        () => _FakeSyncNotifier(initialOnline: online),
      ),
      errorReporterProvider.overrideWithValue(_SilentReporter()),
    ],
  );

  setUp(() {
    api = _MockApi();
    local = _MockLocal();
    when(() => local.getAllRecordings('proj-1')).thenAnswer((_) async => []);
  });

  test('choosing a pendency asks the server for that code', () async {
    when(
      () => api.listRecordings(
        'proj-1',
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
        userId: any(named: 'userId'),
        storytellerId: any(named: 'storytellerId'),
        reviewFlag: any(named: 'reviewFlag'),
      ),
    ).thenAnswer((_) async => [_flagged('s1')]);

    final container = makeContainer(online: true);
    addTearDown(container.dispose);

    await container
        .read(recordingsListNotifierProvider.notifier)
        .setReviewFlagFilter(PendencyKind.classification);

    verify(
      () => api.listRecordings(
        'proj-1',
        offset: 0,
        limit: any(named: 'limit'),
        userId: any(named: 'userId'),
        storytellerId: any(named: 'storytellerId'),
        reviewFlag: 'missing_classification',
      ),
    ).called(1);
  });

  test('a filtered list does not quietly gain the recordings still on the '
      'device', () async {
    // The server counts only uploaded and verified recordings, so a row that
    // exists nowhere but this phone was never part of the number the user
    // tapped. Merging it in would answer a different question than the one
    // asked.
    when(
      () => local.getAllRecordings('proj-1'),
    ).thenAnswer((_) async => [_localOnly('l1'), _localOnly('l2')]);
    when(
      () => api.listRecordings(
        'proj-1',
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
        userId: any(named: 'userId'),
        storytellerId: any(named: 'storytellerId'),
        reviewFlag: any(named: 'reviewFlag'),
      ),
    ).thenAnswer((_) async => [_flagged('s1')]);

    final container = makeContainer(online: true);
    addTearDown(container.dispose);

    await container
        .read(recordingsListNotifierProvider.notifier)
        .setReviewFlagFilter(PendencyKind.classification);

    final state = container.read(recordingsListNotifierProvider);
    expect(state.recordings.map((r) => r.id), ['s1']);
  });

  test('an unfiltered list still shows what is on the device', () async {
    when(
      () => local.getAllRecordings('proj-1'),
    ).thenAnswer((_) async => [_localOnly('l1')]);
    when(
      () => api.listRecordings(
        'proj-1',
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
        userId: any(named: 'userId'),
        storytellerId: any(named: 'storytellerId'),
        reviewFlag: any(named: 'reviewFlag'),
      ),
    ).thenAnswer((_) async => [_flagged('s1')]);

    final container = makeContainer(online: true);
    addTearDown(container.dispose);

    await container
        .read(recordingsListNotifierProvider.notifier)
        .fetchRecordings();

    final state = container.read(recordingsListNotifierProvider);
    expect(state.recordings.map((r) => r.id), containsAll(['l1', 's1']));
  });

  test(
    'offline with a pendency chosen shows nothing rather than everything',
    () async {
      // The local fallback cannot honour a server-computed filter. Handing back
      // the whole device would present unfiltered recordings under a filter the
      // user can see is applied.
      when(
        () => local.getAllRecordings('proj-1'),
      ).thenAnswer((_) async => [_localOnly('l1'), _localOnly('l2')]);

      final container = makeContainer(online: false);
      addTearDown(container.dispose);

      await container
          .read(recordingsListNotifierProvider.notifier)
          .setReviewFlagFilter(PendencyKind.storyteller);

      final state = container.read(recordingsListNotifierProvider);
      expect(state.recordings, isEmpty);
    },
  );

  test('a chosen pendency counts as an active filter', () async {
    when(
      () => api.listRecordings(
        'proj-1',
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
        userId: any(named: 'userId'),
        storytellerId: any(named: 'storytellerId'),
        reviewFlag: any(named: 'reviewFlag'),
      ),
    ).thenAnswer((_) async => []);

    final container = makeContainer(online: true);
    addTearDown(container.dispose);

    final notifier = container.read(recordingsListNotifierProvider.notifier);
    await notifier.setReviewFlagFilter(PendencyKind.description);

    // Without this the list would look unfiltered: no chip, no badge, no way
    // back to the full list.
    expect(container.read(recordingsListNotifierProvider).activeFilterCount, 1);

    await notifier.clearAllFilters();
    expect(container.read(recordingsListNotifierProvider).activeFilterCount, 0);
  });
}
