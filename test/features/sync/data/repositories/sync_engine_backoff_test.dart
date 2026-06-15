/// Tests for the jittered retry backoff policy used by the sync engine.
///
/// Jitter de-synchronizes retries across devices that failed at the same time
/// (e.g. when a server outage clears), so the contract under test is a range,
/// not a single value: the delay never drops below the base rung and never
/// exceeds it by more than the jitter fraction.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/sync/data/repositories/sync_engine.dart';

void main() {
  // Base rung (milliseconds) keyed by 1-based attempt number, one entry per
  // distinct ladder rung. Saturation past the ladder is covered separately.
  const baseMsByAttempt = {1: 5000, 2: 15000, 3: 30000, 4: 60000};

  group('backoffWithJitter', () {
    test('stays within [base, 1.5x base] for every attempt', () {
      final random = Random(12345);
      baseMsByAttempt.forEach((attempt, baseMs) {
        final maxMs = (baseMs * 1.5).round();
        for (var i = 0; i < 1000; i++) {
          final ms = backoffWithJitter(attempt, random).inMilliseconds;
          expect(
            ms,
            inInclusiveRange(baseMs, maxMs),
            reason:
                'attempt $attempt produced ${ms}ms outside [$baseMs, $maxMs]',
          );
        }
      });
    });

    test('applies real jitter — produces more than one distinct delay', () {
      final random = Random(42);
      final seen = <int>{};
      for (var i = 0; i < 100; i++) {
        seen.add(backoffWithJitter(1, random).inMilliseconds);
      }
      expect(seen.length, greaterThan(1));
    });

    test('saturates at the last rung for attempts beyond the ladder', () {
      final random = Random(7);
      for (var i = 0; i < 200; i++) {
        expect(
          backoffWithJitter(9, random).inMilliseconds,
          inInclusiveRange(60000, 90000),
        );
      }
    });
  });
}
