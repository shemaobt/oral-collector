import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/genre/domain/entities/genre.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_notifier.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_state.dart';
import 'package:oral_collector/features/home/presentation/home_screen.dart';
import 'package:oral_collector/features/home/presentation/notifiers/home_notifier.dart';
import 'package:oral_collector/features/home/presentation/notifiers/home_state.dart';
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
}
