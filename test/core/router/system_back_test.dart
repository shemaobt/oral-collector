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

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/auth/auth_notifier.dart';
import 'package:oral_collector/core/auth/auth_state.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/router/app_router.dart';
import 'package:oral_collector/features/auth/data/providers/role_provider.dart';
import 'package:oral_collector/features/auth/domain/entities/user.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_notifier.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_state.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/presentation/notifiers/member_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/member_state.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';
import 'package:oral_collector/features/recording/presentation/recording_detail_screen.dart';
import 'package:oral_collector/features/recording/presentation/recordings_list_screen.dart';
import 'package:oral_collector/features/recording/presentation/trim_editor_screen.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_card.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

import '../../support/system_back.dart';
import '../../support/text_scale.dart';

const _recordingId = 'r1';
const _project = Project(id: 'p1', name: 'Kwanga stories', languageId: 'l1');

final _serverRecording = ServerRecording(
  id: _recordingId,
  projectId: 'p1',
  genreId: 'g1',
  title: 'The hunter and the river',
  durationSeconds: 42,
  fileSizeBytes: 2048,
  format: 'm4a',
  uploadStatus: 'uploaded',
  cleaningStatus: 'none',
  recordedAt: DateTime(2026, 1, 1),
);

/// Lists the one recording the list screen shows, and refuses to resolve it
/// afterwards.
///
/// The refusal is what keeps the detail screen in its not-found state, the one
/// state that renders without the hero player — the player takes near-unbounded
/// constraints under the test font and overflows (see
/// `recording_detail_screen_test.dart`). Which screen is on the stack is what
/// this file asserts, and that is the same in either state.
class _FakeApi implements RecordingApiRepository {
  @override
  Future<List<ServerRecording>> listRecordings(
    String projectId, {
    int offset = 0,
    int limit = 50,
    String? userId,
    String? storytellerId,
    String? uploadStatus,
    String? title,
    String? reviewFlag,
  }) async => [_serverRecording];

  @override
  Future<ServerRecording> getRecording(String id) =>
      throw StateError('the detail screen resolves to not-found in this test');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected in test');
}

class _FakeLocal implements LocalRecordingRepository {
  @override
  Future<List<LocalRecording>> getAllRecordings(String projectId) async =>
      const [];

  @override
  Future<LocalRecording?> getRecordingById(String id) async => null;

  @override
  Future<LocalRecording?> getRecordingByServerId(String serverId) async => null;

  @override
  Future<LocalRecordingEntity?> getRecordingEntityById(String id) async => null;

  @override
  Future<LocalRecordingEntity?> getRecordingEntityByServerId(
    String serverId,
  ) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected in test');
}

class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    currentUser: User(id: 'u1', email: 'a@b.c', isPlatformAdmin: false),
  );
}

class _FakeProjectNotifier extends ProjectNotifier {
  @override
  ProjectState build() =>
      const ProjectState(projects: [_project], activeProject: _project);
}

class _FakeGenreNotifier extends GenreNotifier {
  @override
  GenreState build() => const GenreState();

  @override
  Future<void> fetchGenres() async {}
}

class _OnlineSync extends SyncNotifier {
  @override
  SyncState build() => const SyncState(isOnline: true);

  @override
  Future<void> processQueue() async {}
}

class _FakeRoleNotifier extends RoleNotifier {
  @override
  RoleState build() => const RoleState();

  @override
  Future<void> fetchRoleForProject(String projectId) async {}
}

class _FakeMemberNotifier extends MemberNotifier {
  @override
  MemberState build() => const MemberState();

  @override
  Future<void> fetchMembers(String projectId) async {}
}

/// Boots the app's own router at [at] and pumps until it is quiet.
///
/// The router starts at `/home`, so [at] is applied with `go` before the first
/// pump: `go` replaces the stack, which leaves exactly one entry on it — the
/// state a freshly launched app is in — and spares this file the home screen's
/// unrelated dependency thicket.
Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  required String at,
}) async {
  tester.view.physicalSize = kPhoneSize * 3.0;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final container = ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
      syncNotifierProvider.overrideWith(_OnlineSync.new),
      genreNotifierProvider.overrideWith(_FakeGenreNotifier.new),
      projectNotifierProvider.overrideWith(_FakeProjectNotifier.new),
      roleNotifierProvider.overrideWith(_FakeRoleNotifier.new),
      memberNotifierProvider.overrideWith(_FakeMemberNotifier.new),
      recordingApiRepositoryProvider.overrideWithValue(_FakeApi()),
      localRecordingRepositoryProvider.overrideWithValue(_FakeLocal()),
      // The real Drift watch stream leaves a pending Timer that flutter_test
      // flags on teardown.
      localRecordingStreamProvider(
        _recordingId,
      ).overrideWith((ref) => const Stream<LocalRecordingEntity?>.empty()),
    ],
  );
  addTearDown(container.dispose);

  container.read(routerProvider).go(at);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: container.read(routerProvider),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    ),
  );
  await _settle(tester);
  return container;
}

/// Settles by pumping until no frame is scheduled, never by a fixed number of
/// pumps.
///
/// A counted `pump(50ms)` loop is not equivalent here and quietly lies: a route
/// removed by a system back stays mounted through ten of them, so the test goes
/// red on a defect that is not there.
Future<void> _settle(WidgetTester tester) => tester.pumpAndSettle();

void main() {
  testWidgets('the system back on a pushed screen goes back, '
      'instead of out of the app', (tester) async {
    final platformCalls = recordPlatformCalls(tester);
    await _pumpApp(tester, at: '/recordings');

    await tester.tap(find.byType(RecordingCard));
    await _settle(tester);
    expect(find.byType(RecordingDetailScreen), findsOneWidget);

    await simulateSystemBack();
    await _settle(tester);

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
    await _pumpApp(tester, at: '/recordings');
    expect(find.byType(RecordingsListScreen), findsOneWidget);

    await simulateSystemBack();
    await _settle(tester);

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
    final container = await _pumpApp(tester, at: '/recordings');

    // Not awaited: `push` completes only when the pushed route pops, which is
    // the thing this test is about to make happen.
    unawaited(
      container.read(routerProvider).push('/recording/$_recordingId/trim'),
    );
    await _settle(tester);
    expect(find.byType(TrimEditorScreen), findsOneWidget);

    await simulateSystemBack();
    await _settle(tester);

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
    final container = await _pumpApp(tester, at: '/recordings');

    // Not awaited: `push` completes only when the pushed route pops, which is
    // the thing this test is about to make happen.
    unawaited(
      container.read(routerProvider).push('/recording/$_recordingId/trim'),
    );
    await _settle(tester);
    expect(find.byType(TrimEditorScreen), findsOneWidget);

    await simulatePredictiveBack();
    await _settle(tester);

    expect(platformCalls, isNot(contains('SystemNavigator.pop')));
    expect(find.byType(TrimEditorScreen), findsNothing);
    expect(find.byType(RecordingsListScreen), findsOneWidget);
  });
}
