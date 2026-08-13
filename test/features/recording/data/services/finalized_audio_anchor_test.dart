/// ENG-420 slice 1: the session row must know where the finalized audio is
/// before it is marked completed.
///
/// Until now the only thing linking a stopped session to the file it produced
/// was a substring match on the filename, and it only appeared once the user
/// finished the save form — minutes later, if ever. These tests observe the
/// persisted session row and the disk after running the real finalizer, so
/// they say nothing about how the write is implemented, only that the anchor
/// is there and that it lands before the status flips.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart'
    show ApplyInterceptor, QueryExecutor, QueryInterceptor, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/repositories/recording_session_repository.dart';
import 'package:oral_collector/features/recording/data/services/recording_concat_service.dart';
import 'package:oral_collector/features/recording/data/services/recording_finalization_service.dart';
import 'package:oral_collector/features/recording/data/services/segment_paths.dart';

/// ffmpeg never runs in the VM, so the concat is emulated by byte-copying the
/// segments. Everything else on the path is the real production code.
class _ByteCopyConcat implements RecordingConcatService {
  @override
  Future<String?> concatSegments({
    required List<String> segmentPaths,
    required String outputPath,
  }) async {
    final out = File(outputPath).openSync(mode: FileMode.write);
    try {
      for (final p in segmentPaths) {
        out.writeFromSync(await File(p).readAsBytes());
      }
    } finally {
      out.closeSync();
    }
    return outputPath;
  }
}

/// Reads the anchor straight from the raw database at the exact moment the
/// session is updated to `completed`, which is the only way to tell "written
/// before" from "written eventually".
class _AnchorAtCompletion extends QueryInterceptor {
  Object? anchorSeen;
  var sawCompletion = false;

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    if (statement.contains('recording_sessions') &&
        args.contains('completed')) {
      sawCompletion = true;
      final rows = await executor.runSelect(
        'SELECT finalized_audio_path FROM recording_sessions WHERE id = ?',
        [args.last],
      );
      anchorSeen = rows.single['finalized_audio_path'];
    }
    return super.runUpdate(executor, statement, args);
  }
}

Uint8List _wavBytes(int samples) {
  const sampleRate = 16000;
  const numChannels = 1;
  const bitsPerSample = 16;
  final dataSize = samples * 2;
  final b = BytesBuilder()
    ..add('RIFF'.codeUnits)
    ..add(_u32(36 + dataSize))
    ..add('WAVE'.codeUnits)
    ..add('fmt '.codeUnits)
    ..add(_u32(16))
    ..add(_u16(1))
    ..add(_u16(numChannels))
    ..add(_u32(sampleRate))
    ..add(_u32(sampleRate * numChannels * bitsPerSample ~/ 8))
    ..add(_u16(numChannels * bitsPerSample ~/ 8))
    ..add(_u16(bitsPerSample))
    ..add('data'.codeUnits)
    ..add(_u32(dataSize))
    ..add(Uint8List(dataSize));
  return b.toBytes();
}

List<int> _u32(int v) => [
  v & 0xff,
  (v >> 8) & 0xff,
  (v >> 16) & 0xff,
  (v >> 24) & 0xff,
];
List<int> _u16(int v) => [v & 0xff, (v >> 8) & 0xff];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory docs;
  late AppDatabase db;
  late RecordingSessionRepository repo;
  late _AnchorAtCompletion probe;

  const sessionId = 'sess-anchor';

  setUp(() async {
    docs = await Directory.systemTemp.createTemp('eng420_anchor_');
    probe = _AnchorAtCompletion();
    db = AppDatabase.forTesting(NativeDatabase.memory().interceptWith(probe));
    repo = RecordingSessionRepository(db);
  });

  tearDown(() async {
    await db.close();
    // finalize() fires its source deletions with unawaited(); let them land
    // before the recursive delete walks the directory.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (docs.existsSync()) docs.deleteSync(recursive: true);
  });

  Future<List<String>> seedRecordedSession({int segmentCount = 3}) async {
    final paths = <String>[];
    for (var i = 0; i < segmentCount; i++) {
      final p = SegmentPaths.forSegment(docs.path, sessionId, i);
      await File(p).writeAsBytes(_wavBytes(16000));
      paths.add(p);
    }
    await repo.insertSession(
      RecordingSessionsCompanion.insert(
        id: sessionId,
        projectId: 'proj-1',
        genreId: 'genre-1',
        startedAt: DateTime(2026, 8, 12),
        status: const Value('active'),
        segmentPathsJson: Value(jsonEncode(paths)),
        totalDurationSeconds: Value(segmentCount.toDouble()),
        lastSegmentIndex: Value(segmentCount - 1),
      ),
    );
    return paths;
  }

  RecordingFinalizationService finalizer({
    RecordingConcatService? concat,
    DocumentsDirFn? documentsDirFn,
  }) => RecordingFinalizationService(
    concat: concat ?? _ByteCopyConcat(),
    documentsDirFn: documentsDirFn ?? () async => docs,
    compressFn: (src, dst) async {
      if (await File(src).length() < 44) return false;
      await File(dst).writeAsBytes(await File(src).readAsBytes());
      return true;
    },
  );

  /// Mirrors what _stopNative does around _finalizeOrCrash: a successful
  /// outcome goes to the repository call that anchors and completes, a failed
  /// one crashes the session. The finalizer and the repository are the real
  /// ones, and the ordering under test lives inside the repository — not here.
  Future<FinalizationOutcome?> stopRecording(
    List<String> paths, {
    RecordingFinalizationService? service,
  }) async {
    FinalizationOutcome? outcome;
    try {
      outcome = await (service ?? finalizer()).finalize(
        sessionId: sessionId,
        segmentPaths: paths,
        totalDuration: const Duration(minutes: 18),
      );
    } on FileSystemException {
      outcome = null;
    }
    if (outcome != null) {
      await repo.completeWithFinalizedAudio(
        sessionId,
        filePath: outcome.result.filePath,
        durationSeconds: outcome.result.durationSeconds,
      );
    } else {
      await repo.markCrashed(sessionId);
    }
    return outcome;
  }

  group('ENG-420: a stopped session anchors the audio it produced', () {
    test(
      'stopping a successful recording records a path that exists on disk',
      () async {
        final paths = await seedRecordedSession();

        final outcome = await stopRecording(paths);

        expect(outcome, isNotNull, reason: 'finalization must have succeeded');
        final session = await repo.getById(sessionId);
        expect(session, isNotNull);
        expect(
          session!.finalizedAudioPath,
          outcome!.result.filePath,
          reason: 'the row must point at the file the app will actually use',
        );
        expect(File(session.finalizedAudioPath!).existsSync(), isTrue);
        expect(session.finalizedDurationSeconds, 1080.0);
      },
    );

    test(
      'a single-segment recording anchors the file the app will play',
      () async {
        // No concat runs: the source segment is the finalized audio, unless the
        // compression step replaces it.
        final paths = await seedRecordedSession(segmentCount: 1);

        final outcome = await stopRecording(paths);

        final session = await repo.getById(sessionId);
        expect(session!.finalizedAudioPath, outcome!.result.filePath);
        expect(File(session.finalizedAudioPath!).existsSync(), isTrue);
      },
    );

    test(
      'the session is never completed without the anchor already in place',
      () async {
        final paths = await seedRecordedSession();

        await stopRecording(paths);

        expect(probe.sawCompletion, isTrue, reason: 'the session did complete');
        expect(
          probe.anchorSeen,
          isNotNull,
          reason:
              'read from the database at the instant of the status update: the '
              'anchor must already be there, so swapping the two writes fails here',
        );
        expect((await repo.getById(sessionId))?.status, 'completed');
      },
    );

    test(
      'a finalization that blows up crashes the session and anchors nothing',
      () async {
        final paths = await seedRecordedSession();

        final outcome = await stopRecording(
          paths,
          service: finalizer(
            documentsDirFn: () async =>
                throw const FileSystemException('documents unavailable'),
          ),
        );

        expect(outcome, isNull);
        final session = await repo.getById(sessionId);
        expect(session!.status, 'crashed');
        expect(
          session.finalizedAudioPath,
          isNull,
          reason:
              'an anchor pointing at a file that was never produced would be '
              'worse than no anchor at all',
        );
        expect(session.finalizedDurationSeconds, isNull);
      },
    );
  });
}
