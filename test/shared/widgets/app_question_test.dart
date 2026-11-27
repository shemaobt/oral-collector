import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_motion.dart';
import 'package:oral_collector/shared/widgets/app_question.dart';

void main() {
  String? answer;
  bool closed = false;

  Future<void> open(
    WidgetTester t, {
    bool isDismissible = true,
    bool still = false,
  }) async {
    answer = null;
    closed = false;
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            if (still)
              const AppMotion(
                base: Duration.zero,
                fast: Duration.zero,
                still: true,
              ),
          ],
        ),
        home: Builder(
          builder: (c) => TextButton(
            onPressed: () async {
              answer = await showAppQuestion<String>(
                context: c,
                title: 'Sair?',
                message: 'Linha.',
                isDismissible: isDismissible,
                actionsBuilder: (ctx) => [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, 'yes'),
                    child: const Text('Sim'),
                  ),
                ],
              );
              closed = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pump();
    await t.pumpAndSettle();
  }

  testWidgets('gives the caller the answer that was tapped', (t) async {
    await open(t);
    expect(find.text('Sair?'), findsOneWidget);
    expect(find.text('Linha.'), findsOneWidget);
    await t.tap(find.text('Sim'));
    await t.pumpAndSettle();
    expect(find.text('Sair?'), findsNothing);
    expect(answer, 'yes');
  });

  testWidgets('a tap on the ground closes it with no answer', (t) async {
    await open(t);
    await t.tapAt(const Offset(10, 10));
    await t.pumpAndSettle();
    expect(find.text('Sair?'), findsNothing);
    expect(closed, isTrue);
    expect(answer, isNull);
  });

  testWidgets('where the caller forbids it, the ground tap does nothing', (
    t,
  ) async {
    await open(t, isDismissible: false);
    await t.tapAt(const Offset(10, 10));
    await t.pumpAndSettle();
    expect(find.text('Sair?'), findsOneWidget);
    expect(closed, isFalse);
  });

  testWidgets('less motion: whole at once, gone at once', (t) async {
    await open(t, still: true);
    expect(find.text('Sair?'), findsOneWidget);
    await t.tap(find.text('Sim'));
    await t.pump();
    expect(find.text('Sair?'), findsNothing);
  });
}
