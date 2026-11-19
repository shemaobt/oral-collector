import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/features/project/data/project_cache.dart';
import 'package:oral_collector/features/project/data/providers.dart';
import 'package:oral_collector/features/project/domain/entities/language.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/domain/repositories/project_repository.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockProjectRepository extends Mock implements ProjectRepository {}

/// Cache fake whose [read] can be gated on a [Completer], forcing the
/// interleaving (fetch completes before hydration) that the static
/// SharedPreferences singleton makes unreachable. [read] returns a fixed
/// snapshot — unaffected by [write] — so a late hydration genuinely carries
/// the stale data the guard must reject.
class FakeProjectCache implements ProjectCache {
  FakeProjectCache({this.cached, this.gateRead = false});

  final ProjectCacheSnapshot? cached;
  final bool gateRead;
  final Completer<void> readGate = Completer<void>();

  @override
  Future<ProjectCacheSnapshot?> read() async {
    if (gateRead) await readGate.future;
    return cached;
  }

  List<Project>? written;

  @override
  Future<void> write(List<Project> projects, List<Language> languages) async {
    written = projects;
  }
}

Project _project(String id) =>
    Project(id: id, name: 'name-$id', languageId: 'lang-$id');

Project _projectWithStorytellers() => Project(
  id: 'p1',
  name: 'Kaingang stories',
  languageId: 'l1',
  description: 'Stories told by elders',
  memberCount: 3,
  recordingCount: 6,
  totalDurationSeconds: 125.5,
  storytellerCount: 4,
  createdAt: DateTime.utc(2026, 11, 1, 9, 30),
);

const _kaingang = Language(id: 'l1', name: 'Kaingang', code: 'kgp');

void main() {
  late MockProjectRepository repo;

  setUp(() {
    repo = MockProjectRepository();
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer makeContainer(ProjectCache cache) {
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repo),
        projectCacheProvider.overrideWithValue(cache),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'a completed fetch is not overwritten by a late stale-cache hydration',
    () async {
      final cache = FakeProjectCache(
        cached: ProjectCacheSnapshot(
          projects: [_project('stale-1'), _project('stale-2')],
          languages: const [Language(id: 'l-stale', name: 'Stale', code: 'st')],
        ),
        gateRead: true,
      );
      when(() => repo.listProjects()).thenAnswer(
        (_) async => [_project('srv-1'), _project('srv-2'), _project('srv-3')],
      );
      when(() => repo.listLanguages()).thenAnswer(
        (_) async => [const Language(id: 'l-srv', name: 'Server', code: 'sv')],
      );

      final container = makeContainer(cache);
      // build() fires _hydrateFromCache, which parks inside the gated read().
      final notifier = container.read(projectNotifierProvider.notifier);

      await notifier.fetchProjects(); // completes: server data + lastFetched

      var state = container.read(projectNotifierProvider);
      expect(state.projects.map((p) => p.id).toList(), [
        'srv-1',
        'srv-2',
        'srv-3',
      ]);
      expect(state.lastFetched, isNotNull);

      cache.readGate.complete(); // release the late hydration
      await pumpEventQueue();

      state = container.read(projectNotifierProvider);
      expect(
        state.projects.map((p) => p.id).toList(),
        ['srv-1', 'srv-2', 'srv-3'],
        reason:
            'stale cache must not overwrite server data after a completed fetch',
      );
    },
  );

  test('cached projects hydrate state when no fetch occurs', () async {
    final cache = FakeProjectCache(
      cached: ProjectCacheSnapshot(
        projects: [_project('cached-1'), _project('cached-2')],
        languages: const [Language(id: 'l1', name: 'Lang', code: 'ln')],
      ),
    );
    final container = makeContainer(cache);

    container.read(projectNotifierProvider);
    await pumpEventQueue();

    final state = container.read(projectNotifierProvider);
    expect(state.projects.map((p) => p.id).toList(), ['cached-1', 'cached-2']);
    expect(state.lastFetched, isNull);
  });

  test(
    'a project with storytellers keeps every field when its language name is filled in',
    () async {
      final fetched = _projectWithStorytellers();
      when(() => repo.listProjects()).thenAnswer((_) async => [fetched]);
      when(() => repo.listLanguages()).thenAnswer((_) async => [_kaingang]);
      final container = makeContainer(FakeProjectCache());

      await container.read(projectNotifierProvider.notifier).fetchProjects();

      final project = container.read(projectNotifierProvider).projects.single;
      expect(project.storytellerCount, 4, reason: 'the card showed 0');
      expect(
        project.toJson(),
        {
          ...fetched.toJson(),
          'language_name': 'Kaingang',
          'language_code': 'kgp',
        },
        reason: 'the rebuild copied fields by hand and dropped one',
      );
    },
  );

  test('the active project Home reads keeps its storyteller count', () async {
    when(
      () => repo.listProjects(),
    ).thenAnswer((_) async => [_projectWithStorytellers()]);
    when(() => repo.listLanguages()).thenAnswer((_) async => [_kaingang]);
    final container = makeContainer(FakeProjectCache());

    await container.read(projectNotifierProvider.notifier).fetchProjects();

    final active = container.read(projectNotifierProvider).activeProject;
    expect(active?.id, 'p1');
    expect(active?.storytellerCount, 4, reason: 'the Home tile showed 0');
  });

  test(
    'the cache is written with the storyteller count the server sent',
    () async {
      when(
        () => repo.listProjects(),
      ).thenAnswer((_) async => [_projectWithStorytellers()]);
      when(() => repo.listLanguages()).thenAnswer((_) async => [_kaingang]);
      final cache = FakeProjectCache();
      final container = makeContainer(cache);

      await container.read(projectNotifierProvider.notifier).fetchProjects();

      expect(
        cache.written?.single.storytellerCount,
        4,
        reason: 'the cache kept 0',
      );
    },
  );

  test('empty cache leaves state empty', () async {
    final cache = FakeProjectCache(cached: null);
    final container = makeContainer(cache);

    container.read(projectNotifierProvider);
    await pumpEventQueue();

    final state = container.read(projectNotifierProvider);
    expect(state.projects, isEmpty);
    expect(state.lastFetched, isNull);
  });
}
