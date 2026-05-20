import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:oral_collector/features/auth/data/providers/role_provider.dart';
import 'package:oral_collector/features/invite/presentation/notifiers/invite_notifier.dart';
import 'package:oral_collector/features/invite/presentation/notifiers/invite_state.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/shared/widgets/app_shell.dart';

class _MutableRecordingSessionNotifier extends RecordingSessionNotifier {
  _MutableRecordingSessionNotifier(this._initial);
  final RecordingState _initial;

  @override
  RecordingState build() => _initial;
}

class _FakeInviteNotifier extends InviteNotifier {
  @override
  InviteState build() => const InviteState();

  @override
  Future<void> fetchInvites() async {}
}

class _FakeRoleNotifier extends RoleNotifier {
  @override
  RoleState build() => const RoleState();

  // `isPlatformAdmin` reads authNotifierProvider; the AppShell only calls it
  // in web (>=600px) layout. Override to false so we never reach that read.
  @override
  bool get isPlatformAdmin => false;
}

Widget _harness({
  required RecordingState recordingState,
  RecordingResult? pendingDecision,
  required GoRouter router,
}) {
  return ProviderScope(
    overrides: [
      recordingSessionNotifierProvider.overrideWith(
        () => _MutableRecordingSessionNotifier(recordingState),
      ),
      pendingRecordingDecisionProvider.overrideWith((_) => pendingDecision),
      inviteNotifierProvider.overrideWith(_FakeInviteNotifier.new),
      roleNotifierProvider.overrideWith(_FakeRoleNotifier.new),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    ),
  );
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(
              key: ValueKey('home-screen'),
              body: Center(child: Text('home page')),
            ),
          ),
          GoRoute(
            path: '/record',
            builder: (_, _) => const Scaffold(
              key: ValueKey('record-screen'),
              body: Center(child: Text('record page')),
            ),
          ),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets(
    'tapping a tab while finalizing shows snackbar and does not navigate',
    (tester) async {
      // Mobile layout (< 600px) so the bottom nav is used.
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = _buildRouter();
      await tester.pumpWidget(
        _harness(
          recordingState: const RecordingState(
            finalizationStage: FinalizationStage.compressingAudio,
          ),
          router: router,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('home page'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Record tab'));
      await tester.pump(); // start snackbar animation

      expect(
        find.text('Saving your recording — please wait a moment.'),
        findsOneWidget,
      );
      // Did NOT navigate
      expect(find.text('record page'), findsNothing);
      expect(find.text('home page'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping a tab while error overlay is up shows snackbar and does not '
    'navigate',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = _buildRouter();
      await tester.pumpWidget(
        _harness(
          recordingState: const RecordingState(
            finalizationErrorKind: FinalizationErrorKind.noSegments,
          ),
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Record tab'));
      await tester.pump();

      expect(
        find.text('Saving your recording — please wait a moment.'),
        findsOneWidget,
      );
      expect(find.text('record page'), findsNothing);
    },
  );

  testWidgets(
    'tapping a tab while a recording decision is pending shows discard '
    'dialog; Cancel keeps user on current page',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = _buildRouter();
      await tester.pumpWidget(
        _harness(
          recordingState: const RecordingState(),
          pendingDecision: const RecordingResult(
            filePath: '/tmp/recording_test.m4a',
            durationSeconds: 5.0,
          ),
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Record tab'));
      await tester.pumpAndSettle();

      // Discard dialog appears
      expect(find.text('Discard Recording?'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Cancel keeps user on /home
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('record page'), findsNothing);
      expect(find.text('home page'), findsOneWidget);
    },
  );

  testWidgets('idle state allows tab navigation without snackbar or dialog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = _buildRouter();
    await tester.pumpWidget(
      _harness(recordingState: const RecordingState(), router: router),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Record tab'));
    await tester.pumpAndSettle();

    expect(find.text('record page'), findsOneWidget);
    expect(
      find.text('Saving your recording — please wait a moment.'),
      findsNothing,
    );
  });
}
