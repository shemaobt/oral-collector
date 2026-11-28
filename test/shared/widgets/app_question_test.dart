import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/shared/widgets/app_question.dart';

void main() {
  String? answer;

  Future<void> open(
    WidgetTester t, {
    bool isDismissible = true,
    bool still = false,
    bool settle = true,
    String title = 'Sair?',
    String message = 'Linha.',
    List<String> buttons = const ['Sim'],
  }) async {
    answer = null;
    await t.pumpWidget(
      MaterialApp(
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(disableAnimations: still),
          child: child!,
        ),
        home: Builder(
          builder: (c) => TextButton(
            onPressed: () async {
              answer = await showAppQuestion<String>(
                context: c,
                title: title,
                message: message,
                isDismissible: isDismissible,
                actionsBuilder: (ctx) => [
                  for (final b in buttons)
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, b),
                      child: Text(b),
                    ),
                ],
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pump();
    if (!still && settle) await t.pumpAndSettle();
  }

  testWidgets('gives the caller the answer that was tapped', (t) async {
    await open(t);
    expect(find.text('Linha.'), findsOneWidget);
    await t.tap(find.text('Sim'));
    await t.pumpAndSettle();
    expect(find.text('Sair?'), findsNothing);
    expect(answer, 'Sim');
  });

  for (final dismissible in [true, false]) {
    testWidgets('ground tap, dismissible $dismissible', (t) async {
      await open(t, isDismissible: dismissible);
      await t.tapAt(const Offset(10, 10));
      await t.pumpAndSettle();
      expect(find.text('Sair?'), dismissible ? findsNothing : findsOneWidget);
      expect(answer, isNull);
    });
  }

  testWidgets('less motion: whole at the first frame, gone at once', (t) async {
    await open(t, still: true);
    expect(t.widget<Opacity>(find.byType(Opacity).last).opacity, 1);
    await t.tap(find.text('Sim'));
    await t.pump();
    expect(find.text('Sair?'), findsNothing);
  });

  testWidgets('a pop mid-entrance reverses without a jump', (t) async {
    await open(t, settle: false);
    await t.pump(const Duration(milliseconds: 100));
    final double top = t.getTopLeft(find.text('Sair?')).dy;
    await t.tap(find.text('Sim'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 1));
    expect(t.getTopLeft(find.text('Sair?')).dy, closeTo(top, 0.5));
  });

  testWidgets('scrolls at 2.0x on 320x640', (t) async {
    t.view.physicalSize = const Size(960, 1920);
    t.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(t.view.reset);
    await open(
      t,
      title: 'Leave without saving?',
      buttons: ['Cancel', 'Keep', 'Discard'],
    );
    await t.ensureVisible(find.text('Discard'));
    expect(t.getRect(find.text('Discard')).bottom, lessThan(640));
  });

  testWidgets('the caller builder runs once per open', (t) async {
    var builds = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) => TextButton(
            onPressed: () => showAppDialog<void>(
              context: c,
              builder: (ctx) {
                builds++;
                return TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('fechar'),
                );
              },
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.tap(find.text('fechar'));
    await t.pumpAndSettle();
    expect(builds, 1);
  });

  testWidgets('the builder runs under the theme captured at the caller', (
    t,
  ) async {
    Color? seen;
    await t.pumpWidget(
      MaterialApp(
        home: Theme(
          data: ThemeData(primaryColor: const Color(0xFF123456)),
          child: Builder(
            builder: (c) => TextButton(
              onPressed: () => showAppDialog<void>(
                context: c,
                builder: (ctx) {
                  seen = Theme.of(ctx).primaryColor;
                  return const SizedBox();
                },
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(seen, const Color(0xFF123456));
  });
}
