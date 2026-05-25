import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/database/database_provider.dart';
import 'package:oral_collector/features/storyteller/data/providers.dart';
import 'package:oral_collector/features/storyteller/domain/entities/storyteller.dart';
import 'package:oral_collector/features/storyteller/domain/repositories/storyteller_repository.dart';
import 'package:oral_collector/features/storyteller/presentation/notifiers/project_storytellers_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';

class MockStorytellerApi extends Mock implements StorytellerRepository {}

class _FakeSyncNotifier extends SyncNotifier {
  _FakeSyncNotifier({required this.initialOnline});

  final bool initialOnline;

  @override
  SyncState build() => SyncState(isOnline: initialOnline);
}

void main() {
  late AppDatabase db;
  late MockStorytellerApi mockApi;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(StorytellerSex.male);
  });

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mockApi = MockStorytellerApi();

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        storytellerApiRepositoryProvider.overrideWithValue(mockApi),
        syncNotifierProvider.overrideWith(
          () => _FakeSyncNotifier(initialOnline: true),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('create offline (local-first)', () {
    test(
      'create() inserts storyteller locally without calling the API',
      () async {
        final notifier = container.read(
          projectStorytellersNotifierProvider.notifier,
        );

        final created = await notifier.create(
          projectId: 'proj-1',
          name: 'Maria',
          sex: StorytellerSex.female,
          age: 42,
          location: 'Aracaju',
          dialect: 'Nordestino',
          externalAcceptanceConfirmed: true,
        );

        expect(created, isNotNull);
        expect(created!.name, 'Maria');
        expect(created.projectId, 'proj-1');
        expect(created.sex, StorytellerSex.female);
        verifyNever(
          () => mockApi.create(
            projectId: any(named: 'projectId'),
            name: any(named: 'name'),
            sex: any(named: 'sex'),
            age: any(named: 'age'),
            location: any(named: 'location'),
            dialect: any(named: 'dialect'),
            externalAcceptanceConfirmed: any(
              named: 'externalAcceptanceConfirmed',
            ),
          ),
        );
      },
    );

    test('created storyteller appears in notifier state immediately', () async {
      final notifier = container.read(
        projectStorytellersNotifierProvider.notifier,
      );

      await notifier.create(
        projectId: 'proj-1',
        name: 'Carlos',
        sex: StorytellerSex.male,
        externalAcceptanceConfirmed: true,
      );

      final state = container.read(projectStorytellersNotifierProvider);
      expect(state.storytellers.length, 1);
      expect(state.storytellers.single.name, 'Carlos');
    });

    test('created storyteller is persisted in local DB as pending', () async {
      final notifier = container.read(
        projectStorytellersNotifierProvider.notifier,
      );

      await notifier.create(
        projectId: 'proj-1',
        name: 'Ana',
        sex: StorytellerSex.female,
        externalAcceptanceConfirmed: true,
      );

      final repo = container.read(localStorytellerRepositoryProvider);
      final pending = await repo.getPendingSyncs();
      expect(pending.length, 1);
      expect(pending.single.name, 'Ana');
      expect(pending.single.syncStatus, 'local');
    });

    test(
      'after re-creating the notifier, pending storytellers are visible via fetch',
      () async {
        final notifier = container.read(
          projectStorytellersNotifierProvider.notifier,
        );
        await notifier.create(
          projectId: 'proj-1',
          name: 'Persistente',
          sex: StorytellerSex.female,
          externalAcceptanceConfirmed: true,
        );

        container.invalidate(projectStorytellersNotifierProvider);

        when(
          () => mockApi.listByProject('proj-1'),
        ).thenAnswer((_) async => <Storyteller>[]);

        final fresh = container.read(
          projectStorytellersNotifierProvider.notifier,
        );
        await fresh.fetch('proj-1');

        final state = container.read(projectStorytellersNotifierProvider);
        expect(
          state.storytellers.any((s) => s.name == 'Persistente'),
          isTrue,
          reason:
              'pending storytellers persisted to DB must survive notifier rebuild',
        );
      },
    );
  });

  group('delete (local-pending vs synced)', () {
    test(
      'delete on a local-pending storyteller removes it locally without hitting the API',
      () async {
        final notifier = container.read(
          projectStorytellersNotifierProvider.notifier,
        );
        final created = await notifier.create(
          projectId: 'proj-1',
          name: 'Pending Delete',
          sex: StorytellerSex.male,
          externalAcceptanceConfirmed: true,
        );

        final ok = await notifier.delete(created!.id);

        expect(ok, isTrue);
        verifyNever(() => mockApi.delete(any()));

        final state = container.read(projectStorytellersNotifierProvider);
        expect(state.storytellers.any((s) => s.id == created.id), isFalse);

        final repo = container.read(localStorytellerRepositoryProvider);
        final remaining = await repo.getByProject('proj-1');
        expect(remaining.any((s) => s.id == created.id), isFalse);
      },
    );
  });
}
