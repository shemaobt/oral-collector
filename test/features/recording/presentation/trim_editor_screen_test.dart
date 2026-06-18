/// Characterization gate for TrimEditorScreen (ENG-193).
///
/// Pins the *observable load behaviour* of the current screen so the upcoming
/// extraction of a TrimEditorNotifier cannot change it. These cases drive the
/// real widget and assert only on rendered output, so they must keep passing
/// byte-for-byte after the orchestration moves into the notifier (Step 3) and
/// the widget is re-pointed at the provider (Step 3e).
///
/// Scope note: the save orchestration and the editing mutations (split/exclude/
/// taxonomy/gain) are driven only through gesture-heavy custom widgets and a
/// private editing state that cannot be set without those gestures. Pinning
/// them through the real UI here would be brittle, so they are characterized at
/// the notifier level instead (trim_editor_notifier_test.dart), plus widget
/// delegation tests that override the provider. This file pins load resolution
/// — the part of the orchestration with the most branching (404 vs error vs
/// file-unavailable vs not-found).
library;

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/data/services/waveform_loader.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_player_notifier.dart';
import 'package:oral_collector/features/recording/presentation/trim_editor_screen.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/shared/utils/error_helpers.dart';

import '../../../support/text_scale.dart';

class _MockPlayer extends Mock implements AudioPlayer {}

class _FakeApiRepo implements RecordingApiRepository {
  _FakeApiRepo(this._getRecording);
  final Future<ServerRecording> Function(String id) _getRecording;
  @override
  Future<ServerRecording> getRecording(String id) => _getRecording(id);
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected');
}

void main() {
  const recordingId = 'rec-1';

  late AppDatabase db;
  late LocalRecordingRepository repo;
  late _MockPlayer player;
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);
    player = _MockPlayer();
    when(() => player.dispose()).thenAnswer((_) async {});
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.pause()).thenAnswer((_) async {});
    when(
      () => player.setFilePath(any()),
    ).thenAnswer((_) async => const Duration(seconds: 30));
    when(
      () => player.setUrl(any()),
    ).thenAnswer((_) async => const Duration(seconds: 30));
    when(() => player.duration).thenReturn(const Duration(seconds: 30));
    when(
      () => player.positionStream,
    ).thenAnswer((_) => Stream.value(Duration.zero));
    when(
      () => player.playerStateStream,
    ).thenAnswer((_) => const Stream<PlayerState>.empty());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seed({required String localFilePath}) async {
    await repo.insertRecording(
      LocalRecordingsCompanion(
        id: const Value(recordingId),
        projectId: const Value('project-1'),
        genreId: const Value('genre-1'),
        title: const Value('A Story'),
        durationSeconds: const Value(30.0),
        fileSizeBytes: const Value(100000),
        format: const Value('m4a'),
        localFilePath: Value(localFilePath),
        uploadStatus: const Value('local'),
        cleaningStatus: const Value('cleaned'),
        recordedAt: Value(DateTime.utc(2026, 5, 1, 10)),
      ),
    );
  }

  List<Override> overrides({
    required RecordingApiRepository api,
    bool fileExists = true,
  }) => [
    audioPlayerFactoryProvider.overrideWithValue(() => player),
    localRecordingRepositoryProvider.overrideWithValue(repo),
    recordingApiRepositoryProvider.overrideWithValue(api),
    fileExistsProvider.overrideWithValue((_) async => fileExists),
    waveformLoaderProvider.overrideWithValue(
      (path, {required int targetCount}) async =>
          List<double>.filled(targetCount, 0.5),
    ),
  ];

  Future<void> pumpScreen(
    WidgetTester tester, {
    required RecordingApiRepository api,
    bool fileExists = true,
  }) async {
    await pumpAtTextScale(
      tester,
      overrides: overrides(api: api, fileExists: fileExists),
      child: const TrimEditorScreen(recordingId: recordingId),
    );
  }

  Future<void> settleLoad(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  testWidgets('shows a spinner while the load is in flight', (tester) async {
    // Empty local repo -> the screen falls through to the server fetch, which
    // we hold open to observe the loading state, then release so no future is
    // left dangling at teardown.
    final gate = Completer<ServerRecording>();
    final api = _FakeApiRepo((_) => gate.future);
    await pumpScreen(tester, api: api);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(l10n.trim_notFound), findsNothing);

    gate.completeError(const ValidationException(statusCode: 404));
    await settleLoad(tester);
  });

  testWidgets('a 404 from the server renders the not-found state', (
    tester,
  ) async {
    final api = _FakeApiRepo(
      (_) async => throw const ValidationException(statusCode: 404),
    );
    await pumpScreen(tester, api: api);
    await settleLoad(tester);

    expect(find.text(l10n.trim_notFound), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(LucideIcons.downloadCloud), findsNothing);
  });

  testWidgets('a non-404 server error renders the error state, not not-found', (
    tester,
  ) async {
    const error = ServerException(statusCode: 500);
    final api = _FakeApiRepo((_) async => throw error);
    await pumpScreen(tester, api: api);
    await settleLoad(tester);

    expect(find.byIcon(LucideIcons.downloadCloud), findsOneWidget);
    expect(find.text(friendlyErrorFor(error, l10n)), findsOneWidget);
    expect(find.text(l10n.trim_notFound), findsNothing);
  });

  testWidgets('a recording whose local file is missing shows the '
      'download-first message', (tester) async {
    await seed(localFilePath: '/audio/gone.m4a');
    final api = _FakeApiRepo((_) async => throw StateError('not expected'));
    await pumpScreen(tester, api: api, fileExists: false);
    await settleLoad(tester);

    expect(
      find.text(
        'Local audio file not available. Download the recording first.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a recording with a present local file loads into the editor', (
    tester,
  ) async {
    await seed(localFilePath: '/audio/present.m4a');
    final api = _FakeApiRepo((_) async => throw StateError('not expected'));
    await pumpScreen(tester, api: api, fileExists: true);
    await settleLoad(tester);

    // Out of every non-loaded "problem" state and into the editor: the empty
    // segment-list instructions are the editor's no-splits affordance.
    expect(find.text(l10n.trim_instructions), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(l10n.trim_notFound), findsNothing);
    expect(find.byIcon(LucideIcons.downloadCloud), findsNothing);
  });
}
