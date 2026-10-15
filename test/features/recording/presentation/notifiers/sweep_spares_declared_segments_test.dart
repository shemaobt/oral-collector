/// ENG-531: the orphan sweep never deletes a file the session declares as its
/// own.
///
/// The sweep decided by the **index in the file name**: everything above the
/// session's `lastSegmentIndex` was an orphan. That assumes the recorded index
/// and the names move together, and they do not — `_repairInFlightSegments`
/// attaches the orphans it finds by *incrementing* the counter instead of
/// using the name's index, so one unrepairable orphan in the middle leaves
/// every later name above the counter. The file the repair just accepted lands
/// in the deletion range and is erased by the very flow that accepted it.
///
/// Every case lays out real files in a temp directory, drives the production
/// flow through its public entry point, and looks at the disk afterwards. None
/// asserts on indices, ranges, or how the sweep decides.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/database/database_provider.dart';
import 'package:oral_collector/features/recording/data/repositories/recording_session_repository.dart';
import 'package:oral_collector/features/recording/data/services/recovery_coordinator.dart';
import 'package:oral_collector/features/recording/data/services/recovery_disk.dart';
import 'package:oral_collector/features/recording/data/services/segment_paths.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/interrupted_sessions_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory docs;
  late AppDatabase db;
  late RecordingSessionRepository sessions;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    docs = await Directory.systemTemp.createTemp('eng531_sweep_');

    // The sweeps list the *current* documents directory, so the production
    // lookup has to land in this temp directory.
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => docs.path);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    db = AppDatabase.forTesting(NativeDatabase.memory());
    sessions = RecordingSessionRepository(db);
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        recoveryCoordinatorProvider.overrideWith(
          (ref) => RecoveryCoordinator(
            ref,
            disk: RecoveryDisk(documentsPath: () async => docs.path),
          ),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    if (docs.existsSync()) docs.deleteSync(recursive: true);
  });

  String segment(String sessionId, int index) =>
      SegmentPaths.forSegment(docs.path, sessionId, index);

  /// An in-flight WAV the repair can finish: real header, placeholder sizes,
  /// one second of PCM — what an interrupted `record` session leaves behind.
  Future<void> writeRepairableWav(String path) async {
    final header = BytesBuilder()
      ..add(const AsciiEncoder().convert('RIFF'))
      ..add(Uint8List(4))
      ..add(const AsciiEncoder().convert('WAVE'))
      ..add(const AsciiEncoder().convert('fmt '))
      ..add(Uint8List(4)..buffer.asByteData().setUint32(0, 16, Endian.little))
      ..add(Uint8List(2)..buffer.asByteData().setUint16(0, 1, Endian.little))
      ..add(Uint8List(2)..buffer.asByteData().setUint16(0, 1, Endian.little))
      ..add(
        Uint8List(4)..buffer.asByteData().setUint32(0, 16000, Endian.little),
      )
      ..add(
        Uint8List(4)..buffer.asByteData().setUint32(0, 32000, Endian.little),
      )
      ..add(Uint8List(2)..buffer.asByteData().setUint16(0, 2, Endian.little))
      ..add(Uint8List(2)..buffer.asByteData().setUint16(0, 16, Endian.little))
      ..add(const AsciiEncoder().convert('data'))
      ..add(Uint8List(4));
    await File(path).writeAsBytes([...header.toBytes(), ...Uint8List(32000)]);
  }

  /// A file the repair cannot make sense of, which it deletes instead of
  /// attaching. This is the hole in the numbering.
  Future<void> writeUnrepairableFile(String path) =>
      File(path).writeAsString('not a wav at all');

  Future<void> seedSession(
    String sessionId, {
    required List<String> declared,
    required int lastSegmentIndex,
    String status = 'active',
  }) async {
    await sessions.insertSession(
      RecordingSessionsCompanion.insert(
        id: sessionId,
        projectId: 'proj-1',
        genreId: 'genre-1',
        subcategoryId: const Value('sub-1'),
        startedAt: DateTime(2026, 8, 12),
        status: Value(status),
        segmentPathsJson: Value(jsonEncode(declared)),
        totalDurationSeconds: Value(declared.length.toDouble()),
        lastSegmentIndex: Value(lastSegmentIndex),
      ),
    );
  }

  Future<bool> load(String sessionId) => container
      .read(recordingSessionNotifierProvider.notifier)
      .loadInterruptedSession(sessionId);

  group('ENG-531: the sweep spares what the session declares', () {
    test('a segment the repair just attached survives the load', () async {
      // The reproduced scenario: 000 declared, 001 unrepairable, 002 fine.
      // The repair drops 001 and attaches 002 by bumping the counter to 1, so
      // 002's own name (index 2) now sits above the counter and the load's
      // sweep reads it as an orphan.
      await seedSession(
        'sess-hole',
        declared: [segment('sess-hole', 0)],
        lastSegmentIndex: 0,
      );
      await writeRepairableWav(segment('sess-hole', 0));
      await writeUnrepairableFile(segment('sess-hole', 1));
      await writeRepairableWav(segment('sess-hole', 2));

      await container.read(recoveryCoordinatorProvider).scanOnStartup();
      expect(
        sessions.decodeSegmentPaths((await sessions.getById('sess-hole'))!),
        contains(segment('sess-hole', 2)),
        reason: 'the repair has to have attached it for this to mean anything',
      );

      await load('sess-hole');

      expect(File(segment('sess-hole', 0)).existsSync(), isTrue);
      expect(
        File(segment('sess-hole', 2)).existsSync(),
        isTrue,
        reason: 'the session declares it; the housekeeping does not get a vote',
      );
    });

    test('a file nobody declares is still swept away', () async {
      // The net that stops the fix from turning the housekeeping off.
      await seedSession(
        'sess-litter',
        declared: [segment('sess-litter', 0)],
        lastSegmentIndex: 0,
        status: 'crashed',
      );
      await writeRepairableWav(segment('sess-litter', 0));
      await File(segment('sess-litter', 5)).writeAsString('nobody claims me');

      await load('sess-litter');

      expect(File(segment('sess-litter', 0)).existsSync(), isTrue);
      expect(File(segment('sess-litter', 5)).existsSync(), isFalse);
    });

    test('a session whose numbering never diverged is untouched', () async {
      await seedSession(
        'sess-plain',
        declared: [segment('sess-plain', 0), segment('sess-plain', 1)],
        lastSegmentIndex: 1,
        status: 'crashed',
      );
      await writeRepairableWav(segment('sess-plain', 0));
      await writeRepairableWav(segment('sess-plain', 1));

      await load('sess-plain');

      expect(File(segment('sess-plain', 0)).existsSync(), isTrue);
      expect(File(segment('sess-plain', 1)).existsSync(), isTrue);
    });

    test(
      'discarding still erases everything, declared segments included',
      () async {
        // The other copy of the sweep is only ever asked to erase, and it has to
        // keep doing exactly that — applying the spare-the-declared rule there
        // would preserve the very files the person asked to delete. The declared
        // paths here point at a container that no longer exists (ENG-528), so
        // the discard's own per-path delete finds nothing and the sweep of the
        // current directory is the only thing standing between the person and
        // audio they asked to be rid of.
        const oldContainer = '/var/mobile/Containers/Data/Application/OLD/docs';
        await seedSession(
          'sess-gone',
          declared: [
            '$oldContainer/rec_sess-gone_000.wav',
            '$oldContainer/rec_sess-gone_002.wav',
          ],
          lastSegmentIndex: 1,
          status: 'crashed',
        );
        await writeRepairableWav(segment('sess-gone', 0));
        await writeRepairableWav(segment('sess-gone', 2));
        await File(segment('sess-gone', 5)).writeAsString('orphan');

        await container
            .read(interruptedSessionsNotifierProvider.notifier)
            .discard('sess-gone');

        expect(File(segment('sess-gone', 0)).existsSync(), isFalse);
        expect(File(segment('sess-gone', 2)).existsSync(), isFalse);
        expect(File(segment('sess-gone', 5)).existsSync(), isFalse);
      },
    );
  });
}
