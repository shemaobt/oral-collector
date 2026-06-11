import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/util/bounded_concurrency.dart';

void main() {
  test('preserves input order regardless of completion order', () async {
    // Earlier items resolve later, so a correct result must order by index.
    final results = await mapBounded<int, int>([0, 1, 2, 3, 4], 2, (n) async {
      await Future<void>.delayed(Duration(milliseconds: (5 - n) * 5));
      return n * 10;
    });
    expect(results, [0, 10, 20, 30, 40]);
  });

  test('never runs more than `limit` actions at once', () async {
    var active = 0;
    var maxActive = 0;
    var started = 0;
    final gate = Completer<void>();

    final future = mapBounded<int, int>(List.generate(10, (i) => i), 3, (
      n,
    ) async {
      started++;
      active++;
      if (active > maxActive) maxActive = active;
      await gate.future;
      active--;
      return n;
    });

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(maxActive, 3, reason: 'at most `limit` actions in flight');
    expect(
      started,
      3,
      reason: 'only `limit` actions start before any finishes',
    );

    gate.complete();
    expect(await future, List.generate(10, (i) => i));
    expect(maxActive, 3);
  });

  test('empty input yields empty output without invoking the action', () async {
    var called = false;
    final results = await mapBounded<int, int>([], 4, (n) async {
      called = true;
      return n;
    });
    expect(results, isEmpty);
    expect(called, isFalse);
  });

  test(
    'a limit larger than the item count still processes everything',
    () async {
      final results = await mapBounded<int, int>(
        [1, 2, 3],
        10,
        (n) async => n + 1,
      );
      expect(results, [2, 3, 4]);
    },
  );
}
