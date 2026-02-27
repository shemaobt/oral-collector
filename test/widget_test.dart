import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oral_collector/main.dart';

void main() {
  testWidgets('Home screen shows app title', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: OralCollectorApp()));
    await tester.pumpAndSettle();

    expect(find.text('Oral Collector'), findsOneWidget);
    expect(find.text('Oral Capture'), findsOneWidget);
  });
}
