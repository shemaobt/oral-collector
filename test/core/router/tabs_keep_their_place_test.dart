import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/router/app_router.dart';
import 'package:oral_collector/features/genre/domain/entities/genre.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_notifier.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_state.dart';
import 'package:oral_collector/features/home/presentation/home_screen.dart';
import 'package:oral_collector/features/home/presentation/notifiers/home_notifier.dart';
import 'package:oral_collector/features/home/presentation/notifiers/home_state.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/presentation/recordings_list_screen.dart';
import 'package:oral_collector/features/recording/presentation/widgets/genre_selection_step.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_card.dart';

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
      at: '/recordings',
      overrides: [recordingApiRepositoryProvider.overrideWithValue(server)],
    );
    expect(server.calls, 1);

    await _tapTab(tester, 'Home');
    server.recordings.add(serverRecording);
    await _tapTab(tester, 'Recordings');

    expect(server.calls, 2);
    expect(find.byType(RecordingCard), findsOneWidget);
  });

  testWidgets('coming back to Home reads its numbers again', (tester) async {
    var refreshes = 0;
    await _pump(tester, at: '/home', onHomeRefresh: () => refreshes++);
    expect(refreshes, 1);

    await _tapTab(tester, 'Recordings');
    await _tapTab(tester, 'Home');

    expect(refreshes, 2);
  });

  testWidgets('a genre opens its recordings filtered on a list kept alive', (
    tester,
  ) async {
    final server = _GrowingServer()
      ..recordings.addAll([
        serverRecording,
        ServerRecording(
          id: 'r2',
          projectId: 'p1',
          genreId: 'g1',
          subcategoryId: 's1',
          title: 'The drum that spoke',
          durationSeconds: 30,
          fileSizeBytes: 1024,
          format: 'm4a',
          uploadStatus: 'uploaded',
          cleaningStatus: 'none',
          recordedAt: DateTime(2026, 1, 2),
        ),
      ]);
    final app = await _pump(
      tester,
      at: '/recordings',
      overrides: [recordingApiRepositoryProvider.overrideWithValue(server)],
    );
    expect(find.byType(RecordingCard), findsNWidgets(2));
    await _tapTab(tester, 'Home');

    app.read(routerProvider).go('/recordings?genreId=g1&subcategoryId=s1');
    await settle(tester);

    expect(find.byType(RecordingCard), findsOneWidget);
    expect(find.text('The drum that spoke'), findsOneWidget);
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
}
