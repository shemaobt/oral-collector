import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/presentation/widgets/seek_wave.dart';

const _twelveMinutes = Duration(minutes: 12);

Future<List<Duration>> _pump(
  WidgetTester tester, {
  Duration position = const Duration(minutes: 6),
  Duration duration = _twelveMinutes,
  TextDirection direction = TextDirection.ltr,
  TargetPlatform platform = TargetPlatform.android,
}) async {
  final asked = <Duration>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: platform),
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 64,
              child: SeekWave(
                position: position,
                duration: duration,
                onSeek: asked.add,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return asked;
}

Offset _at(WidgetTester tester, double fraction) {
  final rect = tester.getRect(find.byType(SeekWave));
  return Offset(rect.left + rect.width * fraction, rect.center.dy);
}

void main() {
  group('tap', () {
    testWidgets('asks for the point under the finger', (tester) async {
      final asked = await _pump(tester);
      await tester.tapAt(_at(tester, 0.5));
      await tester.tapAt(_at(tester, 0.25));
      expect(asked, [const Duration(minutes: 6), const Duration(minutes: 3)]);
    });

    testWidgets('counts from the right in right-to-left', (tester) async {
      final asked = await _pump(tester, direction: TextDirection.rtl);
      await tester.tapAt(_at(tester, 0.25));
      expect(asked, [const Duration(minutes: 9)]);
    });

    testWidgets('takes a tap above the 28 px of the wave', (tester) async {
      final asked = await _pump(tester);
      final rect = tester.getRect(find.byType(SeekWave));
      await tester.tapAt(Offset(rect.center.dx, rect.top + 2));
      expect(asked, [const Duration(minutes: 6)]);
    });

    testWidgets('asks for nothing without a duration', (tester) async {
      final asked = await _pump(tester, duration: Duration.zero);
      await tester.tapAt(_at(tester, 0.5));
      expect(asked, isEmpty);
    });
  });

  testWidgets('a horizontal drag asks for nothing', (tester) async {
    final asked = await _pump(tester);
    await tester.dragFrom(_at(tester, 0.2), const Offset(200, 0));
    expect(asked, isEmpty);
  });

  group('screen reader', () {
    testWidgets('reads the position as a percentage', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      final data = tester
          .getSemantics(find.byType(SeekWave))
          .getSemanticsData();
      expect(data.value, '50%');
      expect(data.increasedValue, '55%');
      expect(data.decreasedValue, '45%');
      handle.dispose();
    });

    testWidgets('steps 10% on iOS', (tester) async {
      final handle = tester.ensureSemantics();
      final asked = await _pump(tester, platform: TargetPlatform.iOS);
      tester.semantics.increase(
        find.semantics.byAction(SemanticsAction.increase),
      );
      tester.semantics.decrease(
        find.semantics.byAction(SemanticsAction.decrease),
      );
      expect(asked, [
        const Duration(minutes: 7, seconds: 12),
        const Duration(minutes: 4, seconds: 48),
      ]);
      handle.dispose();
    });

    testWidgets('steps 5% on Android', (tester) async {
      final handle = tester.ensureSemantics();
      final asked = await _pump(tester);
      tester.semantics.increase(
        find.semantics.byAction(SemanticsAction.increase),
      );
      tester.semantics.decrease(
        find.semantics.byAction(SemanticsAction.decrease),
      );
      expect(asked, [
        const Duration(minutes: 6, seconds: 36),
        const Duration(minutes: 5, seconds: 24),
      ]);
      handle.dispose();
    });

    testWidgets('stops at the start and at the end', (tester) async {
      final handle = tester.ensureSemantics();
      var asked = await _pump(tester, position: Duration.zero);
      tester.semantics.decrease(
        find.semantics.byAction(SemanticsAction.decrease),
      );
      expect(asked, [Duration.zero]);
      asked = await _pump(tester, position: _twelveMinutes);
      tester.semantics.increase(
        find.semantics.byAction(SemanticsAction.increase),
      );
      expect(asked, [_twelveMinutes]);
      handle.dispose();
    });
  });

  group('keyboard', () {
    for (final (direction, first, second) in [
      (
        TextDirection.ltr,
        const Duration(minutes: 6, seconds: 36),
        const Duration(minutes: 5, seconds: 24),
      ),
      (
        TextDirection.rtl,
        const Duration(minutes: 5, seconds: 24),
        const Duration(minutes: 6, seconds: 36),
      ),
    ]) {
      testWidgets('right then left in $direction', (tester) async {
        final asked = await _pump(tester, direction: direction);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        expect(asked, [first, second]);
      });
    }
  });
}
