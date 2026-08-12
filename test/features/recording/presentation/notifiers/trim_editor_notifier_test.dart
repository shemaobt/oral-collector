/// Unit tests for TrimEditorNotifier (ENG-193): the split-persist orchestration
/// and editing state extracted from the trim editor screen. Drives the notifier
/// through a ProviderContainer with the platform IO seams faked, so the save
/// paths (web + native) and load resolution are characterized without a device.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/data/services/local_segment_exporter.dart';
import 'package:oral_collector/features/recording/data/services/recording_boost_persister.dart';
import 'package:oral_collector/features/recording/data/services/recording_split_persister.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/domain/entities/split_segment_request.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/trim_editor_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/trim_editor_state.dart';
import 'package:oral_collector/features/recording/presentation/trim_edit_decision.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';

const recordingId = 'rec-1';

/// What the exporter returns for a boost-only save: the whole clip, re-encoded.
const boostedSpec = SplitSegmentSpec(
  id: 'c0',
  title: 'Story',
  localFilePath: '/out/boosted.m4a',
  durationSeconds: 10,
  fileSizeBytes: 2048,
);

/// Stands in for the server, holding the set of recordings it knows about, so a
/// test can ask what survived a save rather than which methods were called.
class _FakeApiRepo implements RecordingApiRepository {
  _FakeApiRepo({this.getRecordingImpl, Set<String>? serverRecordings})
    : serverRecordings = serverRecordings ?? <String>{};

  final Future<ServerRecording> Function(String id)? getRecordingImpl;

  /// The ids the server still has.
  final Set<String> serverRecordings;

  String? splitServerId;
  List<SplitSegmentRequest>? splitSegments;

  @override
  Future<ServerRecording> getRecording(String id) =>
      (getRecordingImpl ?? (_) => throw StateError('getRecording unexpected'))(
        id,
      );

  @override
  Future<bool> deleteRecording(String serverId) async =>
      serverRecordings.remove(serverId);

  @override
  Future<List<String>> splitRecording({
    required String serverId,
    required List<SplitSegmentRequest> segments,
  }) async {
    splitServerId = serverId;
    splitSegments = segments;
    return segments.map((_) => 'child').toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected');
}

class _ExporterSpy {
  _ExporterSpy.throwing() : cannedSpecs = const [], throwOnCall = true;
  _ExporterSpy.returning(this.cannedSpecs) : throwOnCall = false;

  final List<SplitSegmentSpec> cannedSpecs;
  final bool throwOnCall;

  String? sourceFilePath;
  List<SegmentExportSpec>? segments;
  double? gainDb;
  bool? boostOnly;
  String? originalTitle;
  String? parentGenreId;

  Future<List<SplitSegmentSpec>> call(
    ExportLocalSegmentsRequest request,
  ) async {
    sourceFilePath = request.sourceFilePath;
    segments = request.segments;
    gainDb = request.gainDb;
    boostOnly = request.boostOnly;
    originalTitle = request.originalTitle;
    parentGenreId = request.parentGenreId;
    if (throwOnCall) throw Exception('ffmpeg failed');
    return cannedSpecs;
  }
}

class _FakePersister extends RecordingSplitPersister {
  _FakePersister({
    required super.localRepo,
    required super.apiRepo,
    required super.triggerUpload,
    super.trashParent,
  });

  LocalRecordingEntity? persistedParent;
  List<SplitSegmentSpec>? persistedSegments;

  @override
  Future<List<String>> persist({
    required LocalRecordingEntity parent,
    required List<SplitSegmentSpec> segments,
  }) async {
    persistedParent = parent;
    persistedSegments = segments;
    return segments.map((s) => s.id).toList();
  }
}

class _FakeSyncNotifier extends SyncNotifier {
  @override
  SyncState build() => const SyncState();
  @override
  Future<void> processQueue() async {}
}

ServerRecording _serverRecording(String id) => ServerRecording(
  id: id,
  projectId: 'proj',
  genreId: 'g0',
  durationSeconds: 30,
  fileSizeBytes: 1000,
  format: 'm4a',
  uploadStatus: 'verified',
  cleaningStatus: 'cleaned',
  recordedAt: DateTime.utc(2026, 5, 1),
);

void main() {
  late AppDatabase db;
  late LocalRecordingRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);
  });
  tearDown(() => db.close());

  Future<LocalRecording> seed({String? serverId}) async {
    await repo.insertRecording(
      LocalRecordingsCompanion(
        id: const Value(recordingId),
        projectId: const Value('proj'),
        genreId: const Value('g0'),
        subcategoryId: const Value('sub0'),
        registerId: const Value('reg0'),
        title: const Value('Story'),
        durationSeconds: const Value(30.0),
        fileSizeBytes: const Value(1000),
        format: const Value('m4a'),
        localFilePath: const Value('/audio/in.m4a'),
        uploadStatus: const Value('local'),
        cleaningStatus: const Value('cleaned'),
        serverId: Value(serverId),
        recordedAt: Value(DateTime.utc(2026, 5, 1)),
      ),
    );
    return (await repo.getRecordingById(recordingId))!;
  }

  ProviderContainer makeContainer({
    RecordingApiRepository? api,
    _ExporterSpy? exporter,
    _FakePersister Function(_FakePersister)? capturePersister,
    bool useRealSplitPersister = false,
  }) {
    final container = ProviderContainer(
      overrides: [
        localRecordingRepositoryProvider.overrideWithValue(repo),
        recordingApiRepositoryProvider.overrideWithValue(api ?? _FakeApiRepo()),
        syncNotifierProvider.overrideWith(_FakeSyncNotifier.new),
        if (exporter != null)
          localSegmentExporterProvider.overrideWithValue(exporter.call),
        // Both persisters run for real against the in-memory database, minus
        // the one seam a VM test cannot have: archiving the replaced file needs
        // the documents directory, which is a platform channel.
        recordingBoostPersisterProvider.overrideWithValue(
          ({required localRepo, required triggerUpload, trashPrevious}) =>
              RecordingBoostPersister(
                localRepo: localRepo,
                triggerUpload: triggerUpload,
              ),
        ),
        if (useRealSplitPersister)
          recordingSplitPersisterProvider.overrideWithValue(
            ({
              required localRepo,
              required apiRepo,
              required triggerUpload,
              trashParent,
            }) => RecordingSplitPersister(
              localRepo: localRepo,
              apiRepo: apiRepo,
              triggerUpload: triggerUpload,
            ),
          ),
        if (capturePersister != null)
          recordingSplitPersisterProvider.overrideWithValue(
            ({
              required localRepo,
              required apiRepo,
              required triggerUpload,
              trashParent,
            }) => capturePersister(
              _FakePersister(
                localRepo: localRepo,
                apiRepo: apiRepo,
                triggerUpload: triggerUpload,
                trashParent: trashParent,
              ),
            ),
          ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  TrimEditorNotifier notifierOf(ProviderContainer c) =>
      c.read(trimEditorProvider(recordingId).notifier);
  TrimEditorState stateOf(ProviderContainer c) =>
      c.read(trimEditorProvider(recordingId));

  group('load', () {
    test('native: resolves a local recording by id', () async {
      final recording = await seed();
      final c = makeContainer();
      await notifierOf(c).load(isWeb: false);

      expect(stateOf(c).recording?.id, recording.id);
      expect(stateOf(c).errorMessage, isNull);
      expect(stateOf(c).loadError, isNull);
    });

    test('native: falls back to lookup by server id', () async {
      await seed(serverId: 'srv-9');
      final c = makeContainer();
      // The screen id misses getRecordingById and hits getRecordingByServerId.
      await c.read(trimEditorProvider('srv-9').notifier).load(isWeb: false);

      expect(c.read(trimEditorProvider('srv-9')).recording?.serverId, 'srv-9');
    });

    test('native: a 404 from the server leaves a not-found state', () async {
      final api = _FakeApiRepo(
        getRecordingImpl: (_) async =>
            throw const ValidationException(statusCode: 404),
      );
      final c = makeContainer(api: api);
      await notifierOf(c).load(isWeb: false);

      expect(stateOf(c).recording, isNull);
      expect(stateOf(c).isLoading, isFalse);
      expect(stateOf(c).loadError, isNull);
    });

    test('native: a non-404 error is surfaced as a load error', () async {
      const error = ServerException(statusCode: 500);
      final api = _FakeApiRepo(getRecordingImpl: (_) async => throw error);
      final c = makeContainer(api: api);
      await notifierOf(c).load(isWeb: false);

      expect(stateOf(c).loadError, same(error));
      expect(stateOf(c).isLoading, isFalse);
      expect(stateOf(c).recording, isNull);
    });

    test('web: loads the recording from the server', () async {
      final api = _FakeApiRepo(
        getRecordingImpl: (_) async => _serverRecording('srv-web'),
      );
      final c = makeContainer(api: api);
      await notifierOf(c).load(isWeb: true);

      expect(stateOf(c).recording?.id, 'srv-web');
      // The server carries no on-device file, so the server->entity projection
      // leaves localFilePath empty.
      expect(stateOf(c).recording?.localFilePath, '');
      expect(stateOf(c).loadError, isNull);
    });

    test('native: falls back to the server when no local row exists', () async {
      final api = _FakeApiRepo(
        getRecordingImpl: (_) async => _serverRecording('srv-fallback'),
      );
      final c = makeContainer(api: api);
      // No seed: both local lookups miss, so the load fetches from the server.
      await notifierOf(c).load(isWeb: false);

      expect(stateOf(c).recording?.id, 'srv-fallback');
      expect(stateOf(c).loadError, isNull);
    });
  });

  group('editing mutations', () {
    test('setSplitPoints prunes out-of-range exclusions', () async {
      await seed();
      final c = makeContainer();
      await notifierOf(c).load(isWeb: false);
      notifierOf(c).setSplitPoints([0.3, 0.6]); // 3 segments
      notifierOf(c).toggleExclude(2);
      expect(stateOf(c).excludedSegments, {2});

      notifierOf(c).setSplitPoints([0.5]); // back to 2 segments
      expect(stateOf(c).excludedSegments, isEmpty);
    });

    test('toggleExclude refuses to exclude the last kept segment', () async {
      await seed();
      final c = makeContainer();
      await notifierOf(c).load(isWeb: false);
      notifierOf(c).setSplitPoints([0.5]); // 2 segments
      expect(notifierOf(c).toggleExclude(0), isTrue);
      // Only segment 1 is kept; excluding it would leave none.
      expect(notifierOf(c).toggleExclude(1), isFalse);
      expect(stateOf(c).excludedSegments, {0});
    });

    test('setGain updates only the gain', () async {
      final c = makeContainer();
      notifierOf(c).setGain(4.5);
      expect(stateOf(c).gainDb, 4.5);
    });

    test('setSegmentTaxonomy applies to all segments or just one', () async {
      await seed();
      final c = makeContainer();
      await notifierOf(c).load(isWeb: false);
      notifierOf(c).setSplitPoints([0.5]); // 2 segments
      notifierOf(c).setSegmentTaxonomy(
        index: 0,
        applyToAll: true,
        genreId: 'gAll',
        subcategoryId: null,
        registerId: null,
      );
      expect(stateOf(c).effectiveGenre(0), 'gAll');
      expect(stateOf(c).effectiveGenre(1), 'gAll');

      notifierOf(c).setSegmentTaxonomy(
        index: 1,
        applyToAll: false,
        genreId: 'gOne',
        subcategoryId: null,
        registerId: null,
      );
      expect(stateOf(c).effectiveGenre(0), 'gAll');
      expect(stateOf(c).effectiveGenre(1), 'gOne');
    });

    test('copyFromPrevious copies the previous segment override', () async {
      await seed();
      final c = makeContainer();
      await notifierOf(c).load(isWeb: false);
      notifierOf(c).setSplitPoints([0.5]);
      notifierOf(c).setSegmentTaxonomy(
        index: 0,
        applyToAll: false,
        genreId: 'gPrev',
        subcategoryId: null,
        registerId: null,
      );
      notifierOf(c).copyFromPrevious(1);
      expect(stateOf(c).effectiveGenre(1), 'gPrev');
    });

    test('clearAllSplits and restoreAllExcluded reset editing state', () async {
      await seed();
      final c = makeContainer();
      await notifierOf(c).load(isWeb: false);
      notifierOf(c).setSplitPoints([0.3, 0.6]);
      notifierOf(c).toggleExclude(0);
      expect(stateOf(c).excludedSegments, isNotEmpty);

      notifierOf(c).restoreAllExcluded();
      expect(stateOf(c).excludedSegments, isEmpty);

      notifierOf(c).clearAllSplits();
      expect(stateOf(c).splitPoints, isEmpty);
    });
  });

  group('saveSplit', () {
    Future<void> prepareEditableState(ProviderContainer c) async {
      await notifierOf(c).load(isWeb: false);
      notifierOf(c).completeLoad(totalDuration: const Duration(seconds: 10));
      notifierOf(c).setSplitPoints([0.5]);
    }

    /// A gain change and no cut points — the mode the editor calls boost-only.
    Future<void> prepareBoostOnlyState(ProviderContainer c) async {
      await notifierOf(c).load(isWeb: false);
      notifierOf(c).completeLoad(totalDuration: const Duration(seconds: 10));
      notifierOf(c).setGain(3.0);
    }

    test(
      'native: exports kept segments and hands them to the persister',
      () async {
        final recording = await seed();
        final exporter = _ExporterSpy.returning(const [
          SplitSegmentSpec(
            id: 'c0',
            title: 'Story (1/2)',
            localFilePath: '/out/0.m4a',
            durationSeconds: 5,
            fileSizeBytes: 10,
          ),
          SplitSegmentSpec(
            id: 'c1',
            title: 'Story (2/2)',
            localFilePath: '/out/1.m4a',
            durationSeconds: 5,
            fileSizeBytes: 10,
          ),
        ]);
        _FakePersister? created;
        final c = makeContainer(
          exporter: exporter,
          capturePersister: (p) => created = p,
        );
        await prepareEditableState(c);

        final outcome = await notifierOf(
          c,
        ).saveSplit(isWeb: false, localeTag: 'en');

        expect(exporter.sourceFilePath, '/audio/in.m4a');
        expect(exporter.segments, hasLength(2));
        expect(exporter.boostOnly, isFalse);
        expect(exporter.parentGenreId, 'g0');
        expect(created?.persistedParent?.id, recording.id);
        expect(created?.persistedSegments?.map((s) => s.id), ['c0', 'c1']);
        expect(outcome, isA<TrimSaveSucceeded>());
        expect((outcome as TrimSaveSucceeded).mode, TrimSaveMode.split);
        expect(outcome.keptCount, 2);
        expect(outcome.excludedCount, 0);
      },
    );

    test('web: posts split-segment requests to the api', () async {
      await seed(serverId: 'srv-9');
      final api = _FakeApiRepo();
      final c = makeContainer(api: api);
      await prepareEditableState(c);

      final outcome = await notifierOf(
        c,
      ).saveSplit(isWeb: true, localeTag: 'en');

      expect(api.splitServerId, 'srv-9');
      expect(api.splitSegments, hasLength(2));
      expect(api.splitSegments!.first.startSeconds, 0.0);
      expect(api.splitSegments!.first.endSeconds, 5.0);
      expect(api.splitSegments!.first.gainDb, isNull); // no gain change
      expect(outcome, isA<TrimSaveSucceeded>());
    });

    test(
      'native boost-only: exports the whole clip as a single segment',
      () async {
        await seed();
        final exporter = _ExporterSpy.returning(const [boostedSpec]);
        final c = makeContainer(exporter: exporter);
        await prepareBoostOnlyState(c);

        final outcome = await notifierOf(
          c,
        ).saveSplit(isWeb: false, localeTag: 'en');

        expect(exporter.boostOnly, isTrue);
        expect(exporter.segments, hasLength(1));
        expect(exporter.gainDb, 3.0);
        expect((outcome as TrimSaveSucceeded).mode, TrimSaveMode.boostOnly);
      },
    );

    // ENG-402. A save with no cut points is not a split: it updates the story
    // it was opened on. It used to delete that story and insert a new one, and
    // the matching remote delete is best-effort — so an offline boost left the
    // server holding two live recordings and the project counted the story
    // twice.
    group('native boost-only keeps the recording it edited', () {
      test('one row survives, with the same id and serverId', () async {
        await seed(serverId: 'srv-1');
        final c = makeContainer(
          exporter: _ExporterSpy.returning(const [boostedSpec]),
        );
        await prepareBoostOnlyState(c);

        await notifierOf(c).saveSplit(isWeb: false, localeTag: 'en');

        final all = await repo.getAllLocalRecordings();
        expect(all, hasLength(1));
        expect(all.single.id, recordingId);
        expect(all.single.serverId, 'srv-1');
      });

      test('the row points at the boosted audio', () async {
        await seed(serverId: 'srv-1');
        final c = makeContainer(
          exporter: _ExporterSpy.returning(const [boostedSpec]),
        );
        await prepareBoostOnlyState(c);

        await notifierOf(c).saveSplit(isWeb: false, localeTag: 'en');

        final row = (await repo.getRecordingById(recordingId))!;
        expect(row.localFilePath, '/out/boosted.m4a');
        expect(row.fileSizeBytes, 2048);
      });

      test('the server keeps the recording it already had', () async {
        await seed(serverId: 'srv-1');
        final api = _FakeApiRepo(serverRecordings: {'srv-1'});
        final c = makeContainer(
          api: api,
          exporter: _ExporterSpy.returning(const [boostedSpec]),
        );
        await prepareBoostOnlyState(c);

        await notifierOf(c).saveSplit(isWeb: false, localeTag: 'en');

        expect(api.serverRecordings, {'srv-1'});
      });
    });

    test('native with cut points is still a split: the original is replaced '
        'by its segments', () async {
      await seed(serverId: 'srv-1');
      final api = _FakeApiRepo(serverRecordings: {'srv-1'});
      final c = makeContainer(
        api: api,
        useRealSplitPersister: true,
        exporter: _ExporterSpy.returning(const [
          SplitSegmentSpec(
            id: 'c0',
            title: 'Story (1/2)',
            localFilePath: '/out/0.m4a',
            durationSeconds: 5,
            fileSizeBytes: 10,
          ),
          SplitSegmentSpec(
            id: 'c1',
            title: 'Story (2/2)',
            localFilePath: '/out/1.m4a',
            durationSeconds: 5,
            fileSizeBytes: 10,
          ),
        ]),
      );
      await prepareEditableState(c);

      await notifierOf(c).saveSplit(isWeb: false, localeTag: 'en');

      final all = await repo.getAllLocalRecordings();
      expect(all.map((r) => r.id), unorderedEquals(['c0', 'c1']));
      expect(api.serverRecordings, isEmpty);
    });

    test('aborts when there is nothing to save', () async {
      await seed();
      final c = makeContainer();
      await notifierOf(c).load(isWeb: false);
      notifierOf(c).completeLoad(totalDuration: const Duration(seconds: 10));
      // No edits -> canSave is false.
      final outcome = await notifierOf(
        c,
      ).saveSplit(isWeb: false, localeTag: 'en');
      expect(outcome, isA<TrimSaveAborted>());
    });

    test('a failed export surfaces a failure and resets isSaving', () async {
      await seed();
      final c = makeContainer(exporter: _ExporterSpy.throwing());
      await prepareEditableState(c);

      final outcome = await notifierOf(
        c,
      ).saveSplit(isWeb: false, localeTag: 'en');

      expect(outcome, isA<TrimSaveFailed>());
      expect(stateOf(c).isSaving, isFalse);
    });
  });
}
