/// The home total is `what the server has` + `what only this device has`.
///
/// It used to be `pending uploads` + `unclassified`, two overlapping sets: a
/// recording that was both got counted twice, and one in a terminal `failed_*`
/// state that was already classified fell out of both. Two devices holding the
/// same list therefore showed different totals. See ENG-355.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/home/presentation/notifiers/home_notifier.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/domain/entities/stats.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/project/presentation/notifiers/stats_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/stats_state.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/classification.dart';

class _FakeProjectNotifier extends ProjectNotifier {
  _FakeProjectNotifier(this._state);

  final ProjectState _state;

  @override
  ProjectState build() => _state;
}

class _FakeStatsNotifier extends StatsNotifier {
  _FakeStatsNotifier(this._state);

  final StatsState _state;

  @override
  StatsState build() => _state;
}

void main() {
  late AppDatabase db;
  late LocalRecordingRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seed({
    required String id,
    String projectId = 'proj-1',
    String genreId = 'genre-1',
    String? registerId = 'register-1',
    String uploadStatus = 'local',
    double durationSeconds = 60,
  }) {
    return repo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(id),
        projectId: Value(projectId),
        genreId: Value(genreId),
        registerId: Value(registerId),
        localFilePath: Value('/tmp/$id.m4a'),
        uploadStatus: Value(uploadStatus),
        durationSeconds: Value(durationSeconds),
        recordedAt: Value(DateTime.utc(2026, 5, 1)),
        createdAt: Value(DateTime.utc(2026, 5, 1)),
      ),
    );
  }

  ProviderContainer makeContainer({
    Map<String, GenreStat> genreStats = const {},
  }) {
    final container = ProviderContainer(
      overrides: [
        localRecordingRepositoryProvider.overrideWithValue(repo),
        projectNotifierProvider.overrideWith(
          () => _FakeProjectNotifier(
            const ProjectState(
              activeProject: Project(
                id: 'proj-1',
                name: 'Test',
                languageId: 'en',
              ),
            ),
          ),
        ),
        statsNotifierProvider.overrideWith(
          () => _FakeStatsNotifier(StatsState(genreStats: genreStats)),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('a local unclassified recording is counted once, not twice', () async {
    await seed(
      id: 'r1',
      genreId: kUnclassifiedGenreId,
      registerId: null,
      uploadStatus: 'local',
    );

    final container = makeContainer();
    await container.read(homeNotifierProvider.notifier).refreshAll();

    final state = container.read(homeNotifierProvider);
    expect(state.totalRecordings, 1);
    expect(state.totalDuration, 60);
  });

  test(
    'a classified recording in a terminal failed state still counts',
    () async {
      await seed(id: 'r1', uploadStatus: 'failed_exhausted');

      final container = makeContainer();
      await container.read(homeNotifierProvider.notifier).refreshAll();

      final state = container.read(homeNotifierProvider);
      expect(state.totalRecordings, 1);
      expect(state.totalDuration, 60);
    },
  );

  test('server stats and device-only recordings add up', () async {
    await seed(id: 'r1', uploadStatus: 'local', durationSeconds: 30);

    final container = makeContainer(
      genreStats: const {
        'genre-1': GenreStat(
          genreId: 'genre-1',
          totalDurationSeconds: 300,
          recordingCount: 3,
        ),
      },
    );
    await container.read(homeNotifierProvider.notifier).refreshAll();

    final state = container.read(homeNotifierProvider);
    expect(state.totalRecordings, 4);
    expect(state.totalDuration, 330);
  });

  test('recordings the server already has are not re-counted', () async {
    await seed(id: 'r1', uploadStatus: 'uploaded');
    await seed(id: 'r2', uploadStatus: 'verified');

    final container = makeContainer(
      genreStats: const {
        'genre-1': GenreStat(
          genreId: 'genre-1',
          totalDurationSeconds: 120,
          recordingCount: 2,
        ),
      },
    );
    await container.read(homeNotifierProvider.notifier).refreshAll();

    expect(container.read(homeNotifierProvider).totalRecordings, 2);
  });

  test('recordings from another project are excluded', () async {
    await seed(id: 'r1', uploadStatus: 'local');
    await seed(id: 'other', projectId: 'proj-2', uploadStatus: 'local');

    final container = makeContainer();
    await container.read(homeNotifierProvider.notifier).refreshAll();

    expect(container.read(homeNotifierProvider).totalRecordings, 1);
  });

  group('unclassifiedCount badge is a separate number and must not change', () {
    test('counts the local unclassified recording', () async {
      await seed(
        id: 'r1',
        genreId: kUnclassifiedGenreId,
        registerId: null,
        uploadStatus: 'local',
      );

      final container = makeContainer();
      await container.read(homeNotifierProvider.notifier).refreshAll();

      expect(container.read(homeNotifierProvider).unclassifiedCount, 1);
    });

    test('adds the server-side unclassified stat', () async {
      await seed(
        id: 'r1',
        genreId: kUnclassifiedGenreId,
        registerId: null,
        uploadStatus: 'local',
      );

      final container = makeContainer(
        genreStats: const {
          kUnclassifiedGenreId: GenreStat(
            genreId: kUnclassifiedGenreId,
            totalDurationSeconds: 120,
            recordingCount: 2,
          ),
        },
      );
      await container.read(homeNotifierProvider.notifier).refreshAll();

      expect(container.read(homeNotifierProvider).unclassifiedCount, 3);
    });

    test('a classified recording does not reach the badge', () async {
      await seed(id: 'r1', uploadStatus: 'failed_exhausted');

      final container = makeContainer();
      await container.read(homeNotifierProvider.notifier).refreshAll();

      expect(container.read(homeNotifierProvider).unclassifiedCount, 0);
    });
  });
}
