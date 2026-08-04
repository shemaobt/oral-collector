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

class _OfflineSyncNotifier extends SyncNotifier {
  @override
  SyncState build() => const SyncState(isOnline: false);

  @override
  Future<void> processQueue() async {}
}

/// A settled, empty list. The filter is not preset: the screen is expected to
/// apply the one it was opened with, and a preset would hide it failing to.
class _SettledListNotifier extends RecordingsListNotifier {
  @override
  RecordingsListState build() =>
      const RecordingsListState(isLoading: false, hasMore: false);

  @override
  Future<void> fetchRecordings() async {}
}

List<Override> _overrides() => [
  recordingApiRepositoryProvider.overrideWithValue(_FakeApi()),
  localRecordingRepositoryProvider.overrideWithValue(_FakeLocal()),
  projectNotifierProvider.overrideWith(_FakeProjectNotifier.new),
  genreNotifierProvider.overrideWith(_FakeGenreNotifier.new),
  syncNotifierProvider.overrideWith(_OfflineSyncNotifier.new),
];

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
    await pumpAtTextScale(
      tester,
      overrides: [
        ..._overrides(),
        recordingsListNotifierProvider.overrideWith(_SettledListNotifier.new),
      ],
      child: const RecordingsListScreen(
        initialReviewFlag: PendencyKind.classification,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(_l10n.recordings_offlineFilterTitle), findsOneWidget);
    expect(find.text(_l10n.recordings_noRecordings), findsNothing);
  });
}
