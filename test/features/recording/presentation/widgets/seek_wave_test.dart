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
  for (final (name, direction, fraction, top, expected) in [
    ('middle', TextDirection.ltr, 0.5, 32.0, const Duration(minutes: 6)),
    ('quarter', TextDirection.ltr, 0.25, 32.0, const Duration(minutes: 3)),
    ('RTL quarter', TextDirection.rtl, 0.25, 32.0, const Duration(minutes: 9)),
    ('top edge', TextDirection.ltr, 0.5, 2.0, const Duration(minutes: 6)),
    ('start', TextDirection.ltr, 0.0, 32.0, Duration.zero),
  ]) {
    testWidgets('tap at $name asks $expected', (t) async {
      final asked = await _pump(t, direction: direction);
      await t.tapAt(_at(t, fraction, top: top));
      expect(asked, [expected]);
    });
  }

  testWidgets('a horizontal drag asks for nothing', (tester) async {
    final asked = await _pump(tester);
    await tester.dragFrom(_at(tester, 0.2), const Offset(200, 0));
    expect(asked, isEmpty);
  });

  for (final (position, action) in [
    (Duration.zero, SemanticsAction.decrease),
    (_twelveMinutes, SemanticsAction.increase),
  ]) {
    testWidgets('the reader asks nothing at $position', (tester) async {
      final handle = tester.ensureSemantics();
      final asked = await _pump(tester, position: position);
      tester.semantics.performAction(find.semantics.byAction(action), action);
      expect(asked, isEmpty);
      handle.dispose();
    });
  }

  for (final (platform, direction, step) in [
    (TargetPlatform.iOS, TextDirection.ltr, 0.1),
    (TargetPlatform.macOS, TextDirection.rtl, 0.1),
    (TargetPlatform.android, TextDirection.ltr, 0.05),
    (TargetPlatform.android, TextDirection.rtl, 0.05),
  ]) {
    testWidgets('steps, keys, label on $platform $direction', (tester) async {
      final handle = tester.ensureSemantics();
      final asked = await _pump(
        tester,
        position: const Duration(minutes: 6),
        direction: direction,
        wrap: (wave) => Semantics(
          label: 'Tocador',
          child: Theme(
            data: ThemeData(platform: platform),
            child: wave,
          ),
        ),
      );
      expect(_semantics(tester).value, '50%');
      expect(_semantics(tester).label, isEmpty);
      for (final action in [
        SemanticsAction.increase,
        SemanticsAction.decrease,
      ]) {
        tester.semantics.performAction(find.semantics.byAction(action), action);
      }
      Focus.of(tester.element(find.byType(LayoutBuilder))).requestFocus();
      await tester.pump();
      final ltr = direction == TextDirection.ltr;
      for (final key in [
        ltr ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft,
        ltr ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowDown,
      ]) {
        await tester.sendKeyEvent(key);
      }
      final delta = _twelveMinutes * step;
      const six = Duration(minutes: 6);
      expect(asked, [
        for (var i = 0; i < 3; i++) ...[six + delta, six - delta],
      ]);
      handle.dispose();
    });
  }

  testWidgets('zero duration is disabled, key downs pass', (tester) async {
    final handle = tester.ensureSemantics();
    final received = <LogicalKeyboardKey>[];
    final asked = await _pump(
      tester,
      duration: Duration.zero,
      wrap: (wave) => Focus(
        autofocus: true,
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent) received.add(event.logicalKey);
          return KeyEventResult.ignored;
        },
        child: wave,
      ),
    );
    expect(_semantics(tester).flagsCollection.isEnabled, Tristate.isFalse);
    Focus.of(tester.element(find.byType(LayoutBuilder))).requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    expect(received, [LogicalKeyboardKey.arrowRight]);
    expect(asked, isEmpty);
    handle.dispose();
  });

  testWidgets('an unbounded width fails loudly', (tester) async {
    await _pump(
      tester,
      wrap: (wave) =>
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: wave),
    );
    expect(tester.takeException(), isA<FlutterError>());
  });
}
