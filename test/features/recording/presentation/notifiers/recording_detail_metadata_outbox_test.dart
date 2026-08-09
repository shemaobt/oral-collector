/// ENG-403: an edit the server never saw has to be remembered as owed.
///
/// ENG-399 stopped these mutations from throwing the edit away — the local row
/// now keeps it — but nothing recorded that the server was still owed it, so it
/// never went anywhere. Each mutation must name exactly the fields it touched:
/// the drain rebuilds the PATCH from that set, and a field this device did not
/// edit must never ride along and overwrite another device's copy of it.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/database/database_provider.dart';
import 'package:oral_collector/core/errors/api_exception.dart';
import 'package:oral_collector/features/auth/data/providers/role_provider.dart';
import 'package:oral_collector/features/project/presentation/notifiers/member_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/member_state.dart';
import 'package:oral_collector/features/project/presentation/notifiers/stats_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/stats_state.dart';
import 'package:oral_collector/features/recording/data/local_recording_to_entity.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/domain/entities/pending_metadata_field.dart';
import 'package:oral_collector/features/recording/domain/entities/review_flag.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/domain/entities/update_recording_request.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_detail_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recordings_list_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recordings_list_state.dart';
import 'package:oral_collector/features/recording/presentation/widgets/classify_recording_dialog.dart';
import 'package:oral_collector/features/recording/presentation/widgets/move_category_dialog.dart';
import 'package:oral_collector/features/recording/presentation/widgets/secondary_classification_fields.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';

const recordingId = 'rec-1';

class _FakeApiRepo implements RecordingApiRepository {
  _FakeApiRepo({this.updateError});

  final Object? updateError;
  int updateCalls = 0;

  @override
  Future<UpdateRecordingOutcome> updateRecording(
    String serverId,
    UpdateRecordingRequest request,
  ) async {
    updateCalls++;
    if (updateError != null) throw updateError!;
    return (success: true, reviewFlags: null);
  }

  @override
  Future<ServerRecording> getRecording(String serverId) async =>
      throw StateError('getRecording not expected');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected');
}

class _SyncNotifier extends SyncNotifier {
  _SyncNotifier(this._online);
  final bool _online;

  @override
  SyncState build() => SyncState(isOnline: _online);
  @override
  Future<void> processQueue() async {}
  @override
  Future<void> resetAndRetry(String id) async {}
}

class _FakeMemberNotifier extends MemberNotifier {
  @override
  MemberState build() => const MemberState();
  @override
  Future<void> fetchMembers(String projectId) async {}
}

class _FakeRoleNotifier extends RoleNotifier {
  @override
  RoleState build() => const RoleState();
  @override
  Future<void> fetchRoleForProject(String projectId) async {}
}

class _FakeStatsNotifier extends StatsNotifier {
  @override
  StatsState build() => const StatsState();
  @override
  Future<void> fetchGenreStats(String projectId) async {}
}

class _FakeListNotifier extends RecordingsListNotifier {
  @override
  RecordingsListState build() => const RecordingsListState();
  @override
  void patchRecordingTitle(String recordingId, String title) {}
}

void main() {
  late AppDatabase db;
  late LocalRecordingRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);
  });
  tearDown(() => db.close());

  Future<LocalRecordingEntity> seed({
    String? serverId = 'srv-1',
    String uploadStatus = 'verified',
    String cleaningStatus = 'none',
    String? secondaryGenreId,
    String? secondaryRegisterId,
  }) async {
    await repo.insertRecording(
      LocalRecordingsCompanion(
        id: const Value(recordingId),
        projectId: const Value('proj'),
        genreId: const Value('genre-1'),
        subcategoryId: const Value('sub-1'),
        registerId: const Value('reg-1'),
        secondaryGenreId: Value(secondaryGenreId),
        secondaryRegisterId: Value(secondaryRegisterId),
        serverId: Value(serverId),
        title: const Value('Story'),
        description: const Value('initial'),
        durationSeconds: const Value(30),
        fileSizeBytes: const Value(1000),
        localFilePath: const Value('/audio/in.m4a'),
        uploadStatus: Value(uploadStatus),
        cleaningStatus: Value(cleaningStatus),
        recordedAt: Value(DateTime.utc(2026, 5, 1)),
        reviewFlagsJson: Value(encodeReviewFlags(const [])),
      ),
    );
    return localRecordingToEntity((await repo.getRecordingById(recordingId))!);
  }

  ProviderContainer makeContainer({bool isOnline = false, _FakeApiRepo? api}) {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        localRecordingRepositoryProvider.overrideWithValue(repo),
        localRecordingStreamProvider(
          recordingId,
        ).overrideWith((ref) => const Stream<LocalRecordingEntity?>.empty()),
        recordingApiRepositoryProvider.overrideWithValue(api ?? _FakeApiRepo()),
        syncNotifierProvider.overrideWith(() => _SyncNotifier(isOnline)),
        memberNotifierProvider.overrideWith(_FakeMemberNotifier.new),
        roleNotifierProvider.overrideWith(_FakeRoleNotifier.new),
        statsNotifierProvider.overrideWith(_FakeStatsNotifier.new),
        recordingsListNotifierProvider.overrideWith(_FakeListNotifier.new),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  RecordingDetailNotifier notifierOf(ProviderContainer c) =>
      c.read(recordingDetailProvider(recordingId).notifier);

  Future<Set<PendingMetadataField>> owed() async => decodePendingMetadataFields(
    (await repo.getRecordingById(recordingId))!.pendingMetadataJson,
  );

  Future<String> outboxStatus() async =>
      (await repo.getRecordingById(recordingId))!.metadataSyncStatus;

  group('an edit the server never saw becomes owed', () {
    test('toggleCleaningStatus owes the cleaning status alone', () async {
      final recording = await seed();
      final c = makeContainer();

      await notifierOf(c).toggleCleaningStatus(recording);

      expect(await owed(), {PendingMetadataField.cleaningStatus});
      expect(await outboxStatus(), MetadataSyncStatus.pending);
    });

    test('moveCategory owes the category it moved', () async {
      final recording = await seed();
      final c = makeContainer();

      await notifierOf(c).moveCategory(
        recording,
        const MoveCategoryResult(genreId: 'genre-2', subcategoryId: 'sub-2'),
      );

      expect(await owed(), {
        PendingMetadataField.genre,
        PendingMetadataField.subcategory,
        PendingMetadataField.secondary,
      });
    });

    test('classify owes the whole classification it wrote', () async {
      final recording = await seed();
      final c = makeContainer();

      await notifierOf(c).classify(
        recording,
        const ClassifyResult(
          genreId: 'genre-2',
          subcategoryId: 'sub-2',
          registerId: 'reg-2',
        ),
      );

      expect(await owed(), {
        PendingMetadataField.genre,
        PendingMetadataField.subcategory,
        PendingMetadataField.register,
        PendingMetadataField.secondary,
      });
    });

    test('saveSecondary owes the secondary classification alone', () async {
      final recording = await seed();
      final c = makeContainer();

      await notifierOf(c).saveSecondary(
        recording,
        const SecondaryValues(genreId: 'genre-3', registerId: 'reg-3'),
      );

      expect(await owed(), {PendingMetadataField.secondary});
    });

    test('saveDetails owes only the half that changed', () async {
      final recording = await seed();
      final c = makeContainer();

      await notifierOf(
        c,
      ).saveDetails(recording, title: 'A New Title', description: 'initial');

      // The description was not edited, so the drain must not send it — and it
      // must not send the title's old value either.
      expect(await owed(), {PendingMetadataField.title});
    });

    test('saveDetails owes both halves when both changed', () async {
      final recording = await seed();
      final c = makeContainer();

      await notifierOf(
        c,
      ).saveDetails(recording, title: 'A New Title', description: 'a new note');

      expect(await owed(), {
        PendingMetadataField.title,
        PendingMetadataField.description,
      });
    });

    test('two offline edits to the same field collapse into one', () async {
      final recording = await seed();
      final c = makeContainer();

      await notifierOf(c).toggleCleaningStatus(recording);
      final second = localRecordingToEntity(
        (await repo.getRecordingById(recordingId))!,
      );
      await notifierOf(c).toggleCleaningStatus(second);

      // Storing the field rather than the payload is what makes this one entry
      // holding the latest value, instead of two writes to replay in order.
      expect(await owed(), {PendingMetadataField.cleaningStatus});
      expect(
        (await repo.getRecordingById(recordingId))!.cleaningStatus,
        'none',
      );
    });
  });

  group('an edit the server took is not owed', () {
    test('a successful write leaves nothing pending', () async {
      final recording = await seed();
      final api = _FakeApiRepo();
      final c = makeContainer(isOnline: true, api: api);

      await notifierOf(c).toggleCleaningStatus(recording);

      expect(api.updateCalls, 1);
      expect(await owed(), isEmpty);
      expect(await outboxStatus(), MetadataSyncStatus.synced);
    });

    test('a later accepted write clears an earlier owed field', () async {
      // Otherwise the row keeps advertising a pending edit the server already
      // has, and the drain re-sends a value nobody changed.
      final offline = await seed();
      final c = makeContainer();
      await notifierOf(c).toggleCleaningStatus(offline);
      expect(await owed(), isNotEmpty);

      final online = makeContainer(isOnline: true, api: _FakeApiRepo());
      final current = localRecordingToEntity(
        (await repo.getRecordingById(recordingId))!,
      );
      await notifierOf(online).toggleCleaningStatus(current);

      expect(await owed(), isEmpty);
    });

    test('a refusal owes nothing, because nothing was written', () async {
      final recording = await seed();
      final api = _FakeApiRepo(updateError: const ForbiddenException());
      final c = makeContainer(isOnline: true, api: api);

      final result = await notifierOf(c).toggleCleaningStatus(recording);

      expect(result, RecordingMutationResult.forbidden);
      expect(await owed(), isEmpty);
      expect(await outboxStatus(), MetadataSyncStatus.synced);
    });

    test('a recording the server has never seen owes it nothing', () async {
      // Its metadata rides along on the upload's create call; queueing a PATCH
      // for an id the server does not have would only fail.
      final recording = await seed(serverId: null, uploadStatus: 'local');
      final c = makeContainer();

      await notifierOf(c).classify(
        recording,
        const ClassifyResult(genreId: 'genre-2', subcategoryId: 'sub-2'),
      );

      expect(await owed(), isEmpty);
      expect(await outboxStatus(), MetadataSyncStatus.synced);
    });

    test('nor does moveCategory, which asks the server regardless', () async {
      // moveCategory pushes without checking for a serverId, so it is the one
      // mutation that can report "unreachable" for a recording the server was
      // never going to have. The drain skips such a row, so marking it pending
      // would leave a badge that nothing can ever clear.
      final recording = await seed(serverId: null, uploadStatus: 'local');
      final c = makeContainer();

      await notifierOf(c).moveCategory(
        recording,
        const MoveCategoryResult(genreId: 'genre-2', subcategoryId: 'sub-2'),
      );

      expect(await owed(), isEmpty);
      expect(await outboxStatus(), MetadataSyncStatus.synced);
    });
  });
}
