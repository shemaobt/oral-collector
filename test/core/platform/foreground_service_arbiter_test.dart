import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/platform/foreground_service_arbiter.dart';

class _FakeService {
  _FakeService({this.running = false});

  bool running;
  final List<String> calls = [];

  /// When set, [stop] blocks on it — used to hold a take-over mid-flight.
  Completer<void>? stopGate;

  Future<bool> isRunning() async => running;

  Future<void> stop() async {
    calls.add('stop');
    final gate = stopGate;
    if (gate != null) await gate.future;
    running = false;
  }

  Future<void> start(String label) async {
    calls.add('start:$label');
    running = true;
  }
}

Future<void> _takeOver(
  _FakeService svc,
  ForegroundServiceOwner owner,
  String label,
) {
  return ForegroundServiceArbiter.takeOver(
    owner: owner,
    isRunning: svc.isRunning,
    stop: svc.stop,
    start: () => svc.start(label),
  );
}

Future<void> _release(_FakeService svc, ForegroundServiceOwner owner) {
  return ForegroundServiceArbiter.release(
    owner: owner,
    isRunning: svc.isRunning,
    stop: svc.stop,
  );
}

void main() {
  setUp(ForegroundServiceArbiter.resetForTest);

  group('ForegroundServiceArbiter', () {
    test(
      'takeOver stops a running service, starts the new one, records owner',
      () async {
        final svc = _FakeService(running: true);

        await _takeOver(svc, ForegroundServiceOwner.recording, 'recording');

        expect(svc.calls, ['stop', 'start:recording']);
        expect(svc.running, isTrue);
        expect(
          ForegroundServiceArbiter.owner,
          ForegroundServiceOwner.recording,
        );
      },
    );

    test('takeOver skips the stop when nothing is running', () async {
      final svc = _FakeService(running: false);

      await _takeOver(svc, ForegroundServiceOwner.upload, 'upload');

      expect(svc.calls, ['start:upload']);
      expect(ForegroundServiceArbiter.owner, ForegroundServiceOwner.upload);
    });

    test('release stops the service when the caller still owns it', () async {
      final svc = _FakeService(running: true);
      await _takeOver(svc, ForegroundServiceOwner.upload, 'upload');
      svc.calls.clear();

      await _release(svc, ForegroundServiceOwner.upload);

      expect(svc.calls, ['stop']);
      expect(svc.running, isFalse);
      expect(ForegroundServiceArbiter.owner, ForegroundServiceOwner.none);
    });

    test('release is a no-op when another feature has taken over', () async {
      final svc = _FakeService(running: true);
      await _takeOver(svc, ForegroundServiceOwner.recording, 'recording');
      svc.calls.clear();

      await _release(svc, ForegroundServiceOwner.upload);

      expect(svc.calls, isEmpty);
      expect(svc.running, isTrue);
      expect(ForegroundServiceArbiter.owner, ForegroundServiceOwner.recording);
    });

    test(
      'recording takes over an active upload; a late upload release leaves '
      'recording running (bug: notification did not switch to recording)',
      () async {
        final svc = _FakeService(running: true);
        await _takeOver(svc, ForegroundServiceOwner.upload, 'upload');
        svc.calls.clear();

        await _takeOver(svc, ForegroundServiceOwner.recording, 'recording');
        expect(svc.calls, ['stop', 'start:recording']);
        expect(
          ForegroundServiceArbiter.owner,
          ForegroundServiceOwner.recording,
        );
        svc.calls.clear();

        await _release(svc, ForegroundServiceOwner.upload);

        expect(svc.calls, isEmpty);
        expect(svc.running, isTrue);
        expect(
          ForegroundServiceArbiter.owner,
          ForegroundServiceOwner.recording,
        );
      },
    );

    test(
      'upload takes over after recording; a late recording release leaves '
      'upload running (bug: upload notification did not return after discard)',
      () async {
        final svc = _FakeService(running: true);
        await _takeOver(svc, ForegroundServiceOwner.recording, 'recording');
        svc.calls.clear();

        await _takeOver(svc, ForegroundServiceOwner.upload, 'upload');
        expect(svc.calls, ['stop', 'start:upload']);
        expect(ForegroundServiceArbiter.owner, ForegroundServiceOwner.upload);
        svc.calls.clear();

        await _release(svc, ForegroundServiceOwner.recording);

        expect(svc.calls, isEmpty);
        expect(svc.running, isTrue);
        expect(ForegroundServiceArbiter.owner, ForegroundServiceOwner.upload);
      },
    );

    test(
      'serializes operations: a release queued during a take-over runs after '
      'it, so it cannot tear down the service the take-over just claimed',
      () async {
        final svc = _FakeService(running: true);
        await _takeOver(svc, ForegroundServiceOwner.upload, 'upload');
        svc.calls.clear();

        // Hold the recording take-over mid-flight (blocked on its stop) and
        // queue an upload release behind it.
        final gate = Completer<void>();
        svc.stopGate = gate;

        final takeOver = _takeOver(
          svc,
          ForegroundServiceOwner.recording,
          'recording',
        );
        final release = _release(svc, ForegroundServiceOwner.upload);

        await Future<void>.delayed(Duration.zero);
        expect(svc.calls, ['stop']);

        svc.stopGate = null;
        gate.complete();
        await Future.wait([takeOver, release]);

        expect(
          ForegroundServiceArbiter.owner,
          ForegroundServiceOwner.recording,
        );
        expect(svc.running, isTrue);
        expect(svc.calls, ['stop', 'start:recording']);
      },
    );
  });
}
