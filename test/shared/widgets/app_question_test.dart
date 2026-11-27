import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/shared/widgets/app_question.dart';

void main() {
  String? answer;

  Future<void> open(
    WidgetTester t, {
    bool isDismissible = true,
    bool still = false,
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
    if (!still) await t.pumpAndSettle();
  }

  testWidgets('gives the caller the answer that was tapped', (t) async {
    await open(t);
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

  const asks = {
    'Leave without saving?': 'The audio is kept for later.',
    'Sair sem salvar?': 'O áudio fica guardado para depois.',
  };
  for (final ask in asks.entries) {
    testWidgets('${ask.key} scrolls at 2.0x on 320x640', (t) async {
      t.view.physicalSize = const Size(960, 1920);
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.view.reset);
      await open(
        t,
        title: ask.key,
        message: ask.value,
        buttons: ['Cancel', 'Keep for later', 'Discard'],
      );
      await t.ensureVisible(find.text('Discard'));
      expect(t.getRect(find.text('Discard')).bottom, lessThan(640));
    });
  }
}
