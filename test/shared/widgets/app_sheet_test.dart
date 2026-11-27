import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/shared/widgets/app_sheet.dart';

void main() {
  Future<void> open(WidgetTester tester, {bool isDismissible = true}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showAppSheet<void>(
                context: context,
                isDismissible: isDismissible,
                builder: (_) =>
                    const SizedBox(height: 300, child: Text('body')),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a drag down dismisses the sheet', (tester) async {
    await open(tester);

    await tester.fling(find.text('body'), const Offset(0, 400), 2000);
    await tester.pumpAndSettle();

    expect(find.text('body'), findsNothing);
  });

  testWidgets('a tap on the ground dismisses the sheet', (tester) async {
    await open(tester);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('body'), findsNothing);
  });

  testWidgets('a sheet that is not dismissible ignores drag and ground', (
    tester,
  ) async {
    await open(tester, isDismissible: false);

    await tester.fling(find.text('body'), const Offset(0, 400), 2000);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('body'), findsOneWidget);
  });
}
