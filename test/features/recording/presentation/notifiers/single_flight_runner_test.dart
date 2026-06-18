import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/single_flight_runner.dart';

void main() {
  test('drops overlapping runs while one is in flight (coalescing)', () async {
    var calls = 0;
    final gate = Completer<void>();
    final runner = SingleFlightRunner(() async {
      calls++;
      await gate.future;
    }, onError: (_, _) {});

    runner.run();
    runner.run();
    runner.run();
    await Future<void>.delayed(Duration.zero);

    expect(calls, 1, reason: 'only one run may be outstanding at a time');

    gate.complete();
    await Future<void>.delayed(Duration.zero);

    runner.run();
    await Future<void>.delayed(Duration.zero);
    expect(calls, 2, reason: 'a new run is allowed once the prior one settles');
  });

  test('routes errors to onError instead of dropping them', () async {
    Object? captured;
    final runner = SingleFlightRunner(
      () async => throw StateError('boom'),
      onError: (e, _) => captured = e,
    );

    runner.run();
    await Future<void>.delayed(Duration.zero);

    expect(captured, isA<StateError>());
  });

  test(
    'a later run still reports its own error after an earlier success',
    () async {
      final errors = <Object>[];
      var shouldThrow = false;
      final runner = SingleFlightRunner(() async {
        if (shouldThrow) throw StateError('late boom');
      }, onError: (e, _) => errors.add(e));

      runner.run();
      await Future<void>.delayed(Duration.zero);
      expect(errors, isEmpty);

      shouldThrow = true;
      runner.run();
      await Future<void>.delayed(Duration.zero);
      expect(errors, hasLength(1));
    },
  );
}
