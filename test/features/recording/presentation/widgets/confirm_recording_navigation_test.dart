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

class _Harness extends ConsumerWidget {
  const _Harness({required this.onResult});
  final void Function(bool) onResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: TextButton(
        onPressed: () async {
          final ok = await confirmRecordingNavigationFromTab(context, ref);
          onResult(ok);
        },
        child: const Text('go'),
      ),
    );
  }
}

Future<bool?> _runHarness(
  WidgetTester tester, {
  required _FakeRecordingSessionNotifier fake,
}) async {
  bool? captured;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [recordingSessionNotifierProvider.overrideWith(() => fake)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: _Harness(onResult: (v) => captured = v),
      ),
    ),
  );
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
  return captured;
}

void main() {
  testWidgets(
    'returns true without showing dialog when no recording is in progress',
    (tester) async {
      final fake = _FakeRecordingSessionNotifier(const RecordingState());

      final result = await _runHarness(tester, fake: fake);

      final l10n = AppLocalizationsEn();
      expect(find.text(l10n.recording_blockNavTitle), findsNothing);
      expect(result, isTrue);
      expect(fake.discardCallCount, 0);
    },
  );

  testWidgets('returns false and does not discard when user cancels dialog', (
    tester,
  ) async {
    final fake = _FakeRecordingSessionNotifier(
      const RecordingState(isRecording: true),
    );

    bool? captured;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [recordingSessionNotifierProvider.overrideWith(() => fake)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: _Harness(onResult: (v) => captured = v),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    final l10n = AppLocalizationsEn();
    expect(find.text(l10n.recording_blockNavTitle), findsOneWidget);

    await tester.tap(find.text(l10n.common_cancel));
    await tester.pumpAndSettle();

    expect(captured, isFalse);
    expect(fake.discardCallCount, 0);
  });

  testWidgets(
    'returns true and calls discardRecording when user confirms dialog',
    (tester) async {
      final fake = _FakeRecordingSessionNotifier(
        const RecordingState(isRecording: true),
      );

      bool? captured;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recordingSessionNotifierProvider.overrideWith(() => fake),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: _Harness(onResult: (v) => captured = v),
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      final l10n = AppLocalizationsEn();
      await tester.tap(find.text(l10n.recording_blockNavDiscardAndLeave));
      await tester.pumpAndSettle();

      expect(captured, isTrue);
      expect(fake.discardCallCount, 1);
    },
  );

  testWidgets(
    'triggers dialog when only paused (paused counts as in progress)',
    (tester) async {
      final fake = _FakeRecordingSessionNotifier(
        const RecordingState(isRecording: true, isPaused: true),
      );

      bool? captured;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recordingSessionNotifierProvider.overrideWith(() => fake),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: _Harness(onResult: (v) => captured = v),
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      final l10n = AppLocalizationsEn();
      expect(find.text(l10n.recording_blockNavTitle), findsOneWidget);

      await tester.tap(find.text(l10n.common_cancel));
      await tester.pumpAndSettle();
      expect(captured, isFalse);
    },
  );
}
