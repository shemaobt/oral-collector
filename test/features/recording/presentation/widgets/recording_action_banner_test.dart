import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_action_banner.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

RecordingActionBanner _banner({VoidCallback? onAction}) =>
    RecordingActionBanner(
      theme: ThemeData.light(),
      icon: LucideIcons.alertCircle,
      message: 'Needs attention',
      actionLabel: 'Fix it',
      accentColor: const Color(0xFFAA0000),
      backgroundColor: const Color(0x22AA0000),
      borderColor: const Color(0x55AA0000),
      actionBackgroundColor: const Color(0x11AA0000),
      onAction: onAction,
    );

void main() {
  testWidgets('renders the message and action label', (tester) async {
    await tester.pumpWidget(_wrap(_banner(onAction: () {})));

    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.text('Fix it'), findsOneWidget);
  });

  testWidgets('tapping the action button invokes onAction', (tester) async {
    var calls = 0;
    await tester.pumpWidget(_wrap(_banner(onAction: () => calls++)));

    await tester.tap(find.text('Fix it'));
    await tester.pump();

    expect(calls, 1);
  });

  testWidgets('a null onAction renders a disabled button', (tester) async {
    await tester.pumpWidget(_wrap(_banner(onAction: null)));

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
}
