import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/recording_session_repository.dart';
import 'package:oral_collector/features/recording/data/services/recording_finalization_service.dart';
import 'package:oral_collector/features/recording/data/services/recovery_coordinator.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/interrupted_sessions_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';

class _MockSessionRepo extends Mock implements RecordingSessionRepository {}

class _MockFinalizationService extends Mock
    implements RecordingFinalizationService {}

class _MockRecoveryCoordinator extends Mock implements RecoveryCoordinator {}

class _MockSession extends Mock implements RecordingSession {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String>[]);
    registerFallbackValue(Duration.zero);
  });

  late _MockSessionRepo repo;
  late _MockFinalizationService service;
  late _MockRecoveryCoordinator coordinator;
  late _MockSession session;
  late Directory tmp;
  late String segPath;

  setUp(() {
    repo = _MockSessionRepo();
    service = _MockFinalizationService();
    coordinator = _MockRecoveryCoordinator();
    session = _MockSession();

    tmp = Directory.systemTemp.createTempSync('interrupted_save_test_');
    segPath = '${tmp.path}/seg_0.m4a';
    File(segPath).writeAsBytesSync(const [0, 1, 2, 3]);

    when(() => session.id).thenReturn('s1');
    when(() => session.totalDurationSeconds).thenReturn(10.0);
    when(() => repo.getById('s1')).thenAnswer((_) async => session);
    when(() => repo.decodeSegmentPaths(session)).thenReturn([segPath]);
    when(() => repo.markRecovered(any())).thenAnswer((_) async {});
    when(() => repo.markDiscarded(any())).thenAnswer((_) async {});
    when(() => coordinator.refresh()).thenAnswer((_) async {});
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer() => ProviderContainer(
    overrides: [
      recordingSessionRepositoryProvider.overrideWithValue(repo),
      recordingFinalizationServiceProvider.overrideWithValue(service),
      recoveryCoordinatorProvider.overrideWithValue(coordinator),
    ],
  );

  void stubFinalizeThrows(Object error) {
    when(
      () => service.finalize(
        sessionId: any(named: 'sessionId'),
        segmentPaths: any(named: 'segmentPaths'),
        totalDuration: any(named: 'totalDuration'),
      ),
    ).thenThrow(error);
  }

  void stubFinalizeReturns(FinalizationOutcome? outcome) {
    when(
      () => service.finalize(
        sessionId: any(named: 'sessionId'),
        segmentPaths: any(named: 'segmentPaths'),
        totalDuration: any(named: 'totalDuration'),
      ),
    ).thenAnswer((_) async => outcome);
  }

  test('finalize throws: save does not rethrow, returns null, and keeps the '
      'session recoverable', () async {
    stubFinalizeThrows(Exception('ffmpeg failed'));

    final container = makeContainer();
    addTearDown(container.dispose);
    final notifier = container.read(
      interruptedSessionsNotifierProvider.notifier,
    );

    await expectLater(notifier.save('s1'), completion(isNull));
    verifyNever(() => repo.markRecovered(any()));
    verifyNever(() => repo.markDiscarded(any()));
    verify(() => coordinator.refresh()).called(1);
  });

  test(
    'finalize succeeds: marks the session recovered and returns the result',
    () async {
      final result = RecordingResult(
        filePath: '${tmp.path}/out.m4a',
        durationSeconds: 10,
      );
      stubFinalizeReturns(FinalizationOutcome(result: result));

      final container = makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(
        interruptedSessionsNotifierProvider.notifier,
      );

      final returned = await notifier.save('s1');

      expect(returned?.filePath, '${tmp.path}/out.m4a');
      verify(() => repo.markRecovered('s1')).called(1);
    },
  );

  test('finalize returns null without throwing: keeps the session recoverable '
      'instead of marking it recovered', () async {
    stubFinalizeReturns(null);

    final container = makeContainer();
    addTearDown(container.dispose);
    final notifier = container.read(
      interruptedSessionsNotifierProvider.notifier,
    );

    expect(await notifier.save('s1'), isNull);
    verifyNever(() => repo.markRecovered(any()));
  });
}
