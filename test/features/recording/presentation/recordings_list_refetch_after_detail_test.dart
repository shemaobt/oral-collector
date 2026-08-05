/// Coming back from the detail screen has to ask the server again (ENG-383).
///
/// The list under a pendency filter is the server's answer, and correcting the
/// recording in the detail screen changes that answer: the server recomputes
/// the review flags on every write, so the corrected recording is no longer
/// part of the filtered set. Without a refetch on return, the user fixes a
/// recording and watches it stay in the list of things still to fix.
///
/// Nothing covered the detail-to-list loop before this beyond the title patch,
/// so the behaviour was one edit away from being lost silently.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_notifier.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_state.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/review_flag.dart';
import 'package:oral_collector/features/recording/domain/entities/review_pendency.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';
import 'package:oral_collector/features/recording/presentation/recordings_list_screen.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_card.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

const _project = Project(id: 'p1', name: 'Kwanga stories', languageId: 'l1');

final _flagged = ServerRecording(
  id: 'r1',
  projectId: 'p1',
  genreId: 'g1',
  title: 'The hunter and the river',
  durationSeconds: 42,
  fileSizeBytes: 2048,
  format: 'm4a',
  uploadStatus: 'uploaded',
  cleaningStatus: 'none',
  recordedAt: DateTime(2026, 1, 1),
  reviewFlags: const [
    ReviewFlag(code: 'missing_storyteller', origin: 'system'),
  ],
);

/// Answers every listing with the one flagged recording, counting the asks.
class _CountingApi implements RecordingApiRepository {
  var listCalls = 0;

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
    listCalls++;
    return [_flagged];
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

class _OnlineSync extends SyncNotifier {
  @override
  SyncState build() => const SyncState(isOnline: true);

  @override
  Future<void> processQueue() async {}
}

void main() {
  testWidgets('returning from a recording asks the server for the list again', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final api = _CountingApi();
    // A stand-in for the detail screen: the real one is a different unit, and
    // what matters here is only that the list gets control back on pop.
    final router = GoRouter(
      initialLocation: '/recordings',
      routes: [
        GoRoute(
          path: '/recordings',
          builder: (_, _) => const RecordingsListScreen(
            initialReviewFlag: PendencyKind.storyteller,
          ),
        ),
        GoRoute(
          path: '/recording/:id',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.pop(),
                child: const Text('done'),
              ),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recordingApiRepositoryProvider.overrideWithValue(api),
          localRecordingRepositoryProvider.overrideWithValue(_FakeLocal()),
          projectNotifierProvider.overrideWith(_FakeProjectNotifier.new),
          genreNotifierProvider.overrideWith(_FakeGenreNotifier.new),
          syncNotifierProvider.overrideWith(_OnlineSync.new),
        ],
        child: MaterialApp.router(
          routerConfig: router,
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
    await tester.pumpAndSettle();

    expect(find.byType(RecordingCard), findsOneWidget);
    final asksBeforeOpening = api.listCalls;

    await tester.tap(find.byType(RecordingCard));
    await tester.pumpAndSettle();
    expect(find.text('done'), findsOneWidget);

    await tester.tap(find.text('done'));
    await tester.pumpAndSettle();

    expect(find.byType(RecordingCard), findsOneWidget);
    expect(api.listCalls, greaterThan(asksBeforeOpening));
  });
}
