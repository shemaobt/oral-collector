/// The list has to follow the URL it was opened with, every time (ENG-383).
///
/// `initState` applies the pendency the route carries, but the tab bar reaches
/// this screen with `context.go('/recordings')` and the State is reused, so
/// `initState` never runs again. The filter from a previous visit survives into
/// a URL that does not name it, and the two disagree — on web a reload then
/// flips what the list shows.
///
/// The fix must not overcorrect: a filter the user applied on this screen has
/// no business in the URL, and a rebuild that does not change the route must
/// leave it alone.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_notifier.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_state.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/review_pendency.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recordings_list_notifier.dart';
import 'package:oral_collector/features/recording/presentation/recordings_list_screen.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';

import '../../../support/text_scale.dart';

const _project = Project(id: 'p1', name: 'Kwanga stories', languageId: 'l1');

/// Remembers the `review_flag` of every listing it is asked for, so a test can
/// check the list re-asked the server rather than only that the state changed.
class _FakeApi implements RecordingApiRepository {
  final askedFlags = <String?>[];

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
    askedFlags.add(reviewFlag);
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected in test');
}

class _FakeLocal implements LocalRecordingRepository {
  @override
  Future<List<LocalRecording>> getAllRecordings(String projectId) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected in test');
}

class _FakeProjectNotifier extends ProjectNotifier {
  @override
  ProjectState build() => const ProjectState(activeProject: _project);
}

class _FakeGenreNotifier extends GenreNotifier {
  @override
  GenreState build() => const GenreState();

  @override
  Future<void> fetchGenres() async {}
}

class _SyncNotifierAt extends SyncNotifier {
  _SyncNotifierAt({required bool online}) : _online = online;

  final bool _online;

  @override
  SyncState build() => SyncState(isOnline: _online);

  @override
  Future<void> processQueue() async {}
}

void main() {
  late _FakeApi api;
  late List<Override> overrides;

  // The real notifier throughout: the question is what the screen does to the
  // filter it owns, and a fake notifier would answer a different one.
  void useOverrides({required bool online}) {
    api = _FakeApi();
    overrides = <Override>[
      recordingApiRepositoryProvider.overrideWithValue(api),
      localRecordingRepositoryProvider.overrideWithValue(_FakeLocal()),
      projectNotifierProvider.overrideWith(_FakeProjectNotifier.new),
      genreNotifierProvider.overrideWith(_FakeGenreNotifier.new),
      syncNotifierProvider.overrideWith(() => _SyncNotifierAt(online: online)),
    ];
  }

  setUp(() => useOverrides(online: false));

  Future<void> pumpChild(WidgetTester tester, Widget child) =>
      pumpAtTextScale(tester, overrides: overrides, child: child);

  Future<void> openList(WidgetTester tester, PendencyKind? flag) async {
    await pumpChild(tester, RecordingsListScreen(initialReviewFlag: flag));
    await tester.pump();
    await tester.pump();
  }

  PendencyKind? filterOf(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(RecordingsListScreen)),
  ).read(recordingsListNotifierProvider).selectedReviewFlag;

  testWidgets('coming back to the plain list drops the pendency it had', (
    tester,
  ) async {
    await openList(tester, PendencyKind.classification);
    expect(filterOf(tester), PendencyKind.classification);

    // The tab bar's `context.go('/recordings')`: same screen, same State, a
    // route that names no pendency.
    await openList(tester, null);

    expect(filterOf(tester), isNull);
  });

  testWidgets('a rebuild that changes no route leaves the user filter alone', (
    tester,
  ) async {
    await openList(tester, null);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(RecordingsListScreen)),
    );
    await container
        .read(recordingsListNotifierProvider.notifier)
        .setReviewFlagFilter(PendencyKind.storyteller);
    await tester.pump();

    // Rebuilt for its own reasons, still on `/recordings`. A reset keyed on
    // the route rather than on what changed would wipe a filter the user just
    // chose from the sheet.
    await openList(tester, null);

    expect(filterOf(tester), PendencyKind.storyteller);
  });

  testWidgets('a filter chosen in the sheet survives leaving and coming back', (
    tester,
  ) async {
    await openList(tester, null);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(RecordingsListScreen)),
    );
    await container
        .read(recordingsListNotifierProvider.notifier)
        .setReviewFlagFilter(PendencyKind.storyteller);
    await tester.pump();

    // Away: the State is disposed, as it is when the user leaves for another
    // tab. The container outlives the screen, so the filter is still set.
    await pumpChild(tester, const SizedBox.shrink());
    await tester.pump();
    expect(find.byType(RecordingsListScreen), findsNothing);

    // Back on `/recordings`, a route that names no pendency. `initState` runs
    // again here, and the filter it must not touch is the one the user chose.
    await openList(tester, null);

    expect(filterOf(tester), PendencyKind.storyteller);
  });

  testWidgets('following the route back to no pendency re-asks the server', (
    tester,
  ) async {
    useOverrides(online: true);
    await openList(tester, PendencyKind.classification);
    expect(api.askedFlags.last, 'missing_classification');

    // The tab bar's `context.go('/recordings')`. Clearing the state is not
    // enough: the narrowing lives on the server, so a list left holding the
    // filtered page shows fewer recordings than the URL says it should.
    await openList(tester, null);

    expect(api.askedFlags.last, isNull);
  });
}
