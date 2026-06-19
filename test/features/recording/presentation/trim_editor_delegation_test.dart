/// Widget-delegation tests for TrimEditorScreen (ENG-193): the screen no longer
/// owns the save orchestration, so these pin that the action bar delegates to
/// TrimEditorNotifier and renders the outcome. The notifier is replaced by a
/// fake so the test exercises the widget wiring (button -> confirm -> saveSplit
/// -> snackbar) without the real orchestration. The failure path navigates
/// nowhere, so it needs no router.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/features/recording/data/local_recording_to_entity.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/data/services/waveform_loader.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_player_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/trim_editor_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/trim_editor_state.dart';
import 'package:oral_collector/features/recording/presentation/trim_editor_screen.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/shared/utils/error_helpers.dart';

import '../../../support/text_scale.dart';

const _recordingId = 'rec-1';

class _MockPlayer extends Mock implements AudioPlayer {}

class _FakeTrimEditorNotifier extends TrimEditorNotifier {
  _FakeTrimEditorNotifier({
    required LocalRecordingEntity recording,
    required TrimSaveOutcome outcome,
    bool isSaving = false,
  }) : _recording = recording,
       _outcome = outcome,
       _isSaving = isSaving;

  // Private to satisfy avoid_public_notifier_properties; read in-file by tests.
  final LocalRecordingEntity _recording;
  final TrimSaveOutcome _outcome;
  final bool _isSaving;
  int _saveCalls = 0;

  @override
  TrimEditorState build(String arg) => TrimEditorState(
    recording: _recording,
    isLoading: false,
    isSaving: _isSaving,
    totalDuration: const Duration(seconds: 10),
    splitPoints: const [0.5],
  );

  @override
  Future<void> load({required bool isWeb}) async {}
  @override
  void completeLoad({required Duration totalDuration}) {}
  @override
  void setUnavailable(String message) {}

  @override
  Future<TrimSaveOutcome> saveSplit({
    required bool isWeb,
    required String localeTag,
  }) async {
    _saveCalls++;
    return _outcome;
  }
}

void main() {
  late AppDatabase db;
  late LocalRecordingRepository repo;
  late _MockPlayer player;
  late AppLocalizations l10n;
  late LocalRecordingEntity recording;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);
    await repo.insertRecording(
      LocalRecordingsCompanion(
        id: const Value(_recordingId),
        projectId: const Value('proj'),
        genreId: const Value('g0'),
        title: const Value('Story'),
        durationSeconds: const Value(10.0),
        fileSizeBytes: const Value(1000),
        format: const Value('m4a'),
        localFilePath: const Value('/audio/in.m4a'),
        uploadStatus: const Value('local'),
        cleaningStatus: const Value('cleaned'),
        recordedAt: Value(DateTime.utc(2026, 5, 1)),
      ),
    );
    recording = localRecordingToEntity(
      (await repo.getRecordingById(_recordingId))!,
    );

    player = _MockPlayer();
    when(() => player.dispose()).thenAnswer((_) async {});
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.pause()).thenAnswer((_) async {});
    when(
      () => player.setFilePath(any()),
    ).thenAnswer((_) async => const Duration(seconds: 10));
    when(() => player.duration).thenReturn(const Duration(seconds: 10));
    when(
      () => player.positionStream,
    ).thenAnswer((_) => Stream.value(Duration.zero));
    when(
      () => player.playerStateStream,
    ).thenAnswer((_) => const Stream<PlayerState>.empty());
  });

  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester, _FakeTrimEditorNotifier fake) async {
    await pumpAtTextScale(
      tester,
      // A roomy canvas: the waveform panel's segment row overflows a phone
      // width once there are splits (a pre-existing layout trait, unrelated to
      // the delegation under test).
      size: const Size(1200, 1600),
      overrides: [
        audioPlayerFactoryProvider.overrideWithValue(() => player),
        fileExistsProvider.overrideWithValue((_) async => true),
        waveformLoaderProvider.overrideWithValue(
          (path, {required int targetCount}) async =>
              List<double>.filled(targetCount, 0.5),
        ),
        trimEditorProvider.overrideWith(() => fake),
      ],
      child: const TrimEditorScreen(recordingId: _recordingId),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  testWidgets('tapping save confirms then delegates to the notifier; a failed '
      'outcome shows the split-error snackbar', (tester) async {
    final fake = _FakeTrimEditorNotifier(
      recording: recording,
      outcome: const TrimSaveFailed(ServerException(statusCode: 500)),
    );
    await pump(tester, fake);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(find.text(l10n.trim_saveConfirmTitle), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, l10n.common_save));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(fake._saveCalls, 1);
    expect(
      find.text(
        l10n.trim_splitError(
          friendlyErrorFor(const ServerException(statusCode: 500), l10n),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('while saving, the action button is disabled and shows the '
      'splitting label', (tester) async {
    final fake = _FakeTrimEditorNotifier(
      recording: recording,
      outcome: const TrimSaveAborted(),
      isSaving: true,
    );
    await pump(tester, fake);

    expect(find.text(l10n.trim_splitting), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
    expect(fake._saveCalls, 0);
  });
}
