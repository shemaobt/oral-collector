import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/router/app_router.dart';
import 'package:oral_collector/features/auth/data/providers/role_provider.dart';
import 'package:oral_collector/features/genre/domain/entities/genre.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_notifier.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_state.dart';
import 'package:oral_collector/features/home/presentation/home_screen.dart';
import 'package:oral_collector/features/home/presentation/notifiers/home_notifier.dart';
import 'package:oral_collector/features/home/presentation/notifiers/home_state.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/interrupted_sessions_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';
import 'package:oral_collector/features/recording/presentation/recordings_list_screen.dart';
import 'package:oral_collector/features/recording/presentation/widgets/genre_selection_step.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_card.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';

import '../../support/router_app.dart';

class _QuietHome extends HomeNotifier {
  _QuietHome([this._onRefresh]);

  final void Function()? _onRefresh;

  @override
  HomeState build() => const HomeState();

  @override
  Future<void> refreshAll() async => _onRefresh?.call();
}

class _GrowingServer extends FakeApi {
  int calls = 0;
  final recordings = <ServerRecording>[];

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
  }) async {
    calls++;
    return [...recordings];
  }
}

class _GrowingProjects extends FakeProjectNotifier {
  _GrowingProjects(this._gained);

  final List<Project> _gained;

  @override
  Future<void> fetchProjects() async =>
      state = state.copyWith(projects: [project, ..._gained]);
}

class _QuietRoles extends FakeRoleNotifier {
  @override
  Future<void> fetchRolesForProjects(List<String> projectIds) async {}
}

class _GrowingStorage extends OnlineSync {
  _GrowingStorage(this._bytes);

  final int Function() _bytes;

  @override
  Future<int> getLocalStorageUsed() async => _bytes();
}

class _OneGenre extends FakeGenreNotifier {
  @override
  GenreState build() => const GenreState(
    genres: [
      Genre(id: 'g1', name: 'Folk Tale', sortOrder: 1, subcategories: []),
    ],
  );
}

Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.bySemanticsLabel('$label tab'));
  await settle(tester);
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required String at,
  List<Override> overrides = const [],
  void Function()? onHomeRefresh,
}) => pumpApp(
  tester,
  at: at,
  overrides: [
    homeNotifierProvider.overrideWith(() => _QuietHome(onHomeRefresh)),
    ...overrides,
  ],
);

State _stateOf(WidgetTester tester, Type screen) =>
    tester.state(find.byType(screen, skipOffstage: false));

void main() {
  testWidgets('each tab is the same screen after a visit to the other', (
    tester,
  ) async {
    await _pump(tester, at: '/home');
    final home = _stateOf(tester, HomeScreen);
    await _tapTab(tester, 'Recordings');
    final recordings = _stateOf(tester, RecordingsListScreen);

    await _tapTab(tester, 'Home');
    await _tapTab(tester, 'Recordings');

    expect(identical(_stateOf(tester, HomeScreen), home), isTrue);
    expect(
      identical(_stateOf(tester, RecordingsListScreen), recordings),
      isTrue,
    );
  });

  testWidgets('coming back to Recordings asks the server again and shows '
      'what it gained', (tester) async {
    final server = _GrowingServer();
    await _pump(
      tester,
      at: '/home',
      overrides: [recordingApiRepositoryProvider.overrideWithValue(server)],
    );
    await _tapTab(tester, 'Recordings');
    expect(server.calls, 1);

    await _tapTab(tester, 'Home');
    server.recordings.add(serverRecording);
    await _tapTab(tester, 'Recordings');

    expect(server.calls, 2);
    expect(find.byType(RecordingCard), findsOneWidget);
  });

  testWidgets('coming back to Home reads its numbers again', (tester) async {
    var refreshes = 0;
    await _pump(tester, at: '/recordings', onHomeRefresh: () => refreshes++);
    await _tapTab(tester, 'Home');
    expect(refreshes, 1);

    await _tapTab(tester, 'Recordings');
    await _tapTab(tester, 'Home');

    expect(refreshes, 2);
  });

  testWidgets('coming back to Projects shows the projects it gained', (
    tester,
  ) async {
    final gained = <Project>[];
    await _pump(
      tester,
      at: '/projects',
      overrides: [
        projectNotifierProvider.overrideWith(() => _GrowingProjects(gained)),
        roleNotifierProvider.overrideWith(_QuietRoles.new),
      ],
    );
    await _tapTab(tester, 'Home');
    gained.add(
      const Project(id: 'p2', name: 'Lingala songs', languageId: 'l1'),
    );
    await _tapTab(tester, 'Projects');

    expect(find.text('Lingala songs'), findsOneWidget);
  });

  testWidgets('coming back to Profile reads the storage used again', (
    tester,
  ) async {
    var bytes = 0;
    await pumpApp(
      tester,
      at: '/profile',
      settled: false,
      overrides: [
        homeNotifierProvider.overrideWith(_QuietHome.new),
        syncNotifierProvider.overrideWith(() => _GrowingStorage(() => bytes)),
      ],
    );
    Future<void> tapTab(String label) async {
      await tester.tap(find.bySemanticsLabel(RegExp('^$label tab')));
      await tester.pump();
      await tester.pump();
    }

    await tapTab('Home');
    bytes = 2048;
    await tapTab('Profile');

    expect(find.text('2.0 KB'), findsOneWidget);
  });

  testWidgets('Record starts at its first step after a visit to Home', (
    tester,
  ) async {
    await _pump(
      tester,
      at: '/record',
      overrides: [genreNotifierProvider.overrideWith(_OneGenre.new)],
    );
    await tester.tap(find.text('Folk Tale'));
    await settle(tester);
    expect(find.byType(GenreSelectionStep), findsNothing);

    await _tapTab(tester, 'Home');
    await _tapTab(tester, 'Record');

    expect(find.byType(GenreSelectionStep), findsOneWidget);
  });

  testWidgets('a second recovery opens on its own recording', (tester) async {
    final app = await _pump(tester, at: '/home');
    Future<RecordingResult> recover(String name) async {
      final result = RecordingResult(filePath: name, durationSeconds: 5);
      app.read(pendingRecoveryProvider.notifier).state = PendingRecovery(
        result: result,
        sessionId: name,
        genreId: 'g1',
        subcategoryId: null,
      );
      app.read(routerProvider).go('/recovery-confirm');
      await settle(tester);
      return result;
    }

    await recover('first');
    app.read(routerProvider).go('/home');
    await settle(tester);
    final second = await recover('second');

    expect(app.read(pendingRecordingDecisionProvider), same(second));
  });

  testWidgets('Record starts at its first step after a visit to Home, '
      'even when it was opened on a genre', (tester) async {
    final app = await _pump(
      tester,
      at: '/home',
      overrides: [genreNotifierProvider.overrideWith(_OneGenre.new)],
    );
    app.read(routerProvider).go('/record?genreId=g1');
    await settle(tester);
    expect(find.byType(GenreSelectionStep), findsNothing);

    await _tapTab(tester, 'Home');
    await _tapTab(tester, 'Record');

    expect(find.byType(GenreSelectionStep), findsOneWidget);
  });
}
