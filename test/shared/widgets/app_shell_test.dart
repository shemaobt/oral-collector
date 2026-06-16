import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:oral_collector/core/auth/auth_notifier.dart';
import 'package:oral_collector/core/auth/auth_state.dart';
import 'package:oral_collector/features/auth/data/providers/role_provider.dart';
import 'package:oral_collector/features/auth/domain/entities/user.dart';
import 'package:oral_collector/features/invite/presentation/notifiers/invite_notifier.dart';
import 'package:oral_collector/features/invite/presentation/notifiers/invite_state.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';
import 'package:oral_collector/shared/widgets/app_shell.dart';

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

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initial);
  final AuthState _initial;
  int logoutCallCount = 0;

  @override
  AuthState build() => _initial;

  @override
  Future<void> logout() async {
    logoutCallCount++;
    state = const AuthState();
  }
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

  @override
  bool get isPlatformAdmin => false;
}

const _testUser = User(
  id: 'u1',
  email: 'test@example.com',
  displayName: 'Test User',
  isPlatformAdmin: false,
);

Widget _harness({
  required RecordingState recordingState,
  RecordingResult? pendingDecision,
  required GoRouter router,
}) {
  return ProviderScope(
    overrides: [
      recordingSessionNotifierProvider.overrideWith(
        () => _FakeRecordingSessionNotifier(recordingState),
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
          GoRoute(
            path: '/recordings',
            builder: (_, _) => const Scaffold(
              key: ValueKey('recordings-screen'),
              body: Center(child: Text('recordings page')),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(
          key: ValueKey('login-screen'),
          body: Center(child: Text('login page')),
        ),
      ),
    ],
  );
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required _FakeRecordingSessionNotifier rec,
  required _FakeAuthNotifier auth,
}) async {
  tester.view.physicalSize = const Size(1024, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        recordingSessionNotifierProvider.overrideWith(() => rec),
        authNotifierProvider.overrideWith(() => auth),
        inviteNotifierProvider.overrideWith(_FakeInviteNotifier.new),
        roleNotifierProvider.overrideWith(_FakeRoleNotifier.new),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routerConfig: _buildRouter(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpAtTextScale(
  WidgetTester tester, {
  required Size size,
  required double scale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        recordingSessionNotifierProvider.overrideWith(
          () => _FakeRecordingSessionNotifier(const RecordingState()),
        ),
        authNotifierProvider.overrideWith(
          () => _FakeAuthNotifier(const AuthState(currentUser: _testUser)),
        ),
        pendingRecordingDecisionProvider.overrideWith((_) => null),
        inviteNotifierProvider.overrideWith(_FakeInviteNotifier.new),
        roleNotifierProvider.overrideWith(_FakeRoleNotifier.new),
      ],
      child: MaterialApp.router(
        routerConfig: _buildRouter(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('text-scale resilience (ENG-178)', () {
    for (final scale in const [1.0, 1.3, 2.0]) {
      testWidgets('mobile bottom nav has no overflow at ${scale}x', (
        tester,
      ) async {
        await _pumpAtTextScale(
          tester,
          size: const Size(400, 800),
          scale: scale,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('wide sidebar has no overflow at ${scale}x', (tester) async {
        await _pumpAtTextScale(
          tester,
          size: const Size(1024, 800),
          scale: scale,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('record tab stays reachable in bottom nav at 2.0x', (
      tester,
    ) async {
      await _pumpAtTextScale(tester, size: const Size(400, 800), scale: 2.0);
      expect(find.bySemanticsLabel('Record tab'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

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

  group('AppShell logout guard (G1)', () {
    testWidgets(
      'logout while recording shows the block-nav dialog and does not log out yet',
      (tester) async {
        final rec = _FakeRecordingSessionNotifier(
          const RecordingState(isRecording: true),
        );
        final auth = _FakeAuthNotifier(const AuthState(currentUser: _testUser));

        await _pumpShell(tester, rec: rec, auth: auth);

        await tester.tap(find.byIcon(LucideIcons.logOut));
        await tester.pumpAndSettle();

        final l10n = AppLocalizationsEn();
        expect(find.text(l10n.recording_blockNavTitle), findsOneWidget);
        expect(auth.logoutCallCount, 0);
        expect(rec.discardCallCount, 0);
        expect(find.text('login page'), findsNothing);
      },
    );

    testWidgets(
      'cancel on logout dialog keeps user logged in and does not discard',
      (tester) async {
        final rec = _FakeRecordingSessionNotifier(
          const RecordingState(isRecording: true),
        );
        final auth = _FakeAuthNotifier(const AuthState(currentUser: _testUser));

        await _pumpShell(tester, rec: rec, auth: auth);

        await tester.tap(find.byIcon(LucideIcons.logOut));
        await tester.pumpAndSettle();

        final l10n = AppLocalizationsEn();
        await tester.tap(find.text(l10n.common_cancel));
        await tester.pumpAndSettle();

        expect(auth.logoutCallCount, 0);
        expect(rec.discardCallCount, 0);
        expect(find.text('login page'), findsNothing);
      },
    );

    testWidgets(
      'confirm on logout dialog discards recording, logs out, and navigates to /login',
      (tester) async {
        final rec = _FakeRecordingSessionNotifier(
          const RecordingState(isRecording: true),
        );
        final auth = _FakeAuthNotifier(const AuthState(currentUser: _testUser));

        await _pumpShell(tester, rec: rec, auth: auth);

        await tester.tap(find.byIcon(LucideIcons.logOut));
        await tester.pumpAndSettle();

        final l10n = AppLocalizationsEn();
        await tester.tap(find.text(l10n.recording_blockNavDiscardAndLeave));
        await tester.pumpAndSettle();

        expect(rec.discardCallCount, 1);
        expect(auth.logoutCallCount, 1);
        expect(find.text('login page'), findsOneWidget);
      },
    );

    testWidgets(
      'logout when no recording is in progress skips the dialog and logs out immediately',
      (tester) async {
        final rec = _FakeRecordingSessionNotifier(const RecordingState());
        final auth = _FakeAuthNotifier(const AuthState(currentUser: _testUser));

        await _pumpShell(tester, rec: rec, auth: auth);

        await tester.tap(find.byIcon(LucideIcons.logOut));
        await tester.pumpAndSettle();

        final l10n = AppLocalizationsEn();
        expect(find.text(l10n.recording_blockNavTitle), findsNothing);
        expect(auth.logoutCallCount, 1);
        expect(find.text('login page'), findsOneWidget);
      },
    );
  });
}
