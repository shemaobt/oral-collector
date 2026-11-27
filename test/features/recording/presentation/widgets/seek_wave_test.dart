import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/presentation/widgets/seek_wave.dart';

const _twelveMinutes = Duration(minutes: 12);

Future<List<Duration>> _pump(
  WidgetTester tester, {
  Duration position = Duration.zero,
  Duration duration = _twelveMinutes,
  TextDirection direction = TextDirection.ltr,
  Widget Function(Widget wave)? wrap,
}) async {
  final asked = <Duration>[];
  final wave = SeekWave(
    position: position,
    duration: duration,
    onSeek: asked.add,
  );
  await tester.pumpWidget(
    Directionality(
      textDirection: direction,
      child: Material(
        child: Align(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 64),
            child: wrap == null ? wave : wrap(wave),
          ),
        ),
      ),
    ),
  );
  return asked;
}

Offset _at(WidgetTester tester, double fraction, {double top = 32}) {
  final rect = tester.getRect(find.byType(SeekWave));
  return Offset(rect.left + rect.width * fraction, rect.top + top);
}

SemanticsData _semantics(WidgetTester tester) =>
    tester.getSemantics(find.byType(SeekWave)).getSemanticsData();

void main() {
  for (final (direction, fraction, expected) in [
    (TextDirection.ltr, 0.5, const Duration(minutes: 6)),
    (TextDirection.ltr, 0.25, const Duration(minutes: 3)),
    (TextDirection.rtl, 0.25, const Duration(minutes: 9)),
  ]) {
    testWidgets('a tap at $fraction in $direction asks for $expected', (
      tester,
    ) async {
      final asked = await _pump(tester, direction: direction);
      await tester.tapAt(_at(tester, fraction));
      expect(asked, [expected]);
    });
  }

  testWidgets('the tap target is as tall as the parent allows', (tester) async {
    final asked = await _pump(tester);
    await tester.tapAt(_at(tester, 0.5, top: 2));
    expect(asked, [const Duration(minutes: 6)]);
  });

  testWidgets('a horizontal drag asks for nothing', (tester) async {
    final asked = await _pump(tester);
    await tester.dragFrom(_at(tester, 0.2), const Offset(200, 0));
    expect(asked, isEmpty);
  });

  testWidgets('the slider is its own node under a labelled ancestor', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      position: const Duration(minutes: 6),
      wrap: (wave) => Semantics(label: 'Tocador', child: wave),
    );
    final data = _semantics(tester);
    expect(data.value, '50%');
    expect(data.label, isEmpty);
    handle.dispose();
  });

  testWidgets('the screen reader asks for nothing at the edges', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final asked = await _pump(tester);
    tester.semantics.decrease(
      find.semantics.byAction(SemanticsAction.decrease),
    );
    asked.addAll(await _pump(tester, position: _twelveMinutes));
    tester.semantics.increase(
      find.semantics.byAction(SemanticsAction.increase),
    );
    expect(asked, isEmpty);
    handle.dispose();
  });

  testWidgets('a zero duration is disabled and takes no focus', (tester) async {
    final handle = tester.ensureSemantics();
    final asked = await _pump(tester, duration: Duration.zero);
    expect(_semantics(tester).flagsCollection.isEnabled, Tristate.isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    final inner = tester.element(
      find.descendant(
        of: find.byType(SeekWave),
        matching: find.byType(LayoutBuilder),
      ),
    );
    expect(Focus.of(inner).canRequestFocus, isFalse);
    expect(asked, isEmpty);
    handle.dispose();
  });

  testWidgets('an unbounded width fails loudly', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SeekWave(
            position: Duration.zero,
            duration: _twelveMinutes,
            onSeek: (_) {},
          ),
        ),
      ),
    );
    expect(tester.takeException(), isA<FlutterError>());
  });
}
