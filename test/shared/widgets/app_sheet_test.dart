import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/shared/widgets/app_sheet.dart';

void main() {
  final nested = GlobalKey<NavigatorState>();

  Future<void> open(
    WidgetTester t, {
    bool isDismissible = true,
    bool still = false,
    bool root = false,
    BoxConstraints? constraints,
    bool settle = true,
  }) async {
    t.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: still);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await t.pumpWidget(
      MaterialApp(
        home: Navigator(
          key: nested,
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (c) => TextButton(
              onPressed: () => showAppSheet<void>(
                context: c,
                isDismissible: isDismissible,
                useRootNavigator: root,
                constraints: constraints,
                builder: (_) => const SizedBox(
                  width: double.infinity,
                  height: 300,
                  child: Text('body'),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pump();
    if (!still && settle) await t.pumpAndSettle();
  }

  for (final bool dismissible in [true, false]) {
    final gestures = <String, Future<void> Function(WidgetTester)>{
      'drag': (t) => t.fling(find.text('body'), const Offset(0, 400), 2000),
      'ground tap': (t) => t.tapAt(const Offset(10, 10)),
    };
    for (final g in gestures.entries) {
      testWidgets('${g.key}, dismissible $dismissible', (t) async {
        await open(t, isDismissible: dismissible);
        await g.value(t);
        await t.pumpAndSettle();
        expect(find.text('body'), dismissible ? findsNothing : findsOneWidget);
      });
    }
  }
  for (final int grabAtMs in [0, 100]) {
    testWidgets('slow drag at ${grabAtMs}ms follows the finger', (t) async {
      await open(t, settle: grabAtMs == 0);
      await t.pump(Duration(milliseconds: grabAtMs));
      double top() => t.getTopLeft(find.text('body')).dy;
      final double start = top();
      final finger = await t.startGesture(t.getCenter(find.text('body')));
      await finger.moveBy(const Offset(0, 21));
      double moved = 0;
      for (final double step in [0, 60, 89]) {
        await t.pump(const Duration(milliseconds: 16));
        await finger.moveBy(Offset(0, step));
        await t.pump(const Duration(milliseconds: 16));
        expect(top() - start, closeTo(moved += step, 1));
      }
    });
  }
  testWidgets('less motion: whole at once, gone at once', (t) async {
    await open(t, still: true);
    expect(t.getTopLeft(find.text('body')).dy, 300);
    await t.tapAt(const Offset(10, 10));
    await t.pump();
    expect(find.text('body'), findsNothing);
  });

  testWidgets('constraints cap the sheet width', (t) async {
    await open(t, constraints: const BoxConstraints(maxWidth: 600));
    final sheet = find.ancestor(
      of: find.text('body'),
      matching: find.byType(Material),
    );
    expect(t.getSize(sheet.first).width, 600);
  });

  testWidgets('useRootNavigator pushes above the nested navigator', (t) async {
    await open(t, root: true);
    expect(find.text('body'), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(nested), matching: find.text('body')),
      findsNothing,
    );
  });

  testWidgets('the route is named for assistive tech', (t) async {
    final handle = t.ensureSemantics();
    await open(t);
    expect(find.bySemanticsLabel('Dialog'), findsOneWidget);
    handle.dispose();
  });
}
