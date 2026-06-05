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

  @override
  Future<void> write(List<Project> projects, List<Language> languages) async {}
}

Project _project(String id) =>
    Project(id: id, name: 'name-$id', languageId: 'lang-$id');

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
