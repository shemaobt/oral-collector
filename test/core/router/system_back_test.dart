/// The device's back button has to go back, not out of the app (ENG-68).
///
/// These went in to reproduce a reported defect and did not reproduce it: both
/// back paths pop correctly here. They stay as the regression guard the
/// behaviour never had — nothing exercised a system back on a stacked route
/// before this file.
///
/// Driven through the real router on purpose. The claim is about where a screen
/// sits in the route stack, and the stack this app builds on a phone is not
/// obvious from any one file: `/recording/:id` is declared twice in
/// `app_router.dart` — outside the `ShellRoute` under `!kIsWeb` and again
/// inside it under `kIsWeb` — so on a device the detail screen lives in the
/// root Navigator, one level above the shell's nested one. A hand-rolled test
/// router would prove nothing about that.
///
/// The back is delivered over the platform channels the engine uses, never by
/// tapping the AppBar's arrow: the arrow is already known to work, so a test
/// through it would stay green with the defect fully intact.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/router/app_router.dart';
import 'package:oral_collector/features/recording/presentation/recording_detail_screen.dart';
import 'package:oral_collector/features/recording/presentation/recordings_list_screen.dart';
import 'package:oral_collector/features/recording/presentation/trim_editor_screen.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_card.dart';

import '../../support/router_app.dart';
import '../../support/system_back.dart';

void main() {
  testWidgets('the system back on a pushed screen goes back, '
      'instead of out of the app', (tester) async {
    final platformCalls = recordPlatformCalls(tester);
    await pumpApp(tester, at: '/recordings');

    await tester.tap(find.byType(RecordingCard));
    await settle(tester);
    expect(find.byType(RecordingDetailScreen), findsOneWidget);

    await simulateSystemBack();
    await settle(tester);

    expect(platformCalls, isNot(contains('SystemNavigator.pop')));
    expect(find.byType(RecordingDetailScreen), findsNothing);
    expect(find.byType(RecordingsListScreen), findsOneWidget);
  });

  testWidgets('the system back on the first screen still leaves the app', (
    tester,
  ) async {
    // Without this, the cheapest fix for the test above — swallow every back —
    // would pass while trapping the user inside the app forever.
    final platformCalls = recordPlatformCalls(tester);
    await pumpApp(tester, at: '/recordings');
    expect(find.byType(RecordingsListScreen), findsOneWidget);

    await simulateSystemBack();
    await settle(tester);

    expect(platformCalls, contains('SystemNavigator.pop'));
  });

  testWidgets('the system back on a second pushed screen goes back too', (
    tester,
  ) async {
    // Every screen the ticket names is declared the same way — a top-level
    // route outside the shell under `!kIsWeb`. If back is broken for the detail
    // screen it is broken for all of them, so one more of that family says
    // whether a fix has to be per-screen or app-wide.
    final platformCalls = recordPlatformCalls(tester);
    final container = await pumpApp(tester, at: '/recordings');

    // Not awaited: `push` completes only when the pushed route pops, which is
    // the thing this test is about to make happen.
    unawaited(
      container.read(routerProvider).push('/recording/$recordingId/trim'),
    );
    await settle(tester);
    expect(find.byType(TrimEditorScreen), findsOneWidget);

    await simulateSystemBack();
    await settle(tester);

    expect(platformCalls, isNot(contains('SystemNavigator.pop')));
    expect(find.byType(TrimEditorScreen), findsNothing);
    expect(find.byType(RecordingsListScreen), findsOneWidget);
  });

  testWidgets('a predictive back gesture on a pushed screen goes back too', (
    tester,
  ) async {
    // The three above deliver `popRoute`, the legacy back. This app targets
    // Android 36, where predictive back is on by default, so a real device
    // sends a gesture over a different channel and never reaches `popRoute`
    // unless the framework declines it. Covering only the legacy path would
    // leave the one a phone actually uses untested.
    final platformCalls = recordPlatformCalls(tester);
    final container = await pumpApp(tester, at: '/recordings');

    // Not awaited: `push` completes only when the pushed route pops, which is
    // the thing this test is about to make happen.
    unawaited(
      container.read(routerProvider).push('/recording/$recordingId/trim'),
    );
    await settle(tester);
    expect(find.byType(TrimEditorScreen), findsOneWidget);

    await simulatePredictiveBack();
    await settle(tester);

    expect(platformCalls, isNot(contains('SystemNavigator.pop')));
    expect(find.byType(TrimEditorScreen), findsNothing);
    expect(find.byType(RecordingsListScreen), findsOneWidget);
  });
}
