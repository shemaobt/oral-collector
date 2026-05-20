import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/features/storyteller/data/providers.dart';
import 'package:oral_collector/features/storyteller/data/repositories/local_storyteller_repository.dart';
import 'package:oral_collector/features/storyteller/domain/entities/storyteller.dart';
import 'package:oral_collector/features/storyteller/domain/repositories/storyteller_repository.dart';
import 'package:oral_collector/features/storyteller/presentation/notifiers/project_storytellers_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';

class _MockApi extends Mock implements StorytellerRepository {}

class _MockLocal extends Mock implements LocalStorytellerRepository {}

class _FakeSyncNotifier extends SyncNotifier {
  _FakeSyncNotifier({required this.initialOnline});

  final bool initialOnline;

  @override
  SyncState build() => SyncState(isOnline: initialOnline);

  void setOnline(bool online) {
    state = state.copyWith(isOnline: online);
  }
}

Storyteller _makeStoryteller(String id, String name) => Storyteller(
  id: id,
  projectId: 'proj-1',
  name: name,
  sex: StorytellerSex.female,
  age: 40,
  location: null,
  dialect: null,
  externalAcceptanceConfirmed: true,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  late _MockApi api;
  late _MockLocal local;

  ProviderContainer makeContainer({required bool online}) => ProviderContainer(
    overrides: [
      storytellerApiRepositoryProvider.overrideWithValue(api),
      localStorytellerRepositoryProvider.overrideWithValue(local),
      syncNotifierProvider.overrideWith(
        () => _FakeSyncNotifier(initialOnline: online),
      ),
    ],
  );

  setUp(() {
    api = _MockApi();
    local = _MockLocal();
  });

  group('ProjectStorytellersNotifier.fetch — offline behavior', () {
    test(
      'offline with cached storytellers paints cache, no API call, not loading',
      () async {
        final cached = [
          _makeStoryteller('s1', 'Alice'),
          _makeStoryteller('s2', 'Bob'),
        ];
        when(
          () => local.getByProject('proj-1'),
        ).thenAnswer((_) async => cached);

        final container = makeContainer(online: false);
        addTearDown(container.dispose);

        await container
            .read(projectStorytellersNotifierProvider.notifier)
            .fetch('proj-1');

        final state = container.read(projectStorytellersNotifierProvider);
        expect(state.storytellers.map((s) => s.id), ['s1', 's2']);
        expect(state.isLoading, isFalse);
        verifyNever(() => api.listByProject(any()));
      },
    );

    test(
      'offline with empty cache ends with empty list, no API call, not loading',
      () async {
        when(() => local.getByProject('proj-1')).thenAnswer((_) async => []);

        final container = makeContainer(online: false);
        addTearDown(container.dispose);

        await container
            .read(projectStorytellersNotifierProvider.notifier)
            .fetch('proj-1');

        final state = container.read(projectStorytellersNotifierProvider);
        expect(state.storytellers, isEmpty);
        expect(state.isLoading, isFalse);
        verifyNever(() => api.listByProject(any()));
      },
    );
  });

  group('ProjectStorytellersNotifier.fetch — online behavior', () {
    test('online fetches from API, persists, and ends with API list', () async {
      when(() => local.getByProject('proj-1')).thenAnswer((_) async => []);
      final fromApi = [
        _makeStoryteller('s1', 'Alice'),
        _makeStoryteller('s2', 'Bob'),
        _makeStoryteller('s3', 'Carol'),
      ];
      when(() => api.listByProject('proj-1')).thenAnswer((_) async => fromApi);
      when(() => local.upsertAll(any(), any())).thenAnswer((_) async {});

      final container = makeContainer(online: true);
      addTearDown(container.dispose);

      await container
          .read(projectStorytellersNotifierProvider.notifier)
          .fetch('proj-1');

      final state = container.read(projectStorytellersNotifierProvider);
      expect(state.storytellers.map((s) => s.id), ['s1', 's2', 's3']);
      expect(state.isLoading, isFalse);
      verify(() => api.listByProject('proj-1')).called(1);
    });
  });

  group('ProjectStorytellersNotifier.fetch — concurrent call dedupe', () {
    test(
      'two simultaneous fetch() calls for the same projectId only hit the API once',
      () async {
        when(() => local.getByProject('proj-1')).thenAnswer((_) async => []);
        when(() => api.listByProject('proj-1')).thenAnswer(
          (_) async => [_makeStoryteller('s1', 'Alice')],
        );
        when(() => local.upsertAll(any(), any())).thenAnswer((_) async {});

        final container = makeContainer(online: true);
        addTearDown(container.dispose);
        final notifier = container.read(
          projectStorytellersNotifierProvider.notifier,
        );

        // Fire both calls without awaiting between them — mirrors what happens
        // when StorytellersListScreen + StorytellerPicker both fire their
        // reconnect listeners on the same connectivity flip.
        await Future.wait([
          notifier.fetch('proj-1'),
          notifier.fetch('proj-1'),
        ]);

        verify(() => api.listByProject('proj-1')).called(1);
      },
    );

    test(
      'sequential fetch() calls (one completes before the next starts) both run',
      () async {
        when(() => local.getByProject('proj-1')).thenAnswer((_) async => []);
        when(() => api.listByProject('proj-1')).thenAnswer(
          (_) async => [_makeStoryteller('s1', 'Alice')],
        );
        when(() => local.upsertAll(any(), any())).thenAnswer((_) async {});

        final container = makeContainer(online: true);
        addTearDown(container.dispose);
        final notifier = container.read(
          projectStorytellersNotifierProvider.notifier,
        );

        // First fetch resolves before the second starts → second is NOT deduped.
        // This guards against the dedupe being too sticky and breaking
        // legitimate pull-to-refresh / reconnection retries.
        await notifier.fetch('proj-1');
        await notifier.fetch('proj-1');

        verify(() => api.listByProject('proj-1')).called(2);
      },
    );
  });

  group('ProjectStorytellersNotifier.fetch — offline → online transition', () {
    test(
      'first fetch offline short-circuits; second fetch (post-flip) hits the API',
      () async {
        when(() => local.getByProject('proj-1')).thenAnswer((_) async => []);
        when(() => api.listByProject('proj-1')).thenAnswer(
          (_) async => [_makeStoryteller('s1', 'Alice')],
        );
        when(() => local.upsertAll(any(), any())).thenAnswer((_) async {});

        final fakeSync = _FakeSyncNotifier(initialOnline: false);
        final container = ProviderContainer(
          overrides: [
            storytellerApiRepositoryProvider.overrideWithValue(api),
            localStorytellerRepositoryProvider.overrideWithValue(local),
            syncNotifierProvider.overrideWith(() => fakeSync),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(
          projectStorytellersNotifierProvider.notifier,
        );

        // Offline: no API call.
        await notifier.fetch('proj-1');
        verifyNever(() => api.listByProject(any()));

        // Flip online and re-invoke (mirrors the screen's reconnect listener).
        fakeSync.setOnline(true);
        await notifier.fetch('proj-1');

        verify(() => api.listByProject('proj-1')).called(1);
        final state = container.read(projectStorytellersNotifierProvider);
        expect(state.storytellers.map((s) => s.id), ['s1']);
      },
    );
  });
}
