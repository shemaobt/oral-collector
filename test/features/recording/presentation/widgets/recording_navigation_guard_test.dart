import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_navigation_guard.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';

class _FakeRecordingSessionNotifier extends RecordingSessionNotifier {
  _FakeRecordingSessionNotifier(this._initial);

  final RecordingState _initial;
  int discardCallCount = 0;

  @override
  RecordingState build() => _initial;

  @override
  Future<void> discardRecording() async {
    discardCallCount++;
    state = const RecordingState();
  }
}

Future<void> _pumpAppWithGuard(
  WidgetTester tester, {
  required _FakeRecordingSessionNotifier fake,
  required GlobalKey<NavigatorState> navKey,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [recordingSessionNotifierProvider.overrideWith(() => fake)],
      child: MaterialApp(
        navigatorKey: navKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const Scaffold(body: Center(child: Text('root'))),
      ),
    ),
  );

  unawaited(
    navKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const RecordingNavigationGuard(
          child: Scaffold(body: Center(child: Text('recording'))),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pops back to previous route when no recording is in progress', (
    tester,
  ) async {
    final fake = _FakeRecordingSessionNotifier(const RecordingState());
    final navKey = GlobalKey<NavigatorState>();

    await _pumpAppWithGuard(tester, fake: fake, navKey: navKey);
    expect(find.text('recording'), findsOneWidget);

    final popped = await navKey.currentState!.maybePop();
    await tester.pumpAndSettle();

    expect(popped, isTrue);
    expect(find.text('root'), findsOneWidget);
    expect(find.text('recording'), findsNothing);
    expect(fake.discardCallCount, 0);
  });

  testWidgets(
    'blocks pop and shows confirmation dialog when a recording is active',
    (tester) async {
      final fake = _FakeRecordingSessionNotifier(
        const RecordingState(isRecording: true),
      );
      final navKey = GlobalKey<NavigatorState>();

      await _pumpAppWithGuard(tester, fake: fake, navKey: navKey);

      await navKey.currentState!.maybePop();
      await tester.pumpAndSettle();

      final l10n = AppLocalizationsEn();
      expect(find.text(l10n.recording_blockNavTitle), findsOneWidget);
      expect(find.text('recording'), findsOneWidget);
      expect(fake.discardCallCount, 0);
    },
  );

  testWidgets(
    'cancel keeps user on recording screen and does not call discard',
    (tester) async {
      final fake = _FakeRecordingSessionNotifier(
        const RecordingState(isRecording: true),
      );
      final navKey = GlobalKey<NavigatorState>();

      await _pumpAppWithGuard(tester, fake: fake, navKey: navKey);

      await navKey.currentState!.maybePop();
      await tester.pumpAndSettle();

      final l10n = AppLocalizationsEn();
      await tester.tap(find.text(l10n.common_cancel));
      await tester.pumpAndSettle();

      expect(find.text('recording'), findsOneWidget);
      expect(find.text('root'), findsNothing);
      expect(fake.discardCallCount, 0);
    },
  );

  testWidgets(
    'discard-and-leave calls discardRecording and pops back to previous route',
    (tester) async {
      final fake = _FakeRecordingSessionNotifier(
        const RecordingState(isRecording: true),
      );
      final navKey = GlobalKey<NavigatorState>();

      await _pumpAppWithGuard(tester, fake: fake, navKey: navKey);

      await navKey.currentState!.maybePop();
      await tester.pumpAndSettle();

      final l10n = AppLocalizationsEn();
      await tester.tap(find.text(l10n.recording_blockNavDiscardAndLeave));
      await tester.pumpAndSettle();

      expect(fake.discardCallCount, 1);
      expect(find.text('root'), findsOneWidget);
      expect(find.text('recording'), findsNothing);
    },
  );

  testWidgets('also blocks when only paused (paused counts as in progress)', (
    tester,
  ) async {
    final fake = _FakeRecordingSessionNotifier(
      const RecordingState(isRecording: true, isPaused: true),
    );
    final navKey = GlobalKey<NavigatorState>();

    await _pumpAppWithGuard(tester, fake: fake, navKey: navKey);

    await navKey.currentState!.maybePop();
    await tester.pumpAndSettle();

    final l10n = AppLocalizationsEn();
    expect(find.text(l10n.recording_blockNavTitle), findsOneWidget);
    expect(find.text('recording'), findsOneWidget);
  });
}
