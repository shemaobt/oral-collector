/// Unit tests for RecordingDetailNotifier (ENG-194): the load + mutation + IO
/// orchestration extracted from recording_detail_screen. Drives the notifier
/// through a ProviderContainer with a real in-memory Drift repo and the platform
/// IO seams faked, so the behaviour the screen used to do inline is pinned
/// without a device — including the Companion null semantics the typed repo
/// writes must preserve.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/database/database_provider.dart';
import 'package:oral_collector/core/errors/api_exception.dart';
import 'package:oral_collector/core/errors/app_exception.dart'
    show ConflictException;
import 'package:oral_collector/features/auth/data/providers/role_provider.dart';
import 'package:oral_collector/features/project/presentation/notifiers/member_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/member_state.dart';
import 'package:oral_collector/features/project/presentation/notifiers/stats_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/stats_state.dart';
import 'package:oral_collector/features/recording/data/local_recording_to_entity.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/data/services/audio_downloader.dart';
import 'package:oral_collector/features/recording/data/services/recording_file_importer.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/domain/entities/review_flag.dart';
import 'package:oral_collector/features/recording/domain/entities/review_pendency.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/domain/entities/update_recording_request.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_detail_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_detail_state.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recordings_list_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recordings_list_state.dart';
import 'package:oral_collector/features/recording/presentation/widgets/classify_recording_dialog.dart';
import 'package:oral_collector/features/recording/presentation/widgets/move_category_dialog.dart';
import 'package:oral_collector/features/recording/presentation/widgets/secondary_classification_fields.dart';
import 'package:oral_collector/features/storyteller/domain/entities/storyteller.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';

const recordingId = 'rec-1';

class _FakeApiRepo implements RecordingApiRepository {
  _FakeApiRepo({
    this.updateResult = true,
    this.updateError,
    this.getRecordingResult,
    this.updateReviewFlags,
  });

  bool updateResult;
  List<ReviewFlag>? updateReviewFlags;
  Object? updateError;
  ServerRecording? getRecordingResult;

  int updateCalls = 0;
  int getRecordingCalls = 0;
  String? lastServerId;
  String? lastGetServerId;
  Map<String, Object?> lastUpdate = const {};

  @override
  Future<UpdateRecordingOutcome> updateRecording(
    String serverId,
    UpdateRecordingRequest request,
  ) async {
    updateCalls++;
    lastServerId = serverId;
    lastUpdate = {
      'title': request.title,
      'description': request.description,
      'genreId': request.genreId,
      'subcategoryId': request.subcategoryId,
      'registerId': request.registerId,
      'secondaryGenreId': request.secondaryGenreId,
      'secondarySubcategoryId': request.secondarySubcategoryId,
      'secondaryRegisterId': request.secondaryRegisterId,
      'clearSecondary': request.clearSecondary,
      'storytellerId': request.storytellerId,
      'cleaningStatus': request.cleaningStatus,
      'durationSeconds': request.durationSeconds,
      'fileSizeBytes': request.fileSizeBytes,
    };
    if (updateError != null) throw updateError!;
    return (success: updateResult, reviewFlags: updateReviewFlags);
  }

  @override
  Future<ServerRecording> getRecording(String serverId) async {
    getRecordingCalls++;
    lastGetServerId = serverId;
    final result = getRecordingResult;
    if (result == null) throw StateError('getRecording not expected');
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected');
}

class _SyncSpy {
  int processQueueCalls = 0;
  int resetAndRetryCalls = 0;
}

class _SyncNotifier extends SyncNotifier {
  _SyncNotifier(this._online, this._spy);
  final bool _online;
  final _SyncSpy _spy;

  @override
  SyncState build() => SyncState(isOnline: _online);
  @override
  Future<void> processQueue() async => _spy.processQueueCalls++;
  @override
  Future<void> resetAndRetry(String id) async {
    _spy.resetAndRetryCalls++;
    // Mirrors the real notifier's first step so the row's queue state is
    // observable in the DB instead of only in the spy counter.
    await ref.read(localRecordingRepositoryProvider).resetRetryCount(id);
  }
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

class _ListSpy {
  String? patchedTitle;
}

class _FakeListNotifier extends RecordingsListNotifier {
  _FakeListNotifier(this._spy);
  final _ListSpy _spy;
  @override
  RecordingsListState build() => const RecordingsListState();
  @override
  void patchRecordingTitle(String recordingId, String title) {
    _spy.patchedTitle = title;
  }
}

class _CacheDownloaderSpy {
  _CacheDownloaderSpy({this.path = '/cache/dl.m4a', this.error});
  final String path;
  final Object? error;
  int calls = 0;
  String? lastUrl;

  Future<String> call({required String url, required String format}) async {
    calls++;
    lastUrl = url;
    if (error != null) throw error!;
    return path;
  }
}

class _ExportDownloaderSpy {
  int calls = 0;
  String? lastUrl;
  Future<String> call({
    required String url,
    required String recordingId,
    required String format,
  }) async {
    calls++;
    lastUrl = url;
    return '/tmp/export.m4a';
  }
}

class _ImporterSpy {
  _ImporterSpy({this.path = '/recordings/new.m4a', this.sizeBytes = 4242});
  final String path;
  final int sizeBytes;
  int calls = 0;
  String? lastSourcePath;
  String? lastOldPath;

  Future<({String path, int sizeBytes})> call({
    required String sourcePath,
    required String fileName,
    required String? oldPath,
    required String recordingId,
    required String format,
  }) async {
    calls++;
    lastSourcePath = sourcePath;
    lastOldPath = oldPath;
    return (path: path, sizeBytes: sizeBytes);
  }
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
    String genreId = 'genre-1',
    String? subcategoryId = 'sub-1',
    String? registerId = 'reg-1',
    String? secondaryGenreId,
    String? secondaryRegisterId,
    String? storytellerId,
    String? serverId,
    String? userId = 'u1',
    String uploadStatus = 'local',
    String cleaningStatus = 'none',
    String description = 'initial',
    String localFilePath = '/audio/in.m4a',
    String? gcsUrl = 'https://gcs/in.m4a',
    List<ReviewFlag> reviewFlags = const [],
  }) async {
    await repo.insertRecording(
      LocalRecordingsCompanion(
        id: const Value(recordingId),
        projectId: const Value('proj'),
        genreId: Value(genreId),
        subcategoryId: Value(subcategoryId),
        registerId: Value(registerId),
        secondaryGenreId: Value(secondaryGenreId),
        secondaryRegisterId: Value(secondaryRegisterId),
        storytellerId: Value(storytellerId),
        userId: Value(userId),
        serverId: Value(serverId),
        title: const Value('Story'),
        description: Value(description),
        durationSeconds: const Value(30),
        fileSizeBytes: const Value(1000),
        format: const Value('m4a'),
        localFilePath: Value(localFilePath),
        gcsUrl: Value(gcsUrl),
        uploadStatus: Value(uploadStatus),
        cleaningStatus: Value(cleaningStatus),
        recordedAt: Value(DateTime.utc(2026, 5, 1)),
        reviewFlagsJson: Value(encodeReviewFlags(reviewFlags)),
      ),
    );
    return localRecordingToEntity((await repo.getRecordingById(recordingId))!);
  }

  ProviderContainer makeContainer({
    bool isOnline = false,
    _FakeApiRepo? api,
    _SyncSpy? syncSpy,
    _ListSpy? listSpy,
    _CacheDownloaderSpy? cacheDownloader,
    _ExportDownloaderSpy? exportDownloader,
    _ImporterSpy? importer,
  }) {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        localRecordingRepositoryProvider.overrideWithValue(repo),
        // Avoid the Drift watch stream's pending Timer under flutter_test.
        localRecordingStreamProvider(
          recordingId,
        ).overrideWith((ref) => const Stream<LocalRecordingEntity?>.empty()),
        recordingApiRepositoryProvider.overrideWithValue(api ?? _FakeApiRepo()),
        syncNotifierProvider.overrideWith(
          () => _SyncNotifier(isOnline, syncSpy ?? _SyncSpy()),
        ),
        memberNotifierProvider.overrideWith(_FakeMemberNotifier.new),
        roleNotifierProvider.overrideWith(_FakeRoleNotifier.new),
        statsNotifierProvider.overrideWith(_FakeStatsNotifier.new),
        recordingsListNotifierProvider.overrideWith(
          () => _FakeListNotifier(listSpy ?? _ListSpy()),
        ),
        if (cacheDownloader != null)
          audioCacheDownloaderProvider.overrideWithValue(cacheDownloader.call),
        if (exportDownloader != null)
          audioExportDownloaderProvider.overrideWithValue(
            exportDownloader.call,
          ),
        if (importer != null)
          recordingFileImporterProvider.overrideWithValue(importer.call),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  RecordingDetailNotifier notifierOf(ProviderContainer c) =>
      c.read(recordingDetailProvider(recordingId).notifier);
  RecordingDetailState stateOf(ProviderContainer c) =>
      c.read(recordingDetailProvider(recordingId));

  group('load', () {
    test('resolves the local recording offline', () async {
      await seed();
      final c = makeContainer();
      await notifierOf(c).load();

      expect(stateOf(c).recording?.id, recordingId);
      expect(stateOf(c).isLoading, isFalse);
    });

    test('leaves recording null and stops loading when absent', () async {
      final c = makeContainer();
      await notifierOf(c).load();

      expect(stateOf(c).recording, isNull);
      expect(stateOf(c).isLoading, isFalse);
    });

    test(
      'heals the gcs url from the server when online and uploaded',
      () async {
        await seed(
          serverId: 'srv-1',
          gcsUrl: '',
          uploadStatus: 'uploaded',
          userId: 'u1',
        );
        final api = _FakeApiRepo(
          getRecordingResult: ServerRecording(
            id: 'srv-1',
            projectId: 'proj',
            genreId: 'genre-1',
            durationSeconds: 30,
            fileSizeBytes: 1000,
            format: 'm4a',
            gcsUrl: 'https://gcs/healed.m4a',
            uploadStatus: 'verified',
            cleaningStatus: 'none',
            userId: 'u1',
            recordedAt: DateTime.utc(2026, 5, 1),
          ),
        );
        final c = makeContainer(isOnline: true, api: api);

        await notifierOf(c).load();

        expect(api.getRecordingCalls, 1);
        expect(api.lastGetServerId, 'srv-1');
        final row = (await repo.getRecordingById(recordingId))!;
        expect(row.gcsUrl, 'https://gcs/healed.m4a');
        expect(row.uploadStatus, 'verified');
      },
    );

    test('does not call the server when local metadata is complete', () async {
      await seed(
        serverId: 'srv-1',
        gcsUrl: 'https://gcs/in.m4a',
        uploadStatus: 'uploaded',
        userId: 'u1',
      );
      final api = _FakeApiRepo();
      final c = makeContainer(isOnline: true, api: api);

      await notifierOf(c).load();

      expect(api.getRecordingCalls, 0);
      expect(
        (await repo.getRecordingById(recordingId))!.gcsUrl,
        'https://gcs/in.m4a',
      );
    });

    test(
      'does not heal while offline even if metadata is incomplete',
      () async {
        await seed(
          serverId: 'srv-1',
          gcsUrl: '',
          uploadStatus: 'uploaded',
          userId: 'u1',
        );
        final api = _FakeApiRepo();
        final c = makeContainer(api: api);

        await notifierOf(c).load();

        expect(api.getRecordingCalls, 0);
        expect((await repo.getRecordingById(recordingId))!.gcsUrl, '');
      },
    );
  });

  group('setStoryteller', () {
    test('writes the storyteller id and syncs the server', () async {
      final recording = await seed();
      final api = _FakeApiRepo();
      final c = makeContainer(api: api);

      await notifierOf(c).setStoryteller(
        recording,
        Storyteller(
          id: 'st-9',
          projectId: 'proj',
          name: 'Ana',
          sex: StorytellerSex.female,
          externalAcceptanceConfirmed: false,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      expect((await repo.getRecordingById(recordingId))!.storytellerId, 'st-9');
      expect(api.lastUpdate['storytellerId'], 'st-9');
    });

    test('clears the storyteller id when deselected', () async {
      final recording = await seed(storytellerId: 'st-1');
      final c = makeContainer();

      await notifierOf(c).setStoryteller(recording, null);

      expect((await repo.getRecordingById(recordingId))!.storytellerId, isNull);
    });
  });

  // ENG-379: the pendency rule reads the stored flags for any recording the
  // server knows about, so an edit that clears a pendency on the server has to
  // land in the row. Every one of these mutations already had the answer in the
  // response it threw away.
  group('review flags from the write response', () {
    Future<List<PendencyKind>> storedPendencies() async =>
        recordingPendencies((await repo.getRecordingEntityById(recordingId))!);

    test('assigning a storyteller stops the recording owing one', () async {
      final recording = await seed(
        serverId: 'srv-1',
        reviewFlags: const [
          ReviewFlag(code: 'missing_storyteller', origin: 'system'),
        ],
      );
      final c = makeContainer(api: _FakeApiRepo(updateReviewFlags: const []));

      await notifierOf(c).setStoryteller(
        recording,
        Storyteller(
          id: 'st-9',
          projectId: 'proj',
          name: 'Ana',
          sex: StorytellerSex.female,
          externalAcceptanceConfirmed: false,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      expect(await storedPendencies(), isEmpty);
    });

    test('classifying stops the recording owing a classification', () async {
      final recording = await seed(
        serverId: 'srv-1',
        reviewFlags: const [
          ReviewFlag(code: 'missing_classification', origin: 'system'),
        ],
      );
      final c = makeContainer(api: _FakeApiRepo(updateReviewFlags: const []));

      await notifierOf(c).classify(
        recording,
        const ClassifyResult(
          genreId: 'genre-2',
          subcategoryId: 'sub-2',
          registerId: 'reg-2',
        ),
      );

      expect(await storedPendencies(), isEmpty);
    });

    test('moving a recording to another category stops it owing one', () async {
      final recording = await seed(
        serverId: 'srv-1',
        reviewFlags: const [
          ReviewFlag(code: 'missing_classification', origin: 'system'),
        ],
      );
      final c = makeContainer(
        isOnline: true,
        api: _FakeApiRepo(updateReviewFlags: const []),
      );

      await notifierOf(c).moveCategory(
        recording,
        const MoveCategoryResult(genreId: 'genre-2', subcategoryId: 'sub-2'),
      );

      expect(await storedPendencies(), isEmpty);
    });

    test(
      'saving a secondary classification takes the flags that came back',
      () async {
        final recording = await seed(
          serverId: 'srv-1',
          reviewFlags: const [
            ReviewFlag(code: 'missing_classification', origin: 'system'),
          ],
        );
        final c = makeContainer(
          api: _FakeApiRepo(
            updateReviewFlags: const [
              ReviewFlag(code: 'missing_storyteller', origin: 'system'),
            ],
          ),
        );

        await notifierOf(c).saveSecondary(
          recording,
          const SecondaryValues(genreId: 'genre-3', registerId: 'reg-3'),
        );

        expect(await storedPendencies(), [PendencyKind.storyteller]);
      },
    );

    test('a server that says nothing about the flags leaves the stored ones '
        'alone', () async {
      final recording = await seed(
        serverId: 'srv-1',
        reviewFlags: const [
          ReviewFlag(code: 'missing_storyteller', origin: 'system'),
        ],
      );
      final c = makeContainer(api: _FakeApiRepo());

      await notifierOf(c).classify(
        recording,
        const ClassifyResult(genreId: 'genre-2', subcategoryId: 'sub-2'),
      );

      expect(await storedPendencies(), [PendencyKind.storyteller]);
    });
  });

  group('saveDetails', () {
    test(
      'updates only the description locally when title is unchanged',
      () async {
        final recording = await seed(description: 'old');
        final api = _FakeApiRepo();
        final c = makeContainer(api: api);

        await notifierOf(
          c,
        ).saveDetails(recording, title: 'Story', description: 'a fresh note');

        expect(
          (await repo.getRecordingById(recordingId))!.description,
          'a fresh note',
        );
        // Native description edit goes through the local repo, not the API.
        expect(api.updateCalls, 0);
      },
    );

    test('saves a changed title and patches the list cache', () async {
      final recording = await seed(); // title 'Story', description 'initial'
      final listSpy = _ListSpy();
      final c = makeContainer(listSpy: listSpy);

      await notifierOf(
        c,
      ).saveDetails(recording, title: 'A New Title', description: 'initial');

      expect((await repo.getRecordingById(recordingId))!.title, 'A New Title');
      expect(listSpy.patchedTitle, 'A New Title');
    });

    test(
      'renaming a title-conflict recording puts it back in the queue',
      () async {
        final recording = await seed(uploadStatus: 'failed_conflict');
        final c = makeContainer();

        await notifierOf(
          c,
        ).saveDetails(recording, title: 'A Free Name', description: 'initial');

        final row = (await repo.getRecordingById(recordingId))!;
        expect(row.title, 'A Free Name');
        expect(row.uploadStatus, 'local');
      },
    );

    test('a rename the server also rejects reports the clash and leaves the '
        'recording recoverable', () async {
      // Second conflict: the user renamed a name-clashed recording onto
      // another title that is already taken in the project.
      final recording = await seed(
        uploadStatus: 'failed_conflict',
        serverId: 'srv-1',
      );
      final api = _FakeApiRepo(updateError: const ConflictException());
      final c = makeContainer(isOnline: true, api: api);

      final outcome = await notifierOf(
        c,
      ).saveDetails(recording, title: 'Also Taken', description: 'initial');

      expect(outcome, RecordingMutationResult.titleConflict);
      final row = (await repo.getRecordingById(recordingId))!;
      // The local row must not claim a title the server refused...
      expect(row.title, 'Story');
      // ...and the recording stays conflicted, so the rename banner is still
      // there and the user can try another name.
      expect(row.uploadStatus, 'failed_conflict');
    });

    test(
      'lengthening the description of a blocked recording requeues it',
      () async {
        // A recording that predates the create-time description rule was parked
        // in failed_description by the upload pre-flight. Fixing the
        // description is the exit; it must not stay stuck.
        final recording = await seed(uploadStatus: 'failed_description');
        final c = makeContainer();

        await notifierOf(c).saveDetails(
          recording,
          title: 'Story',
          description: 'A description with enough substance to be accepted',
        );

        final row = (await repo.getRecordingById(recordingId))!;
        expect(
          row.description,
          'A description with enough substance to be accepted',
        );
        expect(row.uploadStatus, 'local');
      },
    );

    test(
      'lengthening the description of an uploaded recording leaves its upload '
      'state alone',
      () async {
        final recording = await seed(uploadStatus: 'uploaded');
        final c = makeContainer();

        await notifierOf(c).saveDetails(
          recording,
          title: 'Story',
          description: 'A description with enough substance to be accepted',
        );

        expect(
          (await repo.getRecordingById(recordingId))!.uploadStatus,
          'uploaded',
        );
      },
    );

    test(
      'renaming an uploaded recording leaves its upload state alone',
      () async {
        final recording = await seed(uploadStatus: 'uploaded');
        final c = makeContainer();

        await notifierOf(
          c,
        ).saveDetails(recording, title: 'A New Title', description: 'initial');

        expect(
          (await repo.getRecordingById(recordingId))!.uploadStatus,
          'uploaded',
        );
      },
    );
  });

  group('toggleCleaningStatus', () {
    test(
      'flips the status locally without an API call when not uploaded',
      () async {
        final recording = await seed(
          uploadStatus: 'local',
          cleaningStatus: 'none',
        );
        final api = _FakeApiRepo();
        final c = makeContainer(api: api);

        final result = await notifierOf(c).toggleCleaningStatus(recording);

        expect(result, RecordingMutationResult.success);
        expect(
          (await repo.getRecordingById(recordingId))!.cleaningStatus,
          'needs_cleaning',
        );
        expect(api.updateCalls, 0);
      },
    );

    test('calls the API when the recording was uploaded', () async {
      final recording = await seed(
        uploadStatus: 'uploaded',
        cleaningStatus: 'needs_cleaning',
        serverId: 'srv-1',
      );
      final api = _FakeApiRepo();
      final c = makeContainer(isOnline: true, api: api);

      await notifierOf(c).toggleCleaningStatus(recording);

      expect(api.lastUpdate['cleaningStatus'], 'none');
      expect(
        (await repo.getRecordingById(recordingId))!.cleaningStatus,
        'none',
      );
    });

    test('calls the API when the recording was verified', () async {
      final recording = await seed(
        uploadStatus: 'verified',
        cleaningStatus: 'none',
        serverId: 'srv-1',
      );
      final api = _FakeApiRepo();
      final c = makeContainer(isOnline: true, api: api);

      final result = await notifierOf(c).toggleCleaningStatus(recording);

      expect(result, RecordingMutationResult.success);
      expect(api.updateCalls, 1);
      expect(api.lastUpdate['cleaningStatus'], 'needs_cleaning');
      expect(
        (await repo.getRecordingById(recordingId))!.cleaningStatus,
        'needs_cleaning',
      );
    });

    // ENG-399: since ENG-376 counted `verified` as server-known, the common
    // recording takes the server path — so a plain network error used to throw
    // the edit away instead of keeping it.
    test(
      'keeps the edit on the device when the server is unreachable',
      () async {
        final recording = await seed(
          uploadStatus: 'verified',
          cleaningStatus: 'none',
          serverId: 'srv-1',
        );
        final api = _FakeApiRepo(updateError: Exception('connection failed'));
        final c = makeContainer(isOnline: true, api: api);

        final result = await notifierOf(c).toggleCleaningStatus(recording);

        expect(result, RecordingMutationResult.savedLocallyOnly);
        expect(
          (await repo.getRecordingById(recordingId))!.cleaningStatus,
          'needs_cleaning',
        );
      },
    );

    test('writes locally without trying the server while offline', () async {
      final recording = await seed(
        uploadStatus: 'verified',
        cleaningStatus: 'none',
        serverId: 'srv-1',
      );
      final api = _FakeApiRepo();
      final c = makeContainer(api: api);

      final result = await notifierOf(c).toggleCleaningStatus(recording);

      expect(result, RecordingMutationResult.savedLocallyOnly);
      expect(api.updateCalls, 0);
      expect(
        (await repo.getRecordingById(recordingId))!.cleaningStatus,
        'needs_cleaning',
      );
    });

    test('returns forbidden and leaves the row untouched on 403', () async {
      final recording = await seed(
        uploadStatus: 'verified',
        cleaningStatus: 'none',
        serverId: 'srv-1',
      );
      final api = _FakeApiRepo(updateError: const ForbiddenException());
      final c = makeContainer(isOnline: true, api: api);

      final result = await notifierOf(c).toggleCleaningStatus(recording);

      expect(result, RecordingMutationResult.forbidden);
      expect(
        (await repo.getRecordingById(recordingId))!.cleaningStatus,
        'none',
      );
    });
  });

  group('moveCategory', () {
    test(
      'updates the primary category and clears secondary on success',
      () async {
        final recording = await seed(secondaryGenreId: 'sg-old');
        final api = _FakeApiRepo();
        final c = makeContainer(isOnline: true, api: api);

        final result = await notifierOf(c).moveCategory(
          recording,
          const MoveCategoryResult(
            genreId: 'genre-2',
            subcategoryId: 'sub-2',
            clearSecondary: true,
          ),
        );

        expect(result, RecordingMutationResult.success);
        final row = (await repo.getRecordingById(recordingId))!;
        expect(row.genreId, 'genre-2');
        expect(row.secondaryGenreId, isNull);
        expect(api.lastUpdate['clearSecondary'], true);
      },
    );

    test('returns forbidden and leaves the row untouched on 403', () async {
      final recording = await seed(genreId: 'genre-1');
      final api = _FakeApiRepo(updateError: const ForbiddenException());
      final c = makeContainer(isOnline: true, api: api);

      final result = await notifierOf(c).moveCategory(
        recording,
        const MoveCategoryResult(
          genreId: 'genre-2',
          subcategoryId: 'sub-2',
          clearSecondary: false,
        ),
      );

      expect(result, RecordingMutationResult.forbidden);
      expect((await repo.getRecordingById(recordingId))!.genreId, 'genre-1');
    });

    test('returns failed when the API reports no success', () async {
      final recording = await seed();
      final api = _FakeApiRepo(updateResult: false);
      final c = makeContainer(isOnline: true, api: api);

      final result = await notifierOf(c).moveCategory(
        recording,
        const MoveCategoryResult(
          genreId: 'genre-2',
          subcategoryId: 'sub-2',
          clearSecondary: false,
        ),
      );

      expect(result, RecordingMutationResult.failed);
    });

    // ENG-399: same shape as toggleCleaningStatus — a network error used to
    // discard the move instead of keeping it on the device.
    test(
      'keeps the move on the device when the server is unreachable',
      () async {
        final recording = await seed(
          genreId: 'genre-1',
          uploadStatus: 'verified',
          serverId: 'srv-1',
        );
        final api = _FakeApiRepo(updateError: Exception('connection failed'));
        final c = makeContainer(isOnline: true, api: api);

        final result = await notifierOf(c).moveCategory(
          recording,
          const MoveCategoryResult(
            genreId: 'genre-2',
            subcategoryId: 'sub-2',
            clearSecondary: false,
          ),
        );

        expect(result, RecordingMutationResult.savedLocallyOnly);
        expect((await repo.getRecordingById(recordingId))!.genreId, 'genre-2');
      },
    );

    test('writes locally without trying the server while offline', () async {
      final recording = await seed(
        genreId: 'genre-1',
        uploadStatus: 'verified',
        serverId: 'srv-1',
      );
      final api = _FakeApiRepo();
      final c = makeContainer(api: api);

      final result = await notifierOf(c).moveCategory(
        recording,
        const MoveCategoryResult(
          genreId: 'genre-2',
          subcategoryId: 'sub-2',
          clearSecondary: false,
        ),
      );

      expect(result, RecordingMutationResult.savedLocallyOnly);
      expect(api.updateCalls, 0);
      expect((await repo.getRecordingById(recordingId))!.genreId, 'genre-2');
    });
  });

  group('classify', () {
    test('preserves the existing register when registerId is null', () async {
      // Unclassified-by-register seed; classifying without a register must NOT
      // wipe the stored one (Value.absent semantics through the typed write).
      final recording = await seed(registerId: 'reg-keep', serverId: 'srv-1');
      final c = makeContainer(api: _FakeApiRepo());

      await notifierOf(c).classify(
        recording,
        const ClassifyResult(genreId: 'genre-2', subcategoryId: 'sub-2'),
      );

      expect(
        (await repo.getRecordingById(recordingId))!.registerId,
        'reg-keep',
      );
    });

    test(
      'triggers the upload queue when offline-saved without a server id',
      () async {
        final recording = await seed(serverId: null);
        final spy = _SyncSpy();
        final c = makeContainer(isOnline: true, syncSpy: spy);

        await notifierOf(c).classify(
          recording,
          const ClassifyResult(genreId: 'genre-2', subcategoryId: 'sub-2'),
        );

        expect(spy.processQueueCalls, 1);
      },
    );

    test(
      'does not trigger the queue when the recording has a server id',
      () async {
        final recording = await seed(serverId: 'srv-1');
        final spy = _SyncSpy();
        final c = makeContainer(isOnline: true, syncSpy: spy);

        await notifierOf(c).classify(
          recording,
          const ClassifyResult(genreId: 'genre-2', subcategoryId: 'sub-2'),
        );

        expect(spy.processQueueCalls, 0);
      },
    );
  });

  group('saveSecondary', () {
    test('clears the secondary classification when values are null', () async {
      final recording = await seed(
        secondaryGenreId: 'sg-1',
        secondaryRegisterId: 'sr-1',
      );
      final c = makeContainer();

      await notifierOf(c).saveSecondary(recording, null);

      final row = (await repo.getRecordingById(recordingId))!;
      expect(row.secondaryGenreId, isNull);
      expect(row.secondaryRegisterId, isNull);
    });

    test(
      'writes the secondary classification when values are provided',
      () async {
        final recording = await seed();
        final c = makeContainer();

        await notifierOf(c).saveSecondary(
          recording,
          const SecondaryValues(genreId: 'sg-2', subcategoryId: 'ss-2'),
        );

        expect(
          (await repo.getRecordingById(recordingId))!.secondaryGenreId,
          'sg-2',
        );
      },
    );
  });

  group('downloadAndCache', () {
    test('caches the downloaded file path', () async {
      final recording = await seed(localFilePath: '');
      final dl = _CacheDownloaderSpy(path: '/cache/got.m4a');
      final c = makeContainer(cacheDownloader: dl);

      await notifierOf(c).downloadAndCache(recording);

      expect(dl.calls, 1);
      expect(
        (await repo.getRecordingById(recordingId))!.localFilePath,
        '/cache/got.m4a',
      );
    });

    test('rethrows and does not cache when the download fails', () async {
      final recording = await seed(localFilePath: '');
      final dl = _CacheDownloaderSpy(error: Exception('boom'));
      final c = makeContainer(cacheDownloader: dl);

      await expectLater(
        notifierOf(c).downloadAndCache(recording),
        throwsA(isA<Exception>()),
      );
      expect((await repo.getRecordingById(recordingId))!.localFilePath, '');
    });
  });

  group('downloadForExport', () {
    test('downloads from the gcs url and returns the temp path', () async {
      final recording = await seed(gcsUrl: 'https://gcs/export.m4a');
      final dl = _ExportDownloaderSpy();
      final c = makeContainer(exportDownloader: dl);

      final path = await notifierOf(c).downloadForExport(recording);

      expect(path, '/tmp/export.m4a');
      expect(dl.lastUrl, 'https://gcs/export.m4a');
    });
  });

  group('replaceAudio', () {
    test('imports the file and updates the row', () async {
      final recording = await seed(localFilePath: '/audio/old.m4a');
      final importer = _ImporterSpy(path: '/recordings/x.m4a', sizeBytes: 999);
      final c = makeContainer(importer: importer);

      final ok = await notifierOf(c).replaceAudio(
        recording,
        sourcePath: '/picked/new.m4a',
        fileName: 'new.m4a',
        durationSeconds: 42.0,
      );

      expect(ok, isTrue);
      expect(importer.lastOldPath, '/audio/old.m4a');
      final row = (await repo.getRecordingById(recordingId))!;
      expect(row.localFilePath, '/recordings/x.m4a');
      expect(row.durationSeconds, 42.0);
      expect(row.fileSizeBytes, 999);
    });

    test(
      'syncs server metadata and resets retry when previously uploaded',
      () async {
        final recording = await seed(
          uploadStatus: 'uploaded',
          serverId: 'srv-1',
          localFilePath: '/audio/old.m4a',
        );
        final api = _FakeApiRepo();
        final spy = _SyncSpy();
        final importer = _ImporterSpy(sizeBytes: 555);
        final c = makeContainer(api: api, syncSpy: spy, importer: importer);

        await notifierOf(c).replaceAudio(
          recording,
          sourcePath: '/picked/new.m4a',
          fileName: 'new.m4a',
          durationSeconds: 7.0,
        );

        expect(api.lastUpdate['durationSeconds'], 7.0);
        expect(api.lastUpdate['fileSizeBytes'], 555);
        expect(spy.resetAndRetryCalls, 1);
      },
    );
  });
}
