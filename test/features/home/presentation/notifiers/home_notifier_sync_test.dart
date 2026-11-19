import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/home/presentation/notifiers/home_notifier.dart';
import 'package:oral_collector/features/project/data/providers.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/domain/entities/stats.dart';
import 'package:oral_collector/features/project/domain/repositories/stats_repository.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/project/presentation/notifiers/stats_notifier.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';

class _FakeProjectNotifier extends ProjectNotifier {
  @override
  ProjectState build() => const ProjectState(
    activeProject: Project(id: 'proj-1', name: 'Test', languageId: 'en'),
  );
}

class _ServerStats implements StatsRepository {
  Map<String, GenreStat> answer = const {};
  final askedFor = <String>[];

  @override
  Future<Map<String, GenreStat>> fetchGenreStats(String projectId) async {
    askedFor.add(projectId);
    return answer;
  }
}

class _FakeSync extends SyncNotifier {
  @override
  SyncState build() => const SyncState(isOnline: true);

  void syncFinished() => state = state.copyWith(lastSyncAt: DateTime.now());
}

void main() {
  late AppDatabase db;
  late LocalRecordingRepository local;
  late _ServerStats server;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    local = LocalRecordingRepository(db);
    server = _ServerStats();
    container = ProviderContainer(
      overrides: [
        localRecordingRepositoryProvider.overrideWithValue(local),
        statsRepositoryProvider.overrideWithValue(server),
        projectNotifierProvider.overrideWith(_FakeProjectNotifier.new),
        syncNotifierProvider.overrideWith(_FakeSync.new),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
  });

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  test('a finished sync round asks the server for the genre counts again, so '
      'the cards follow a save', () async {
    container.read(homeNotifierProvider);
    server.answer = const {
      'genre-1': GenreStat(
        genreId: 'genre-1',
        totalDurationSeconds: 60,
        recordingCount: 1,
      ),
    };

    (container.read(syncNotifierProvider.notifier) as _FakeSync).syncFinished();
    await settle();

    expect(
      container
          .read(statsNotifierProvider)
          .genreStats['genre-1']
          ?.recordingCount,
      1,
      reason: 'o cartão do gênero seguia no número antigo depois do envio',
    );
  });

  test('a recording that just uploaded is counted once, by the server, and '
      'not again as a recording only this phone holds', () async {
    await local.insertRecording(
      LocalRecordingsCompanion(
        id: const Value('r1'),
        projectId: const Value('proj-1'),
        genreId: const Value('genre-1'),
        localFilePath: const Value('/tmp/r1.m4a'),
        uploadStatus: const Value('local'),
        durationSeconds: const Value(60),
        recordedAt: Value(DateTime.utc(2026, 5, 1)),
        createdAt: Value(DateTime.utc(2026, 5, 1)),
      ),
    );
    await container.read(homeNotifierProvider.notifier).refreshAll();
    expect(container.read(homeNotifierProvider).totalRecordings, 1);

    await local.updateRecording(
      'r1',
      const LocalRecordingsCompanion(uploadStatus: Value('uploaded')),
    );
    server.answer = const {
      'genre-1': GenreStat(
        genreId: 'genre-1',
        totalDurationSeconds: 120,
        recordingCount: 2,
      ),
    };
    (container.read(syncNotifierProvider.notifier) as _FakeSync).syncFinished();
    await settle();

    expect(
      container.read(homeNotifierProvider).totalRecordings,
      2,
      reason:
          'a gravação enviada contava uma vez no aparelho e outra no servidor',
    );
  });
}
