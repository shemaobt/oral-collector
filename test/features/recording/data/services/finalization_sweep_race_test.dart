import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/database/database_provider.dart';
import 'package:oral_collector/core/platform/file_ops.dart' as file_ops;
import 'package:oral_collector/features/recording/data/repositories/recording_session_repository.dart';
import 'package:oral_collector/features/recording/data/services/recording_concat_service.dart';
import 'package:oral_collector/features/recording/data/services/recording_finalization_service.dart';
import 'package:oral_collector/features/recording/data/services/recovery_coordinator.dart';
import 'package:oral_collector/features/recording/data/services/segment_paths.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// ffmpeg reporting failure — a full disk while writing the concat output of a
/// long recording is the realistic way there.
class _FailingConcat implements RecordingConcatService {
  @override
  Future<String?> concatSegments({
    required List<String> segmentPaths,
    required String outputPath,
  }) async => null;
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
  late ProviderContainer container;

  const sessionId = 'sess-long';
  const segmentCount = 3;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    docs = await Directory.systemTemp.createTemp('eng408_sweep_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RecordingSessionRepository(db);
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        recoveryCoordinatorProvider.overrideWith(
          (ref) =>
              RecoveryCoordinator(ref, directoryResolver: () async => docs),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    // These tests deliberately leave finalize()'s unawaited source deletions
    // in flight. Let them land, then delete synchronously so the recursive
    // walk cannot race them.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (docs.existsSync()) docs.deleteSync(recursive: true);
  });

  /// A session that recorded [segmentCount] segments and reached the stop
  /// button — exactly the state _stopNative hands to the finalizer.
  Future<List<String>> seedRecordedSession() async {
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
        startedAt: DateTime(2026, 8, 11),
        status: const Value('active'),
        segmentPathsJson: Value(jsonEncode(paths)),
        totalDurationSeconds: Value(segmentCount.toDouble()),
        lastSegmentIndex: const Value(segmentCount - 1),
      ),
    );
    return paths;
  }

  /// Runs the real finalizer the way _stopNative does, then records the
  /// success the way _stopNative does (markCompleted).
  Future<FinalizationOutcome?> finalizeAndComplete(
    List<String> paths, {
    required DeleteFn deleteFn,
    RecordingConcatService? concat,
  }) async {
    final service = RecordingFinalizationService(
      concat: concat ?? _ByteCopyConcat(),
      documentsDirFn: () async => docs,
      compressFn: (src, dst) async {
        // Real ffmpeg cannot compress a truncated source either.
        if (await File(src).length() < 44) return false;
        await File(dst).writeAsBytes(await File(src).readAsBytes());
        return true;
      },
      deleteFn: deleteFn,
    );
    final outcome = await service.finalize(
      sessionId: sessionId,
      segmentPaths: paths,
      totalDuration: const Duration(minutes: 18),
    );
    await repo.markCompleted(sessionId);
    return outcome;
  }

  bool anySegmentLeft() {
    final prefix = SegmentPaths.prefixFor(docs.path, sessionId);
    return docs.listSync().whereType<File>().any(
      (f) => SegmentPaths.parseIndex(f.path, prefix) != null,
    );
  }

  group('ENG-408: the recovery offer for a finalized session is a race', () {
    test(
      'sweep re-marks a SUCCESSFULLY finalized session as crashed when it runs '
      'before the fire-and-forget source deletions land',
      () async {
        final paths = await seedRecordedSession();
        // finalize() fires the source deletions with unawaited(); this gate
        // holds them in flight, which is the state the process is in for a
        // real (slow disk, iOS file coordination) deletion.
        final gate = Completer<void>();
        final outcome = await finalizeAndComplete(
          paths,
          deleteFn: (p) async {
            await gate.future;
            await file_ops.deleteFile(p);
          },
        );

        expect(outcome, isNotNull, reason: 'finalization must have succeeded');
        expect(File(outcome!.result.filePath).existsSync(), isTrue);
        expect(anySegmentLeft(), isTrue, reason: 'deletions still in flight');

        await container.read(recoveryCoordinatorProvider).scanOnStartup();

        expect(
          (await repo.getById(sessionId))?.status,
          'crashed',
          reason:
              'the recording finalized fine, yet the sweep offers it for '
              'recovery purely because the deletions had not landed',
        );
        expect(
          container.read(interruptedSessionsProvider).map((s) => s.sessionId),
          contains(sessionId),
        );

        gate.complete();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
    );

    test('the confirmation-form window on its own does NOT produce the banner: '
        'once the deletions land the sweep leaves the session alone — and the '
        'finished audio is then unreachable', () async {
      final paths = await seedRecordedSession();
      final outcome = await finalizeAndComplete(
        paths,
        deleteFn: file_ops.deleteFile,
      );

      // The user is typing title and description; the deletions have all the
      // time in the world to land.
      for (var i = 0; i < 100 && anySegmentLeft(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(anySegmentLeft(), isFalse, reason: 'deletions landed');

      await container.read(recoveryCoordinatorProvider).scanOnStartup();

      expect(
        (await repo.getById(sessionId))?.status,
        'completed',
        reason: 'same inputs, same success — opposite classification',
      );
      expect(
        container.read(interruptedSessionsProvider).map((s) => s.sessionId),
        isNot(contains(sessionId)),
      );
      // Nothing references the finalized file: no LocalRecording row (the
      // user never got to the save form) and no recovery offer either.
      expect(
        File(outcome!.result.filePath).existsSync(),
        isTrue,
        reason: '18 minutes of audio sitting on disk that nothing points at',
      );
    });

    test(
      'when both concat paths fail, finalize deletes NOTHING — every segment '
      'is leaked and re-offers the session for recovery on every launch',
      () async {
        final paths = await seedRecordedSession();
        // A rotation cut short by a full disk leaves a truncated segment; the
        // pure-Dart fallback rejects it, so both concat paths are out.
        await File(paths.first).writeAsBytes(Uint8List(20));

        final outcome = await finalizeAndComplete(
          paths,
          deleteFn: file_ops.deleteFile,
          concat: _FailingConcat(),
        );

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(outcome, isNotNull);
        expect(outcome!.degraded, isTrue);
        final prefix = SegmentPaths.prefixFor(docs.path, sessionId);
        final leaked = docs
            .listSync()
            .whereType<File>()
            .where((f) => SegmentPaths.parseIndex(f.path, prefix) != null)
            .length;
        expect(
          leaked,
          segmentCount,
          reason: 'no source was cleaned up on this branch',
        );

        for (var launch = 0; launch < 2; launch++) {
          await repo.markCompleted(sessionId);
          await container.read(recoveryCoordinatorProvider).scanOnStartup();
          expect(
            (await repo.getById(sessionId))?.status,
            'crashed',
            reason: 'launch $launch still sees the leaked segments',
          );
        }
      },
    );

    test('a source deletion that permanently fails makes the misclassification '
        'permanent rather than racy', () async {
      final paths = await seedRecordedSession();
      await finalizeAndComplete(
        paths,
        deleteFn: (_) async =>
            throw const FileSystemException('delete refused'),
      );

      // Every launch from here on sees the same orphans.
      for (var launch = 0; launch < 2; launch++) {
        await repo.markCompleted(sessionId);
        await container.read(recoveryCoordinatorProvider).scanOnStartup();
        expect(
          (await repo.getById(sessionId))?.status,
          'crashed',
          reason: 'launch $launch re-offers a recording that finalized fine',
        );
      }
    });
  });
}
