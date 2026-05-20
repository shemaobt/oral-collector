import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:oral_collector/core/auth/auth_notifier.dart';
import 'package:oral_collector/core/auth/auth_state.dart';
import 'package:oral_collector/features/auth/domain/entities/user.dart';
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

const _testUser = User(
  id: 'u1',
  email: 'test@example.com',
  displayName: 'Test User',
  isPlatformAdmin: false,
);

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const Text('home page')),
          GoRoute(
            path: '/recordings',
            builder: (_, _) => const Text('recordings page'),
          ),
        ],
      ),
      GoRoute(path: '/login', builder: (_, _) => const Text('login page')),
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

void main() {
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
