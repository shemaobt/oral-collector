import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/core/theme/app_motion.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/shared/widgets/quick_notice.dart';

const _heldFor = Duration(milliseconds: 2900);

MaterialApp _app({required Widget home, Brightness? brightness}) => MaterialApp(
  locale: const Locale('pt'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  theme: ThemeData(brightness: brightness ?? Brightness.light),
  home: home,
);

Future<void> _pump(
  WidgetTester tester, {
  bool still = false,
  ValueChanged<int>? onUndo,
  String? word,
  QuickNoticeTone tone = QuickNoticeTone.calm,
  Brightness? brightness,
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: still);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  var count = 0;
  await tester.pumpWidget(
    _app(
      brightness: brightness,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () {
            final n = ++count;
            showQuickNotice(
              context,
              'Saved $n',
              tone: tone,
              action: switch ((onUndo, word)) {
                (null, _) => null,
                (final f?, null) => QuickNoticeAction.undo(() => f(n)),
                (final f?, final w?) => QuickNoticeAction(w, () => f(n)),
              },
            );
          },
          child: const Text('show'),
        ),
      ),
    ),
  );
}

Future<void> _show(WidgetTester tester) async {
  await tester.tap(find.text('show'));
  await tester.pump();
  while (tester.binding.hasScheduledFrame) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

void main() {
  for (final still in [false, true]) {
    testWidgets('a notice stays, then leaves by itself'
        '${still ? ' with reduced motion' : ''}', (tester) async {
      await _pump(tester, still: still);

      await _show(tester);
      for (var i = 0; i < 29; i++) {
        await tester.pump(_heldFor ~/ 29);
      }
      expect(find.text('Saved 1'), findsOneWidget);

      await tester.pump(MotionScale.noticeStay - _heldFor);
      await tester.pumpAndSettle();
      expect(find.text('Saved 1'), findsNothing);
    });
  }

  testWidgets('a new notice replaces the one on screen, even as it leaves', (
    tester,
  ) async {
    final live = <Object>{};
    void track(ObjectEvent e) =>
        e is ObjectCreated ? live.add(e.object) : live.remove(e.object);

    await _pump(tester);
    FlutterMemoryAllocations.instance.addListener(track);
    addTearDown(() => FlutterMemoryAllocations.instance.removeListener(track));
    await _show(tester);
    await _show(tester);
    expect(find.text('Saved 1'), findsNothing);
    expect(find.text('Saved 2'), findsOneWidget);

    await tester.pump(MotionScale.noticeStay);
    await tester.pump(MotionScale.fast - const Duration(milliseconds: 1));
    await tester.tap(find.text('show'));
    await tester.pump(const Duration(milliseconds: 2));
    expect(find.text('Saved 3'), findsOneWidget);

    await tester.pumpAndSettle();
    await tester.pump(MotionScale.noticeStay);
    await tester.pumpAndSettle();
    expect(live.whereType<OverlayEntry>(), isEmpty);
  });

  testWidgets(
    'a notice shown from a route that is gone still leaves by itself',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(navigatorKey: navigator, home: const Text('home')),
      );
      Route<void> page(String name) => MaterialPageRoute(
        builder: (context) => TextButton(
          onPressed: () => showQuickNotice(context, 'Saved'),
          child: Text(name),
        ),
      );

      unawaited(navigator.currentState!.push(page('first')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('first'));
      await tester.pumpAndSettle();

      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      unawaited(navigator.currentState!.push(page('second')));
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsOneWidget);

      await tester.pump(MotionScale.noticeStay);
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsNothing);
    },
  );

  testWidgets('a tap on the action calls it once and the notice leaves', (
    tester,
  ) async {
    final undone = <int>[];
    await _pump(tester, onUndo: undone.add, word: 'Ver');
    await _show(tester);

    await tester.tap(find.text('Ver'));
    await tester.tap(find.text('Ver'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(undone, [1]);
    expect(find.text('Saved 1'), findsNothing);
  });

  testWidgets('a notice with undo stays 6 s and never calls undo by itself', (
    tester,
  ) async {
    final undone = <int>[];
    await _pump(tester, onUndo: undone.add);
    await _show(tester);

    for (var i = 0; i < 59; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Saved 1'), findsOneWidget);
    expect(find.text('Desfazer'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('Saved 1'), findsNothing);
    expect(undone, isEmpty);
  });

  testWidgets('the undo of a replaced notice can no longer be called', (
    tester,
  ) async {
    final undone = <int>[];
    await _pump(tester, onUndo: undone.add);
    await _show(tester);
    await _show(tester);

    expect(find.text('Desfazer'), findsOneWidget);
    await tester.tap(find.text('Desfazer'));
    await tester.pumpAndSettle();
    expect(undone, [2]);
    expect(find.text('Saved 2'), findsNothing);
  });

  for (final ms in [100, 1500]) {
    testWidgets('a downward swipe over $ms ms sends the notice away', (
      tester,
    ) async {
      await _pump(tester);
      await _show(tester);

      final swipe = Duration(milliseconds: ms);
      await tester.timedDrag(find.text('Saved 1'), const Offset(0, 70), swipe);
      await tester.pumpAndSettle(const Duration(milliseconds: 10));

      expect(find.text('Saved 1'), findsNothing);
    });
  }

  group('the action reads in the kit colours', () {
    final cases = {
      'calm in light': (
        Brightness.light,
        QuickNoticeTone.calm,
        AppColors.light.sand,
      ),
      'failed in light': (
        Brightness.light,
        QuickNoticeTone.failed,
        AppColors.background,
      ),
      'calm in dark': (
        Brightness.dark,
        QuickNoticeTone.calm,
        AppColors.darkPale,
      ),
      'failed in dark': (
        Brightness.dark,
        QuickNoticeTone.failed,
        AppColors.darkPale,
      ),
    };
    for (final MapEntry(key: name, value: (brightness, tone, color))
        in cases.entries) {
      testWidgets(
        '$name, 15 at weight 600, its own button 44 high in a bar 52 high',
        (tester) async {
          final semantics = tester.ensureSemantics();
          await _pump(
            tester,
            onUndo: (_) {},
            tone: tone,
            brightness: brightness,
          );
          await _show(tester);

          final style = tester.widget<Text>(find.text('Desfazer')).style!;
          expect(style.color, color);
          expect(style.fontSize, 15);
          expect(style.fontWeight, FontWeight.w600);
          final action = tester.getSemantics(find.text('Desfazer'));
          expect(action.flagsCollection.isButton, isTrue);
          expect(action.rect.height, 44);
          final bar = find.ancestor(
            of: find.text('Saved 1'),
            matching: find.byType(CustomPaint),
          );
          expect(tester.getSize(bar.first).height, 52);
          await tester.pump(MotionScale.noticeStayAction);
          await tester.pumpAndSettle();
          semantics.dispose();
        },
      );
    }
  });

  testWidgets('screen readers hear the sentence when the notice arrives', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    await _show(tester);

    final node = tester.getSemantics(find.bySemanticsLabel('Saved 1'));
    expect(node.flagsCollection.isLiveRegion, isTrue);

    await tester.pump(MotionScale.noticeStay);
    await tester.pumpAndSettle();
    handle.dispose();
  });
}
