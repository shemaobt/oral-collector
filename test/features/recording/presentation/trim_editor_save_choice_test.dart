import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/local_recording_to_entity.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/data/services/waveform_loader.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_player_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/trim_editor_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/trim_editor_state.dart';
import 'package:oral_collector/features/recording/presentation/trim_edit_decision.dart';
import 'package:oral_collector/features/recording/presentation/trim_editor_screen.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

import '../../../support/text_scale.dart';

const _recordingId = 'rec-1';
const _keepSeparate = 'Manter segmentos separados';
const _saveAsNew = 'Salvar como nova gravação';
const _removeStretch = 'Remover trecho';

class _MockPlayer extends Mock implements AudioPlayer {}

class _FakeTrimEditorNotifier extends TrimEditorNotifier {
  _FakeTrimEditorNotifier({
    required LocalRecordingEntity recording,
    required Set<int> excluded,
  }) : _recording = recording,
       _excluded = excluded;

  final LocalRecordingEntity _recording;
  final Set<int> _excluded;
  final List<TrimSaveMode?> _savedWith = [];

  @override
  TrimEditorState build(String arg) => TrimEditorState(
    recording: _recording,
    isLoading: false,
    totalDuration: const Duration(seconds: 60),
    splitPoints: const [1 / 3, 1 / 2],
    excludedSegments: _excluded,
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
    TrimSaveMode? mode,
  }) async {
    _savedWith.add(mode);
    return const TrimSaveAborted();
  }
}

void main() {
  late AppDatabase db;
  late LocalRecordingEntity recording;
  late _MockPlayer player;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = LocalRecordingRepository(db);
    await repo.insertRecording(
      LocalRecordingsCompanion(
        id: const Value(_recordingId),
        projectId: const Value('proj'),
        genreId: const Value('g0'),
        title: const Value('Story'),
        durationSeconds: const Value(60.0),
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
    ).thenAnswer((_) async => const Duration(seconds: 60));
    when(() => player.duration).thenReturn(const Duration(seconds: 60));
    when(
      () => player.positionStream,
    ).thenAnswer((_) => Stream.value(Duration.zero));
    when(
      () => player.playerStateStream,
    ).thenAnswer((_) => const Stream<PlayerState>.empty());
  });

  tearDown(() => db.close());

  Future<void> pumpEditor(
    WidgetTester tester,
    _FakeTrimEditorNotifier fake,
  ) async {
    await pumpAtTextScale(
      tester,
      size: const Size(1200, 1600),
      locale: const Locale('pt'),
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

  Finder inSaveStep(String text) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  testWidgets('the save step offers the three options in Portuguese when a '
      'stretch is excluded', (tester) async {
    final fake = _FakeTrimEditorNotifier(recording: recording, excluded: {1});
    await pumpEditor(tester, fake);

    await tester.tap(find.byType(ElevatedButton));
    await settle(tester);

    final tops = [
      for (final label in [_keepSeparate, _saveAsNew, _removeStretch])
        tester.getTopLeft(inSaveStep(label)).dy,
    ];
    expect(tops[0], lessThan(tops[1]));
    expect(tops[1], lessThan(tops[2]));
    expect(inSaveStep('Cancelar'), findsOneWidget);
    expect(inSaveStep('Salvar alterações?'), findsOneWidget);
    expect(
      inSaveStep(
        'A gravação original só é mantida em "Salvar como nova gravação".',
      ),
      findsOneWidget,
    );
  });

  testWidgets('each option saves with its own mode and Cancelar saves '
      'nothing', (tester) async {
    final picks = {
      _keepSeparate: TrimSaveMode.split,
      _saveAsNew: TrimSaveMode.saveAsNew,
      _removeStretch: TrimSaveMode.removeStretch,
    };
    final fake = _FakeTrimEditorNotifier(recording: recording, excluded: {1});
    await pumpEditor(tester, fake);

    for (final label in [...picks.keys, 'Cancelar']) {
      await tester.tap(find.byType(ElevatedButton));
      await settle(tester);
      await tester.tap(inSaveStep(label));
      await settle(tester);
    }

    expect(fake._savedWith, picks.values.toList());
  });

  testWidgets('a save with split marks and nothing excluded keeps today\'s '
      'confirm and splits', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('pt'));
    final fake = _FakeTrimEditorNotifier(recording: recording, excluded: {});
    await pumpEditor(tester, fake);

    await tester.tap(find.byType(ElevatedButton));
    await settle(tester);

    expect(find.text(l10n.trim_saveConfirmBody(3)), findsOneWidget);
    expect(find.text(_removeStretch), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, l10n.common_save));
    await settle(tester);

    expect(fake._savedWith, [TrimSaveMode.split]);
  });
}
