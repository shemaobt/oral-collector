/// What the list itself has to say once a pendency filter is on (ENG-381).
///
/// Landing in a narrowed list with nothing on screen to say so is the worst
/// outcome of this feature: the user reads a short list as the whole project.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_notifier.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_state.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/domain/entities/review_pendency.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recordings_list_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recordings_list_state.dart';
import 'package:oral_collector/features/recording/presentation/recordings_list_screen.dart';
import 'package:oral_collector/features/recording/presentation/widgets/active_filter_chips.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';

import '../../../support/text_scale.dart';

final _l10n = AppLocalizationsEn();

const _project = Project(id: 'p1', name: 'Kwanga stories', languageId: 'l1');

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
  }) async => const [];

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

/// Counts refetches. Kept outside the notifier: a public field on a Notifier
/// trips `avoid_public_notifier_properties`.
var _fetchCalls = 0;

/// A settled list. The filter is not preset: the screen is expected to apply
/// the one it was opened with, and a preset would hide it failing to.
class _SettledListNotifier extends RecordingsListNotifier {
  _SettledListNotifier(this._initial);

  final RecordingsListState _initial;

  @override
  RecordingsListState build() => _initial;

  @override
  Future<void> fetchRecordings() async {
    _fetchCalls++;
  }
}

const _settledEmpty = RecordingsListState(isLoading: false, hasMore: false);

LocalRecordingEntity _entity(String id) => LocalRecordingEntity(
  id: id,
  projectId: 'p1',
  genreId: 'g1',
  title: 'Story $id',
  durationSeconds: 30,
  fileSizeBytes: 1024,
  format: 'm4a',
  localFilePath: '/tmp/$id.m4a',
  uploadStatus: 'uploaded',
  cleaningStatus: 'none',
  recordedAt: DateTime(2026, 1, 1),
  createdAt: DateTime(2026, 1, 1),
  retryCount: 0,
  uploadedBytes: 0,
);

List<Override> _overrides({bool online = false}) => [
  recordingApiRepositoryProvider.overrideWithValue(_FakeApi()),
  localRecordingRepositoryProvider.overrideWithValue(_FakeLocal()),
  projectNotifierProvider.overrideWith(_FakeProjectNotifier.new),
  genreNotifierProvider.overrideWith(_FakeGenreNotifier.new),
  syncNotifierProvider.overrideWith(() => _SyncNotifierAt(online: online)),
];

/// Pumps the list screen already opened on a pendency filter, over [listState].
Future<void> pumpList(
  WidgetTester tester, {
  required RecordingsListState listState,
  bool online = false,
}) async {
  await pumpAtTextScale(
    tester,
    overrides: [
      ..._overrides(online: online),
      recordingsListNotifierProvider.overrideWith(
        () => _SettledListNotifier(listState),
      ),
    ],
    child: const RecordingsListScreen(
      initialReviewFlag: PendencyKind.classification,
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// The chips run against the real notifier: the point is that removing the chip
/// really widens the list, not that a fake was called.
Future<ProviderContainer> pumpChips(
  WidgetTester tester,
  PendencyKind kind,
) async {
  await pumpAtTextScale(
    tester,
    overrides: _overrides(),
    child: const Align(
      alignment: Alignment.topCenter,
      child: ActiveFilterChips(),
    ),
  );
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ActiveFilterChips)),
  );
  await container
      .read(recordingsListNotifierProvider.notifier)
      .setReviewFlagFilter(kind);
  await tester.pump();
  return container;
}

void main() {
  testWidgets('a filtered list says which pendency it is showing', (
    tester,
  ) async {
    await pumpChips(tester, PendencyKind.storyteller);

    expect(find.text(_l10n.recording_pendencyStoryteller), findsOneWidget);
  });

  testWidgets('the chip gives the whole project back', (tester) async {
    final container = await pumpChips(tester, PendencyKind.classification);

    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();

    expect(
      container.read(recordingsListNotifierProvider).selectedReviewFlag,
      isNull,
    );
    expect(find.byType(InputChip), findsNothing);
  });

  testWidgets('offline under a filter explains itself instead of claiming '
      'there are no recordings', (tester) async {
    await pumpList(tester, listState: _settledEmpty);

    expect(find.text(_l10n.recordings_offlineFilterTitle), findsOneWidget);
    expect(find.text(_l10n.recordings_noRecordings), findsNothing);
  });

  testWidgets('a fetch that failed under a filter is not reported as an '
      'empty project', (tester) async {
    // Online, with a 5xx or a timeout behind the empty list. Saying "no
    // recordings yet" here tells the user the work is finished seconds after
    // the project screen said three recordings still need details.
    await pumpList(
      tester,
      online: true,
      listState: _settledEmpty.copyWith(fetchFailed: true),
    );

    expect(find.text(_l10n.recordings_filterErrorTitle), findsOneWidget);
    expect(find.text(_l10n.recordings_noRecordings), findsNothing);
    // The connection is not the cause and must not be named as one.
    expect(find.text(_l10n.recordings_offlineFilterTitle), findsNothing);
  });

  testWidgets('offline is named as the cause only when it is the cause', (
    tester,
  ) async {
    await pumpList(tester, listState: _settledEmpty);

    expect(find.text(_l10n.recordings_filterErrorTitle), findsNothing);
  });

  testWidgets('the way out of a failed fetch is to ask again, not to give up '
      'the filter', (tester) async {
    await pumpList(
      tester,
      online: true,
      listState: _settledEmpty.copyWith(fetchFailed: true),
    );
    final before = _fetchCalls;

    await tester.tap(find.widgetWithText(FilledButton, _l10n.common_retry));
    await tester.pump();

    expect(_fetchCalls, greaterThan(before));
  });

  testWidgets('a sieve applied on this device is not blamed on the '
      'connection', (tester) async {
    // Offline and filtered, but the list is empty because of the search box,
    // not because the server could not be reached. Blaming connectivity for a
    // local filter sends the user to look for a signal they do not need.
    await pumpList(
      tester,
      listState: _settledEmpty.copyWith(
        recordings: [_entity('r1')],
        searchQuery: 'nothing matches this',
      ),
    );

    expect(find.text(_l10n.recordings_offlineFilterTitle), findsNothing);
    expect(find.text(_l10n.recordings_noRecordings), findsOneWidget);
  });
}
