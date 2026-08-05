/// The sheet has to own every filter the badge counts (ENG-383).
///
/// `activeFilterCount` counts the pendency, so the badge says "1" and sends the
/// user to a sheet that never knew the filter existed: nothing reads as
/// selected, and Reset followed by Apply leaves it standing. Only the chip on
/// the list could remove it, which makes the badge point at the wrong place.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/l10n/content_l10n.dart';
import 'package:oral_collector/features/genre/domain/entities/genre.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_notifier.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_state.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/presentation/notifiers/member_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/member_state.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/review_pendency.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recordings_list_notifier.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recordings_filter_sheet.dart';
import 'package:oral_collector/features/storyteller/presentation/notifiers/project_storytellers_notifier.dart';
import 'package:oral_collector/features/storyteller/presentation/notifiers/project_storytellers_state.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';
import 'package:oral_collector/l10n/app_localizations_es.dart';

import '../../../../support/text_scale.dart';

final _l10n = AppLocalizationsEn();

const _project = Project(id: 'p1', name: 'Kwanga stories', languageId: 'l1');

/// Remembers the `review_flag` of every listing it was asked for, so a test can
/// check the filter reached the server rather than only the local state.
class _RecordingApi implements RecordingApiRepository {
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

const _genres = [
  Genre(id: 'g1', name: 'Kwanga tales'),
  Genre(id: 'g2', name: 'Ndoto songs'),
];

class _FakeGenreNotifier extends GenreNotifier {
  @override
  GenreState build() => const GenreState(genres: _genres);

  @override
  Future<void> fetchGenres() async {}
}

class _FakeStorytellersNotifier extends ProjectStorytellersNotifier {
  @override
  ProjectStorytellersState build() => const ProjectStorytellersState();

  @override
  Future<void> fetch(String projectId) async {}
}

class _FakeMemberNotifier extends MemberNotifier {
  @override
  MemberState build() => const MemberState();

  @override
  Future<void> fetchMembers(String projectId) async {}
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
  late _RecordingApi api;

  setUp(() => api = _RecordingApi());

  // The real list notifier throughout: the question is what the sheet does to
  // the filter the list holds, and a fake would answer a different one.
  List<Override> overrides({required bool online}) => [
    recordingApiRepositoryProvider.overrideWithValue(api),
    localRecordingRepositoryProvider.overrideWithValue(_FakeLocal()),
    projectNotifierProvider.overrideWith(_FakeProjectNotifier.new),
    genreNotifierProvider.overrideWith(_FakeGenreNotifier.new),
    projectStorytellersNotifierProvider.overrideWith(
      _FakeStorytellersNotifier.new,
    ),
    memberNotifierProvider.overrideWith(_FakeMemberNotifier.new),
    syncNotifierProvider.overrideWith(() => _SyncNotifierAt(online: online)),
  ];

  /// Pumps a host with a button that opens the sheet the way the list does, so
  /// the filter can be set on the notifier before the sheet's `initState` runs.
  Future<ProviderContainer> pumpHost(
    WidgetTester tester, {
    bool online = false,
    Locale locale = const Locale('en'),
  }) async {
    await pumpAtTextScale(
      tester,
      overrides: overrides(online: online),
      locale: locale,
      child: Builder(
        builder: (context) => TextButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const RecordingsFilterSheet(projectId: 'p1'),
          ),
          child: const Text('open'),
        ),
      ),
    );
    return ProviderScope.containerOf(tester.element(find.text('open')));
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> tapChip(WidgetTester tester, String label) async {
    final chip = find.widgetWithText(ChoiceChip, label);
    if (chip.evaluate().isEmpty) {
      // The sheet's list only builds what fits, and the genre chips are below
      // the fold on a phone.
      await tester.scrollUntilVisible(
        chip,
        200,
        scrollable: find
            .descendant(
              of: find.byType(RecordingsFilterSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
    }
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pump();
  }

  Future<void> apply(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(ElevatedButton, _l10n.filter_apply));
    await tester.pumpAndSettle();
  }

  testWidgets('the sheet opens showing the pendency the list is narrowed to', (
    tester,
  ) async {
    final container = await pumpHost(tester);
    await container
        .read(recordingsListNotifierProvider.notifier)
        .setReviewFlagFilter(PendencyKind.storyteller);
    await tester.pump();

    await openSheet(tester);

    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, _l10n.recording_pendencyStoryteller),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('Reset then Apply really drops the pendency', (tester) async {
    final container = await pumpHost(tester);
    await container
        .read(recordingsListNotifierProvider.notifier)
        .setReviewFlagFilter(PendencyKind.storyteller);
    await tester.pump();
    await openSheet(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, _l10n.filter_reset));
    await tester.pump();
    await apply(tester);

    expect(
      container.read(recordingsListNotifierProvider).selectedReviewFlag,
      isNull,
    );
  });

  testWidgets(
    'a pendency chosen in the sheet is what the server is asked for',
    (tester) async {
      final container = await pumpHost(tester, online: true);
      await openSheet(tester);

      await tapChip(tester, _l10n.recording_pendencyClassification);
      await apply(tester);

      expect(
        container.read(recordingsListNotifierProvider).selectedReviewFlag,
        PendencyKind.classification,
      );
      // The narrowing only exists on the server, so applying it without asking
      // again would leave the previous, wider page on screen.
      expect(api.askedFlags.last, 'missing_classification');
    },
  );

  testWidgets('the neutral chip widens the list back', (tester) async {
    final container = await pumpHost(tester);
    await container
        .read(recordingsListNotifierProvider.notifier)
        .setReviewFlagFilter(PendencyKind.description);
    await tester.pump();
    await openSheet(tester);

    await tapChip(tester, _l10n.filter_pendencyAll);
    await apply(tester);

    expect(
      container.read(recordingsListNotifierProvider).selectedReviewFlag,
      isNull,
    );
  });

  testWidgets('the two chips that share a name are told apart by section', (
    tester,
  ) async {
    // Spanish reads "Sin clasificar" for both the status chip and the pendency
    // chip. Seven of the eleven languages do; English is one of the four that
    // hide it. Both stay: the status one is the offline answer, and this app is
    // used in the field. So the section they sit in is what has to distinguish
    // them.
    final es = AppLocalizationsEs();
    expect(es.filter_unclassified, es.recording_pendencyClassification);

    await pumpHost(tester, locale: const Locale('es'));
    await openSheet(tester);

    final homonym = find.widgetWithText(
      ChoiceChip,
      es.recording_pendencyClassification,
    );
    expect(homonym, findsNWidgets(2));

    Finder inSection(String title) => find.descendant(
      of: find.widgetWithText(FilterSection, title),
      matching: homonym,
    );
    expect(inSection(es.filters_sectionStatus), findsOneWidget);
    expect(inSection(es.filters_sectionPendency), findsOneWidget);

    // The headers are what the reader has to go on, so they cannot collide the
    // way the chips do, and each carries the line that says what it costs.
    expect(es.filters_sectionStatus, isNot(es.filters_sectionPendency));
    expect(find.text(es.filters_sectionStatusHint), findsOneWidget);
    expect(find.text(es.filters_sectionPendencyHint), findsOneWidget);
  });

  testWidgets('Reset then Apply drops the subcategory the badge counts', (
    tester,
  ) async {
    // `/recordings?genreId=…&subcategoryId=…` is a live route (the genre
    // detail screen), and `activeFilterCount` counts the subcategory, so the
    // sheet has to be able to clear what the badge is counting.
    final container = await pumpHost(tester);
    final notifier = container.read(recordingsListNotifierProvider.notifier);
    notifier.setGenreFilter('g1');
    notifier.setSubcategoryFilter('s1');
    await tester.pump();
    await openSheet(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, _l10n.filter_reset));
    await tester.pump();
    await apply(tester);

    expect(container.read(recordingsListNotifierProvider).activeFilterCount, 0);
  });

  testWidgets('Apply keeps a subcategory the sheet never showed', (
    tester,
  ) async {
    final container = await pumpHost(tester);
    final notifier = container.read(recordingsListNotifierProvider.notifier);
    notifier.setGenreFilter('g1');
    notifier.setSubcategoryFilter('s1');
    await tester.pump();
    await openSheet(tester);

    // Changing something else entirely must not silently widen the list back
    // to the whole genre.
    await tapChip(tester, _l10n.filter_uploaded);
    await apply(tester);

    final state = container.read(recordingsListNotifierProvider);
    expect(state.selectedSubcategoryId, 's1');
    expect(state.selectedGenreId, 'g1');
  });

  testWidgets('picking another genre drops the subcategory under it', (
    tester,
  ) async {
    final container = await pumpHost(tester);
    final notifier = container.read(recordingsListNotifierProvider.notifier);
    notifier.setGenreFilter('g1');
    notifier.setSubcategoryFilter('s1');
    await tester.pump();
    await openSheet(tester);

    await tapChip(tester, localizedGenreName(_l10n, _genres[1].name));
    await apply(tester);

    final state = container.read(recordingsListNotifierProvider);
    expect(state.selectedGenreId, 'g2');
    // A refinement of the genre it came with. Kept under a different genre it
    // would narrow the list to nothing while the badge counted it.
    expect(state.selectedSubcategoryId, isNull);
  });
}
