import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/platform/ffmpeg_ops.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/data/services/joined_audio_exporter.dart';
import 'package:oral_collector/features/recording/data/services/local_segment_exporter.dart';
import 'package:oral_collector/features/recording/domain/entities/pending_metadata_field.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/domain/entities/split_segment_request.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/trim_editor_notifier.dart';
import 'package:oral_collector/features/recording/presentation/trim_edit_decision.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';

import '../../../../support/system_ffmpeg.dart';

const _recordingId = 'rec-1';
const _total = Duration(seconds: 60);

class _ServerCallLog implements RecordingApiRepository {
  final calls = <String>[];
  List<SplitSegmentRequest>? splitSegments;

  @override
  Future<ServerRecording> getRecording(String id) async => ServerRecording(
    id: id,
    projectId: 'proj',
    genreId: 'g0',
    title: 'Story',
    durationSeconds: 60,
    fileSizeBytes: 1000,
    format: 'm4a',
    uploadStatus: 'verified',
    cleaningStatus: 'cleaned',
    recordedAt: DateTime.utc(2026, 5, 1),
  );

  @override
  Future<bool> deleteRecording(String serverId) async {
    calls.add('deleteRecording');
    return true;
  }

  @override
  Future<List<String>> splitRecording({
    required String serverId,
    required List<SplitSegmentRequest> segments,
  }) async {
    calls.add('splitRecording');
    splitSegments = segments;
    return segments.map((_) => 'child').toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation.memberName.toString());
    throw UnimplementedError('${invocation.memberName} not expected');
  }
}

class _CountingSyncNotifier extends SyncNotifier {
  _CountingSyncNotifier(this._onKick);

  final void Function() _onKick;

  @override
  SyncState build() => const SyncState();
  @override
  Future<void> processQueue() async => _onKick();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory docs;
  late String sourcePath;
  late AppDatabase db;
  late LocalRecordingRepository repo;
  late _ServerCallLog server;
  late int uploadKicks;

  setUp(() async {
    uploadKicks = 0;
    docs = Directory.systemTemp.createTempSync('trim_join_save_');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => docs.path);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    sourcePath = '${docs.path}/story.m4a';
    await writeToneM4a(sourcePath, seconds: 60);

    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);
    server = _ServerCallLog();
  });

  tearDown(() async {
    await db.close();
    docs.deleteSync(recursive: true);
  });

  Future<void> seed({
    String? serverId,
    String uploadStatus = 'local',
    String format = 'm4a',
  }) => repo.insertRecording(
    LocalRecordingsCompanion(
      id: const Value(_recordingId),
      projectId: const Value('proj'),
      genreId: const Value('g0'),
      subcategoryId: const Value('sub0'),
      registerId: const Value('reg0'),
      title: const Value('Story'),
      description: const Value('told by the river'),
      durationSeconds: const Value(60.0),
      fileSizeBytes: Value(File(sourcePath).lengthSync()),
      format: Value(format),
      localFilePath: Value(sourcePath),
      uploadStatus: Value(uploadStatus),
      cleaningStatus: const Value('cleaned'),
      serverId: Value(serverId),
      recordedAt: Value(DateTime.utc(2026, 5, 1)),
    ),
  );

  Future<void> seedOther(String id, String title) => repo.insertRecording(
    LocalRecordingsCompanion(
      id: Value(id),
      projectId: const Value('proj'),
      genreId: const Value('g0'),
      title: Value(title),
      durationSeconds: const Value(5.0),
      fileSizeBytes: const Value(10),
      format: const Value('m4a'),
      localFilePath: Value('${docs.path}/$id.m4a'),
      uploadStatus: const Value('uploaded'),
      cleaningStatus: const Value('none'),
      recordedAt: Value(DateTime.utc(2026, 5, 2)),
    ),
  );

  ProviderContainer container({FFmpegRunner joinRunner = runSystemFFmpeg}) {
    final c = ProviderContainer(
      overrides: [
        localRecordingRepositoryProvider.overrideWithValue(repo),
        recordingApiRepositoryProvider.overrideWithValue(server),
        syncNotifierProvider.overrideWith(
          () => _CountingSyncNotifier(() => uploadKicks++),
        ),
        joinedAudioExporterProvider.overrideWithValue(
          (request) => exportJoinedKeptRanges(request, runner: joinRunner),
        ),
        localSegmentExporterProvider.overrideWithValue(
          (request) => exportLocalSegments(request, runner: runSystemFFmpeg),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<TrimEditorNotifier> editWith(
    ProviderContainer c, {
    required List<double> splitSeconds,
    required Set<int> excluded,
    bool isWeb = false,
    Duration editorDuration = _total,
  }) async {
    final notifier = c.read(trimEditorProvider(_recordingId).notifier);
    await notifier.load(isWeb: isWeb);
    notifier.completeLoad(totalDuration: editorDuration);
    notifier.setSplitPoints([
      for (final s in splitSeconds) s / editorDuration.inSeconds,
    ]);
    for (final i in excluded) {
      notifier.toggleExclude(i);
    }
    return notifier;
  }

  Future<TrimSaveOutcome> save(TrimEditorNotifier n, TrimSaveMode mode) =>
      n.saveSplit(isWeb: false, localeTag: 'pt', mode: mode);

  test('a 60 s recording with 20 s to 30 s removed as a stretch stays one '
      'recording, same id and title, 50 s long', () async {
    await seed();
    final n = await editWith(
      container(),
      splitSeconds: [20, 30],
      excluded: {1},
    );

    final outcome = await save(n, TrimSaveMode.removeStretch);

    expect(outcome, isA<TrimSaveSucceeded>());
    final all = await repo.getAllLocalRecordings();
    expect(all, hasLength(1));
    expect(all.single.id, _recordingId);
    expect(all.single.title, 'Story');
    expect(
      await measuredDurationSeconds(all.single.localFilePath),
      closeTo(50, 0.1),
    );
    expect(all.single.durationSeconds, closeTo(50, 0.1));
  });

  test('removing a stretch from an uploaded recording keeps its serverId and '
      'owes the new audio to the metadata outbox', () async {
    await seed(serverId: 'srv-1', uploadStatus: 'uploaded');
    final n = await editWith(
      container(),
      splitSeconds: [20, 30],
      excluded: {1},
    );

    await save(n, TrimSaveMode.removeStretch);

    final row = (await repo.getRecordingById(_recordingId))!;
    expect(row.serverId, 'srv-1');
    expect(decodePendingMetadataFields(row.pendingMetadataJson), {
      PendingMetadataField.audio,
    });
    expect(row.durationSeconds, closeTo(50, 0.1));
    expect(row.fileSizeBytes, File(row.localFilePath).lengthSync());
    expect(row.uploadStatus, 'local');
    expect(uploadKicks, 1);
    expect(server.calls, isEmpty);
  });

  test('removing the first and the last part leaves one recording with the '
      'same id', () async {
    await seed();
    final n = await editWith(
      container(),
      splitSeconds: [10, 50],
      excluded: {0, 2},
    );

    await save(n, TrimSaveMode.removeStretch);

    final all = await repo.getAllLocalRecordings();
    expect(all, hasLength(1));
    expect(all.single.id, _recordingId);
    expect(
      await measuredDurationSeconds(all.single.localFilePath),
      closeTo(40, 0.1),
    );
  });

  test(
    'on the web the save offers no choice and keeps the server split',
    () async {
      await seed(serverId: 'srv-1', uploadStatus: 'uploaded');
      final c = container();
      final n = await editWith(
        c,
        splitSeconds: [20, 30],
        excluded: {1},
        isWeb: true,
      );

      final decision = c.read(trimEditorProvider(_recordingId)).decision;
      await n.saveSplit(isWeb: true, localeTag: 'pt');

      expect(decision.offersJoinChoice(isWeb: true), isFalse);
      expect(server.calls, ['splitRecording']);
      expect(server.splitSegments!.map((s) => (s.startSeconds, s.endSeconds)), [
        (0.0, 20.0),
        (30.0, 60.0),
      ]);
      final row = (await repo.getRecordingById(_recordingId))!;
      expect(row.localFilePath, sourcePath);
    },
  );

  test('keeping the segments separate splits as today, one recording per '
      'kept part', () async {
    await seed();
    final n = await editWith(
      container(),
      splitSeconds: [20, 30],
      excluded: {1},
    );

    await save(n, TrimSaveMode.split);

    final all = await repo.getAllLocalRecordings();
    expect(all, hasLength(2));
    expect(all.map((r) => r.id), isNot(contains(_recordingId)));
    expect(all.map((r) => r.durationSeconds).toList()..sort(), [
      closeTo(20, 0.1),
      closeTo(30, 0.1),
    ]);
  });

  test(
    'saving as a new recording keeps the 60 s original and adds a 50 s '
    'recording titled {original} (2) that uploads as a normal recording',
    () async {
      await seed(serverId: 'srv-1', uploadStatus: 'uploaded');
      final originalBytes = File(sourcePath).lengthSync();
      final n = await editWith(
        container(),
        splitSeconds: [20, 30],
        excluded: {1},
      );

      await save(n, TrimSaveMode.saveAsNew);

      final all = await repo.getAllLocalRecordings();
      expect(all, hasLength(2));
      final original = all.singleWhere((r) => r.id == _recordingId);
      expect(original.title, 'Story');
      expect(original.durationSeconds, 60.0);
      expect(original.localFilePath, sourcePath);
      expect(original.serverId, 'srv-1');
      expect(original.uploadStatus, 'uploaded');
      expect(File(sourcePath).lengthSync(), originalBytes);
      expect(await measuredDurationSeconds(sourcePath), closeTo(60, 0.1));

      final copy = all.singleWhere((r) => r.id != _recordingId);
      expect(copy.title, 'Story (2)');
      expect(
        await measuredDurationSeconds(copy.localFilePath),
        closeTo(50, 0.1),
      );
      expect(copy.durationSeconds, closeTo(50, 0.1));
      expect(copy.serverId, isNull);
      expect(copy.uploadStatus, 'local');
      expect(copy.description, 'told by the river');
      expect(
        (await repo.getPendingUploads()).map((r) => r.id),
        contains(copy.id),
      );
      expect(uploadKicks, 1);
      expect(server.calls, isEmpty);
      expect(Directory('${docs.path}/.trash').existsSync(), isFalse);
    },
  );

  test('saving as a new recording when {original} (2) already exists locally '
      'titles it {original} (3)', () async {
    await seed();
    await seedOther('other', 'Story (2)');
    final n = await editWith(
      container(),
      splitSeconds: [20, 30],
      excluded: {1},
    );

    await save(n, TrimSaveMode.saveAsNew);

    final titles = (await repo.getAllLocalRecordings()).map((r) => r.title);
    expect(titles, unorderedEquals(['Story', 'Story (2)', 'Story (3)']));
  });

  test('removing a stretch puts the previous audio in the trash', () async {
    await seed(serverId: 'srv-1', uploadStatus: 'uploaded');
    final n = await editWith(
      container(),
      splitSeconds: [20, 30],
      excluded: {1},
    );

    await save(n, TrimSaveMode.removeStretch);

    final trashed = Directory('${docs.path}/.trash').listSync();
    final audio = trashed.whereType<File>().singleWhere(
      (f) => f.path.endsWith('_story.m4a'),
    );
    expect(await measuredDurationSeconds(audio.path), closeTo(60, 0.1));
    final sidecar = jsonDecode(File('${audio.path}.json').readAsStringSync());
    expect(sidecar['id'], _recordingId);
    expect(sidecar['serverId'], 'srv-1');
    final row = (await repo.getRecordingById(_recordingId))!;
    expect(sidecar['replacedBy'], row.localFilePath);
    expect(File(sourcePath).existsSync(), isFalse);
  });

  test('a join keeps the recording\'s classification even when a kept part '
      'carried an override', () async {
    await seed();
    final n = await editWith(
      container(),
      splitSeconds: [20, 30],
      excluded: {1},
    );
    n.setSegmentTaxonomy(
      index: 0,
      applyToAll: false,
      genreId: 'g-override',
      subcategoryId: 'sub-override',
      registerId: 'reg-override',
    );

    await save(n, TrimSaveMode.saveAsNew);

    final copy = (await repo.getAllLocalRecordings()).singleWhere(
      (r) => r.id != _recordingId,
    );
    expect(
      (copy.genreId, copy.subcategoryId, copy.registerId),
      ('g0', 'sub0', 'reg0'),
    );
  });

  test(
    'a failed join persists nothing and leaves the original untouched',
    () async {
      await seed();
      final c = container(joinRunner: (_) async => false);
      final n = await editWith(c, splitSeconds: [20, 30], excluded: {1});

      final outcome = await save(n, TrimSaveMode.removeStretch);

      expect(outcome, isA<TrimSaveFailed>());
      final all = await repo.getAllLocalRecordings();
      expect(all.single.localFilePath, sourcePath);
      expect(all.single.durationSeconds, 60.0);
      expect(File(sourcePath).existsSync(), isTrue);
    },
  );

  test('a mode picked on the web is ignored and the server splits', () async {
    await seed(serverId: 'srv-1', uploadStatus: 'uploaded');
    final n = await editWith(
      container(),
      splitSeconds: [20, 30],
      excluded: {1},
      isWeb: true,
    );

    await n.saveSplit(
      isWeb: true,
      localeTag: 'pt',
      mode: TrimSaveMode.removeStretch,
    );

    expect(server.calls, ['splitRecording']);
    final row = (await repo.getRecordingById(_recordingId))!;
    expect(row.localFilePath, sourcePath);
    expect(row.durationSeconds, 60.0);
    expect(decodePendingMetadataFields(row.pendingMetadataJson), isEmpty);
  });

  group('a joined recording takes the format of the joined file', () {
    setUp(() async {
      sourcePath = '${docs.path}/story.mp3';
      await writeToneMp3(sourcePath, seconds: 60);
      await seed(format: 'mp3');
    });

    test('removing a stretch from an mp3 recording leaves it m4a', () async {
      final n = await editWith(
        container(),
        splitSeconds: [20, 30],
        excluded: {1},
      );

      await save(n, TrimSaveMode.removeStretch);

      final row = (await repo.getRecordingById(_recordingId))!;
      expect(row.localFilePath, endsWith('.m4a'));
      expect(row.format, 'm4a');
    });

    test('saving an mp3 recording as a new recording makes the new one m4a '
        'and leaves the original mp3', () async {
      final n = await editWith(
        container(),
        splitSeconds: [20, 30],
        excluded: {1},
      );

      await save(n, TrimSaveMode.saveAsNew);

      final all = await repo.getAllLocalRecordings();
      final copy = all.singleWhere((r) => r.id != _recordingId);
      final original = all.singleWhere((r) => r.id == _recordingId);
      expect(copy.localFilePath, endsWith('.m4a'));
      expect(copy.format, 'm4a');
      expect(original.format, 'mp3');
    });
  });

  test('removing a stretch when the editor believed the recording longer than '
      'its file keeps the original audio', () async {
    await seed();
    final n = await editWith(
      container(),
      splitSeconds: [20, 30],
      excluded: {1},
      editorDuration: const Duration(seconds: 70),
    );

    final outcome = await save(n, TrimSaveMode.removeStretch);

    expect(outcome, isA<TrimSaveFailed>());
    final row = (await repo.getRecordingById(_recordingId))!;
    expect(row.localFilePath, sourcePath);
    expect(row.durationSeconds, 60.0);
    expect(File(sourcePath).existsSync(), isTrue);
  });
}
