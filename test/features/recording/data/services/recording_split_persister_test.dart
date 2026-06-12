/// Tests for RecordingSplitPersister.
///
/// The persister is the post-FFmpeg pipeline that the trim editor used to
/// inline: it writes the child rows, removes the parent locally and (best-
/// effort) remotely, and triggers the upload queue so children start
/// uploading without the user having to interact further. The bug this
/// guards against: prior to this code path, the trim editor never kicked
/// the sync queue, so children sat in `uploadStatus='local'` indefinitely
/// until the user opened them and edited a field.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/data/services/recording_split_persister.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/domain/entities/split_segment_request.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';

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

  Future<LocalRecording> seedParent({
    String id = 'parent-1',
    String? serverId,
  }) async {
    await repo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(id),
        projectId: const Value('project-1'),
        genreId: const Value('genre-1'),
        title: const Value('Parent'),
        durationSeconds: const Value(60.0),
        fileSizeBytes: const Value(100000),
        format: const Value('m4a'),
        localFilePath: const Value('/local/parent.m4a'),
        uploadStatus: const Value('verified'),
        serverId: Value(serverId),
        gcsUrl: serverId != null
            ? Value('https://gcs.example/$serverId.m4a')
            : const Value(null),
        cleaningStatus: const Value('cleaned'),
        recordedAt: Value(DateTime.utc(2026, 5, 1, 10)),
      ),
    );
    return (await repo.getRecordingById(id))!;
  }

  SplitSegmentSpec spec({String id = 'c1'}) => SplitSegmentSpec(
    id: id,
    title: 'segment',
    localFilePath: '/local/$id.m4a',
    durationSeconds: 30.0,
    fileSizeBytes: 50000,
  );

  test('persists children with uploadStatus=local, deletes the parent row, '
      'and kicks the upload queue exactly once', () async {
    final parent = await seedParent();
    final api = _FakeApiRepo();
    var triggerCalls = 0;
    final persister = RecordingSplitPersister(
      localRepo: repo,
      apiRepo: api,
      triggerUpload: () async {
        triggerCalls++;
      },
    );

    await persister.persist(
      parent: parent,
      segments: [
        spec(id: 'c1'),
        spec(id: 'c2'),
      ],
    );

    final child1 = await repo.getRecordingById('c1');
    final child2 = await repo.getRecordingById('c2');
    final parentAfter = await repo.getRecordingById(parent.id);

    expect(child1, isNotNull);
    expect(child2, isNotNull);
    expect(child1!.uploadStatus, 'local');
    expect(child2!.uploadStatus, 'local');
    expect(parentAfter, isNull);
    expect(triggerCalls, 1);
  });

  test(
    'calls remote deleteRecording with the parent serverId when present',
    () async {
      final parent = await seedParent(serverId: 'server-parent');
      final api = _FakeApiRepo();
      final persister = RecordingSplitPersister(
        localRepo: repo,
        apiRepo: api,
        triggerUpload: () async {},
      );

      await persister.persist(parent: parent, segments: [spec()]);

      expect(api.deleteCalls, ['server-parent']);
    },
  );

  test(
    'does not call remote deleteRecording when parent serverId is null',
    () async {
      final parent = await seedParent();
      final api = _FakeApiRepo();
      final persister = RecordingSplitPersister(
        localRepo: repo,
        apiRepo: api,
        triggerUpload: () async {},
      );

      await persister.persist(parent: parent, segments: [spec()]);

      expect(api.deleteCalls, isEmpty);
    },
  );

  test('swallows remote-delete failures and still triggers upload + persists '
      'children locally', () async {
    final parent = await seedParent(serverId: 'server-parent');
    final api = _FakeApiRepo(deleteThrows: true);
    var triggerCalls = 0;
    final persister = RecordingSplitPersister(
      localRepo: repo,
      apiRepo: api,
      triggerUpload: () async {
        triggerCalls++;
      },
    );

    await persister.persist(
      parent: parent,
      segments: [spec(id: 'c1')],
    );

    expect(await repo.getRecordingById('c1'), isNotNull);
    expect(triggerCalls, 1);
  });

  test('runs trashParent callback before deleting the parent locally, when '
      'a callback is provided', () async {
    final parent = await seedParent();
    final api = _FakeApiRepo();
    LocalRecording? trashedParent;
    bool parentStillPresentDuringTrash = false;
    final persister = RecordingSplitPersister(
      localRepo: repo,
      apiRepo: api,
      triggerUpload: () async {},
      trashParent: (p) async {
        trashedParent = p;
        parentStillPresentDuringTrash =
            (await repo.getRecordingById(p.id)) != null;
      },
    );

    await persister.persist(parent: parent, segments: [spec()]);

    expect(trashedParent?.id, parent.id);
    expect(parentStillPresentDuringTrash, isTrue);
    expect(await repo.getRecordingById(parent.id), isNull);
  });

  test('returns the inserted child ids in order', () async {
    final parent = await seedParent();
    final api = _FakeApiRepo();
    final persister = RecordingSplitPersister(
      localRepo: repo,
      apiRepo: api,
      triggerUpload: () async {},
    );

    final ids = await persister.persist(
      parent: parent,
      segments: [
        spec(id: 'first'),
        spec(id: 'second'),
        spec(id: 'third'),
      ],
    );

    expect(ids, ['first', 'second', 'third']);
  });
}

class _FakeApiRepo implements RecordingApiRepository {
  _FakeApiRepo({this.deleteThrows = false});
  final bool deleteThrows;
  final List<String> deleteCalls = [];

  @override
  Future<bool> deleteRecording(String serverId) async {
    deleteCalls.add(serverId);
    if (deleteThrows) throw Exception('remote delete failed');
    return true;
  }

  @override
  Future<ServerRecording> getRecording(String serverId) =>
      throw UnimplementedError();

  @override
  Future<List<ServerRecording>> listRecordings(
    String projectId, {
    int offset = 0,
    int limit = 50,
    String? userId,
    String? storytellerId,
    String? uploadStatus,
  }) => throw UnimplementedError();

  @override
  Future<bool> updateRecording(
    String serverId, {
    String? title,
    String? description,
    String? genreId,
    String? subcategoryId,
    String? registerId,
    String? secondaryGenreId,
    String? secondarySubcategoryId,
    String? secondaryRegisterId,
    bool clearSecondary = false,
    String? storytellerId,
    String? cleaningStatus,
    double? durationSeconds,
    int? fileSizeBytes,
  }) => throw UnimplementedError();

  @override
  Future<List<String>> splitRecording({
    required String serverId,
    required List<SplitSegmentRequest> segments,
  }) => throw UnimplementedError();

  @override
  Future<int> clearStaleRecordings(String projectId) =>
      throw UnimplementedError();
}
