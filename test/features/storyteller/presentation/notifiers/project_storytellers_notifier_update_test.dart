import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/storyteller/data/providers.dart';
import 'package:oral_collector/features/storyteller/data/repositories/local_storyteller_repository.dart';
import 'package:oral_collector/features/storyteller/domain/entities/storyteller.dart';
import 'package:oral_collector/features/storyteller/domain/repositories/storyteller_repository.dart';
import 'package:oral_collector/features/storyteller/presentation/notifiers/project_storytellers_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';

class _MockApi extends Mock implements StorytellerRepository {}

class _FakeSyncNotifier extends SyncNotifier {
  @override
  SyncState build() => const SyncState(isOnline: false);

  void comeOnline() {
    state = state.copyWith(isOnline: true);
  }
}

const temporaryId = 'stl_1795065034097_b202a0';
const leilaniServerId = '4c038139-9d2e-4f6a-b1c4-7e2f0a9d3b51';
const kekoaId = '9a1e5b7c-3d2f-4e8a-b6c0-1f4d7e2a9c35';

Storyteller storyteller(String id, String name) => Storyteller(
  id: id,
  projectId: 'proj-1',
  name: name,
  sex: StorytellerSex.female,
  age: 41,
  externalAcceptanceConfirmed: true,
  createdAt: DateTime(2026, 11, 18),
);

void main() {
  late AppDatabase db;
  late LocalStorytellerRepository storytellers;
  late _MockApi api;
  late _FakeSyncNotifier sync;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    storytellers = LocalStorytellerRepository(db);
    api = _MockApi();
    sync = _FakeSyncNotifier();
    container = ProviderContainer(
      overrides: [
        storytellerApiRepositoryProvider.overrideWithValue(api),
        localStorytellerRepositoryProvider.overrideWithValue(storytellers),
        syncNotifierProvider.overrideWith(() => sync),
      ],
    );

    await storytellers.upsertAll([
      storyteller(kekoaId, 'Kekoa Alapai'),
    ], 'proj-1');
    await storytellers.insertLocal(storyteller(temporaryId, 'Leilani Kahale'));
    await storytellers.markUploaded(temporaryId, leilaniServerId);

    when(
      () => api.update(
        kekoaId,
        name: any(named: 'name'),
        sex: any(named: 'sex'),
        age: any(named: 'age'),
        location: any(named: 'location'),
        dialect: any(named: 'dialect'),
      ),
    ).thenAnswer((_) async => storyteller(kekoaId, 'Kekoa Alapai Jr.'));
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> editKekoaAfterTheListFailedToRefresh() async {
    final notifier = container.read(
      projectStorytellersNotifierProvider.notifier,
    );
    await notifier.fetch('proj-1');
    sync.comeOnline();
    await notifier.update(kekoaId, name: 'Kekoa Alapai Jr.');
  }

  test(
    'editing one storyteller leaves a phone-created storyteller that already '
    'uploaded with its server id',
    () async {
      await editKekoaAfterTheListFailedToRefresh();

      final row = await storytellers.getRowById(temporaryId);
      expect(
        row?.serverId,
        leilaniServerId,
        reason:
            'the edit rewrote the whole table from memory and dropped the '
            'server id of the storyteller it did not touch',
      );
      final edited = await storytellers.getById(kekoaId);
      expect(edited?.name, 'Kekoa Alapai Jr.');
    },
  );

  test('a recording of that storyteller still shows its name after the edit, '
      'with no refresh in between', () async {
    final recordings = LocalRecordingRepository(db);
    await recordings.insertRecording(
      LocalRecordingsCompanion(
        id: const Value('ruth-1-4'),
        projectId: const Value('proj-1'),
        genreId: const Value('g-1'),
        title: const Value('Ruth: the sons marry'),
        durationSeconds: const Value(10.9),
        fileSizeBytes: const Value(2048),
        format: const Value('m4a'),
        localFilePath: const Value('/recordings/ruth-1-4.m4a'),
        storytellerId: const Value(temporaryId),
        recordedAt: Value(DateTime(2026, 11, 18)),
      ),
    );

    await editKekoaAfterTheListFailedToRefresh();

    final recording = await recordings.getRecordingById('ruth-1-4');
    final shown = await storytellers.getById(recording!.storytellerId!);
    expect(
      shown?.name,
      'Leilani Kahale',
      reason: 'the card read «Unknown storyteller» until the next refresh',
    );
  });

  test('a storyteller created on the phone and not yet uploaded still waits '
      'to upload after another storyteller is edited', () async {
    const notYetUploaded = 'stl_1795068811512_4e91c7';
    await storytellers.insertLocal(
      storyteller(notYetUploaded, 'Malia Keawe'),
      syncStatus: 'local',
    );

    await editKekoaAfterTheListFailedToRefresh();

    final waiting = await storytellers.getPendingSyncs();
    expect(
      waiting.map((s) => s.id),
      [notYetUploaded],
      reason:
          'the edit wrote it back as synced, so it never reached the server',
    );
  });
}
