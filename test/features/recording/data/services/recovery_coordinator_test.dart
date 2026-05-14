import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/database/database_provider.dart';
import 'package:oral_collector/features/recording/data/services/recovery_coordinator.dart';
import 'package:oral_collector/features/recording/data/repositories/recording_session_repository.dart';

void main() {
  late AppDatabase db;
  late RecordingSessionRepository repo;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RecordingSessionRepository(db);
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> seedSession({
    required String id,
    required String status,
    required DateTime startedAt,
    List<String> segmentPaths = const [],
    double totalDurationSeconds = 0.0,
    int lastSegmentIndex = -1,
  }) async {
    await repo.insertSession(
      RecordingSessionsCompanion.insert(
        id: id,
        projectId: 'proj-1',
        genreId: 'genre-1',
        startedAt: startedAt,
        status: Value(status),
        segmentPathsJson: segmentPaths.isEmpty
            ? const Value.absent()
            : Value(jsonEncode(segmentPaths)),
        totalDurationSeconds: Value(totalDurationSeconds),
        lastSegmentIndex: Value(lastSegmentIndex),
      ),
    );
  }

  group('RecordingSessionRepository.findCrashedSessions', () {
    test('returns only crashed sessions ordered by startedAt desc', () async {
      await seedSession(
        id: 'older-crashed',
        status: 'crashed',
        startedAt: DateTime(2026, 5, 10, 9, 0),
        segmentPaths: ['/p1.wav'],
      );
      await seedSession(
        id: 'completed',
        status: 'completed',
        startedAt: DateTime(2026, 5, 11),
        segmentPaths: ['/p2.wav'],
      );
      await seedSession(
        id: 'newer-crashed',
        status: 'crashed',
        startedAt: DateTime(2026, 5, 12, 14, 0),
        segmentPaths: ['/p3.wav'],
      );

      final result = await repo.findCrashedSessions();
      expect(result.map((s) => s.id).toList(), [
        'newer-crashed',
        'older-crashed',
      ]);
    });
  });

  group('RecordingSessionRepository.markActive', () {
    test('flips a crashed session back to active', () async {
      await seedSession(
        id: 'sess-1',
        status: 'crashed',
        startedAt: DateTime(2026, 5, 12),
      );

      await repo.markActive('sess-1');

      final session = await repo.getById('sess-1');
      expect(session?.status, 'active');
    });
  });

  group('RecoveryCoordinator', () {
    test('scanOnStartup marks active sessions as crashed', () async {
      await seedSession(
        id: 'orphaned',
        status: 'active',
        startedAt: DateTime(2026, 5, 12),
        segmentPaths: ['/p.wav'],
      );

      final coordinator = container.read(recoveryCoordinatorProvider);
      await coordinator.scanOnStartup();

      final session = await repo.getById('orphaned');
      expect(session?.status, 'crashed');
    });

    test(
      'refresh populates interruptedSessionsProvider with crashed sessions '
      'having at least one segment',
      () async {
        await seedSession(
          id: 'with-segments',
          status: 'crashed',
          startedAt: DateTime(2026, 5, 12),
          segmentPaths: ['/a.wav', '/b.wav'],
          totalDurationSeconds: 120.0,
          lastSegmentIndex: 1,
        );
        await seedSession(
          id: 'no-segments',
          status: 'crashed',
          startedAt: DateTime(2026, 5, 11),
        );

        final coordinator = container.read(recoveryCoordinatorProvider);
        await coordinator.refresh();

        final list = container.read(interruptedSessionsProvider);
        expect(list.length, 1);
        expect(list.first.sessionId, 'with-segments');
        expect(list.first.segmentCount, 2);
        expect(list.first.totalDuration, const Duration(seconds: 120));

        final noSegments = await repo.getById('no-segments');
        expect(
          noSegments?.status,
          'discarded',
          reason: 'zero-segment crashed sessions should be auto-discarded',
        );
      },
    );

    test('refresh sorts sessions by startedAt desc', () async {
      await seedSession(
        id: 'old',
        status: 'crashed',
        startedAt: DateTime(2026, 5, 10, 8, 0),
        segmentPaths: ['/o.wav'],
      );
      await seedSession(
        id: 'new',
        status: 'crashed',
        startedAt: DateTime(2026, 5, 12, 17, 0),
        segmentPaths: ['/n.wav'],
      );

      final coordinator = container.read(recoveryCoordinatorProvider);
      await coordinator.refresh();

      final list = container.read(interruptedSessionsProvider);
      expect(list.map((s) => s.sessionId).toList(), ['new', 'old']);
    });
  });
}
