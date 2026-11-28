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
import 'package:oral_collector/features/recording/presentation/notifiers/interrupted_sessions_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';
import 'package:oral_collector/features/recording/presentation/recordings_list_screen.dart';
import 'package:oral_collector/features/recording/presentation/widgets/genre_selection_step.dart';

import '../../support/router_app.dart';

class _QuietHome extends HomeNotifier {
  @override
  HomeState build() => const HomeState();

  @override
  Future<void> refreshAll() async {}
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
}) => pumpApp(
  tester,
  at: at,
  overrides: [homeNotifierProvider.overrideWith(_QuietHome.new), ...overrides],
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
}
