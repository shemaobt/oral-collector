import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/data/services/waveform_loader.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_player_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/trim_editor_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/trim_editor_state.dart';
import 'package:oral_collector/features/recording/presentation/trim_editor_screen.dart';
import 'package:oral_collector/features/recording/presentation/widgets/edit_transport_bar.dart';
import 'package:oral_collector/features/recording/presentation/widgets/exclude_range_handles.dart';
import 'package:oral_collector/features/recording/presentation/widgets/trim_waveform.dart';

import 'package:oral_collector/l10n/app_localizations.dart';

import '../../../support/text_scale.dart';

const _recordingId = 'rec-1';
const _excludeRange = 'Excluir trecho';

class _MockPlayer extends Mock implements AudioPlayer {}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  late AppDatabase db;
  late _MockPlayer player;

  setUp(() => player = _MockPlayer());

  tearDown(() => db.close());

  Future<void> openEditor(WidgetTester tester, {required int seconds}) async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await LocalRecordingRepository(db).insertRecording(
      LocalRecordingsCompanion(
        id: const Value(_recordingId),
        projectId: const Value('proj'),
        genreId: const Value('g0'),
        title: const Value('Story'),
        durationSeconds: Value(seconds.toDouble()),
        fileSizeBytes: const Value(1000),
        format: const Value('m4a'),
        localFilePath: const Value('/audio/story.m4a'),
        uploadStatus: const Value('local'),
        cleaningStatus: const Value('cleaned'),
        recordedAt: Value(DateTime.utc(2026, 5, 1)),
      ),
    );
    final total = Duration(seconds: seconds);
    when(() => player.dispose()).thenAnswer((_) async {});
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.pause()).thenAnswer((_) async {});
    when(() => player.play()).thenAnswer((_) async {});
    when(() => player.seek(any())).thenAnswer((_) async {});
    when(() => player.setVolume(any())).thenAnswer((_) async {});
    when(() => player.setFilePath(any())).thenAnswer((_) async => total);
    when(() => player.duration).thenReturn(total);
    when(() => player.playing).thenReturn(false);
    when(
      () => player.positionStream,
    ).thenAnswer((_) => Stream.value(Duration.zero));
    when(
      () => player.playerStateStream,
    ).thenAnswer((_) => const Stream<PlayerState>.empty());

    await pumpAtTextScale(
      tester,
      size: const Size(400, 1600),
      locale: const Locale('pt'),
      overrides: [
        audioPlayerFactoryProvider.overrideWithValue(() => player),
        localRecordingRepositoryProvider.overrideWithValue(
          LocalRecordingRepository(db),
        ),
        fileExistsProvider.overrideWithValue((_) async => true),
        waveformLoaderProvider.overrideWithValue(
          (path, {required int targetCount}) async =>
              List<double>.filled(targetCount, 0.5),
        ),
      ],
      child: const TrimEditorScreen(recordingId: _recordingId),
    );
    await settle(tester);
  }

  TrimEditorState editorState(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(TrimEditorScreen)),
  ).read(trimEditorProvider(_recordingId));

  Rect waveformRect(WidgetTester tester) {
    final box = tester.renderObject<RenderBox>(find.byType(TrimWaveform));
    return box.localToGlobal(Offset.zero) & box.size;
  }

  TrimEditorNotifier editor(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(TrimEditorScreen)),
  ).read(trimEditorProvider(_recordingId).notifier);

  Future<void> placePlayheadAt(
    WidgetTester tester,
    num seconds,
    int total,
  ) async {
    final rect = waveformRect(tester);
    await tester.tapAt(
      Offset(rect.left + rect.width * seconds / total, rect.center.dy),
    );
    await settle(tester);
  }

  Future<void> pressExcludeRange(WidgetTester tester) async {
    await tester.tap(find.text(_excludeRange));
    await settle(tester);
  }

  Finder handle(Key key) => find.byKey(key);
  Finder handleTime(Key key, String time) =>
      find.descendant(of: handle(key), matching: find.text(time));

  Future<void> dragHandleBy(
    WidgetTester tester,
    Key key,
    double seconds,
    int total,
  ) async {
    final pxPerSecond = waveformRect(tester).width / total;
    await tester.dragFrom(
      tester.getCenter(handle(key)),
      Offset(seconds * pxPerSecond, 0),
    );
    await settle(tester);
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.byKey(kExcludeRangeConfirmKey));
    await settle(tester);
  }

  testWidgets('Pressing «Excluir trecho» with the playhead at 25 s of a 60 s '
      'recording shows handles at 20 s and 30 s', (tester) async {
    await openEditor(tester, seconds: 60);
    await placePlayheadAt(tester, 25, 60);

    await pressExcludeRange(tester);

    expect(handleTime(kExcludeRangeStartHandleKey, '00:20.00'), findsOneWidget);
    expect(handleTime(kExcludeRangeEndHandleKey, '00:30.00'), findsOneWidget);
  });

  testWidgets('Confirming handles dragged to 18 s and 32 s excludes that '
      'range without adding a split mark', (tester) async {
    await openEditor(tester, seconds: 60);
    await placePlayheadAt(tester, 25, 60);
    await pressExcludeRange(tester);

    await dragHandleBy(tester, kExcludeRangeStartHandleKey, -2, 60);
    await dragHandleBy(tester, kExcludeRangeEndHandleKey, 2, 60);
    await confirm(tester);

    final state = editorState(tester);
    expect(state.excludedRanges, hasLength(1));
    expect(state.excludedRanges.single.startFraction * 60, closeTo(18, 0.01));
    expect(state.excludedRanges.single.endFraction * 60, closeTo(32, 0.01));
    expect(state.splitPoints, isEmpty);
    expect(state.segmentCount, 1);
    expect(handle(kExcludeRangeStartHandleKey), findsNothing);
  });

  testWidgets('Saving after confirming an excluded range offers the three '
      'options', (tester) async {
    await openEditor(tester, seconds: 60);
    await placePlayheadAt(tester, 25, 60);
    await pressExcludeRange(tester);
    await confirm(tester);

    await tester.tap(find.byType(ElevatedButton));
    await settle(tester);

    for (final option in [
      'Manter segmentos separados',
      'Salvar como nova gravação',
      'Remover trecho',
    ]) {
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(option),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('Pressing then cancelling «Excluir trecho» excludes nothing', (
    tester,
  ) async {
    await openEditor(tester, seconds: 60);
    await placePlayheadAt(tester, 25, 60);
    await pressExcludeRange(tester);

    await tester.tap(find.byKey(kExcludeRangeCancelKey));
    await settle(tester);

    expect(editorState(tester).excludedRanges, isEmpty);
    expect(handle(kExcludeRangeStartHandleKey), findsNothing);
    expect(handle(kExcludeRangeEndHandleKey), findsNothing);
  });

  testWidgets('Restoring before saving makes the recording whole again', (
    tester,
  ) async {
    await openEditor(tester, seconds: 60);
    await placePlayheadAt(tester, 25, 60);
    await pressExcludeRange(tester);
    await confirm(tester);

    await tester.tap(find.text('Restaurar todos'));
    await settle(tester);

    expect(editorState(tester).excludedRanges, isEmpty);
    final save = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(save.onPressed, isNull);
  });

  testWidgets('With the playhead at 2 s the start handle sits at 0 s', (
    tester,
  ) async {
    await openEditor(tester, seconds: 60);
    await placePlayheadAt(tester, 2, 60);

    await pressExcludeRange(tester);

    expect(handleTime(kExcludeRangeStartHandleKey, '00:00.00'), findsOneWidget);
    expect(handleTime(kExcludeRangeEndHandleKey, '00:07.00'), findsOneWidget);
  });

  testWidgets('A range that would leave nothing kept cannot be confirmed', (
    tester,
  ) async {
    await openEditor(tester, seconds: 8);
    await placePlayheadAt(tester, 4, 8);
    await pressExcludeRange(tester);
    expect(handleTime(kExcludeRangeStartHandleKey, '00:00.00'), findsOneWidget);
    expect(handleTime(kExcludeRangeEndHandleKey, '00:08.00'), findsOneWidget);

    await confirm(tester);

    expect(
      find.text('Pelo menos um segmento deve ser mantido'),
      findsOneWidget,
    );
    expect(editorState(tester).excludedRanges, isEmpty);
  });

  testWidgets('The start handle cannot be dragged past the end handle', (
    tester,
  ) async {
    await openEditor(tester, seconds: 60);
    await placePlayheadAt(tester, 25, 60);
    await pressExcludeRange(tester);

    await dragHandleBy(tester, kExcludeRangeStartHandleKey, 25, 60);

    expect(handleTime(kExcludeRangeStartHandleKey, '00:29.75'), findsOneWidget);
    expect(handleTime(kExcludeRangeEndHandleKey, '00:30.00'), findsOneWidget);
  });

  testWidgets('The end handle cannot be dragged back past the start handle', (
    tester,
  ) async {
    await openEditor(tester, seconds: 60);
    await placePlayheadAt(tester, 25, 60);
    await pressExcludeRange(tester);

    await dragHandleBy(tester, kExcludeRangeEndHandleKey, -25, 60);

    expect(handleTime(kExcludeRangeStartHandleKey, '00:20.00'), findsOneWidget);
    expect(handleTime(kExcludeRangeEndHandleKey, '00:20.25'), findsOneWidget);
  });

  testWidgets('Save stays disabled while the handles are open', (tester) async {
    await openEditor(tester, seconds: 60);
    await placePlayheadAt(tester, 25, 60);
    await pressExcludeRange(tester);
    await confirm(tester);
    await pressExcludeRange(tester);

    final save = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(save.onPressed, isNull);
  });

  testWidgets('A handle dropped 120 ms past a split mark lands on the mark', (
    tester,
  ) async {
    await openEditor(tester, seconds: 60);
    editor(tester).setSplitPoints([40 / 60]);
    await placePlayheadAt(tester, 25, 60);
    await pressExcludeRange(tester);

    await dragHandleBy(tester, kExcludeRangeEndHandleKey, 10.12, 60);

    expect(handleTime(kExcludeRangeEndHandleKey, '00:40.00'), findsOneWidget);
  });

  testWidgets('With the playhead at 5.1 s the start handle sits at 0 s', (
    tester,
  ) async {
    await openEditor(tester, seconds: 60);
    await placePlayheadAt(tester, 5.1, 60);

    await pressExcludeRange(tester);

    expect(handleTime(kExcludeRangeStartHandleKey, '00:00.00'), findsOneWidget);
  });

  testWidgets('With a range and no split mark the save button counts the two '
      'kept parts', (tester) async {
    await openEditor(tester, seconds: 60);
    await placePlayheadAt(tester, 25, 60);
    await pressExcludeRange(tester);
    await confirm(tester);

    expect(find.text('Salvar 2 segmentos'), findsOneWidget);
  });

  testWidgets('The scissors is withheld within 250 ms of a range edge', (
    tester,
  ) async {
    await openEditor(tester, seconds: 60);
    await placePlayheadAt(tester, 25, 60);
    await pressExcludeRange(tester);
    await confirm(tester);
    await placePlayheadAt(tester, 35, 60);
    expect(find.textContaining('00:35.'), findsOneWidget);

    await placePlayheadAt(tester, 30.1, 60);

    expect(find.textContaining('00:30.'), findsNothing);
  });

  testWidgets('Toggling a segment card off and on beside an excluded range '
      'keeps the split mark', (tester) async {
    await openEditor(tester, seconds: 60);
    editor(tester).setSplitPoints([40 / 60]);
    await placePlayheadAt(tester, 25, 60);
    await pressExcludeRange(tester);
    await dragHandleBy(tester, kExcludeRangeStartHandleKey, -2, 60);
    await dragHandleBy(tester, kExcludeRangeEndHandleKey, 2, 60);
    await confirm(tester);

    await tester.tap(find.byIcon(LucideIcons.trash2).at(1));
    await settle(tester);
    expect(editorState(tester).excludedSegments, {1});
    await tester.tap(find.byIcon(LucideIcons.rotateCcw));
    await settle(tester);

    final state = editorState(tester);
    expect(state.excludedSegments, isEmpty);
    expect(state.splitPoints, [40 / 60]);
    expect(state.excludedRanges, hasLength(1));
  });

  testWidgets('The segment card refuses an exclusion that would leave nothing '
      'kept beside a range', (tester) async {
    await openEditor(tester, seconds: 60);
    final notifier = editor(tester);
    notifier.setSplitPoints([40 / 60]);
    notifier.confirmExcludedRange(startFraction: 0, endFraction: 40 / 60);
    await settle(tester);

    await tester.tap(find.byIcon(LucideIcons.trash2).at(1));
    await settle(tester);

    expect(
      find.text('Pelo menos um segmento deve ser mantido'),
      findsOneWidget,
    );
    expect(editorState(tester).excludedSegments, isEmpty);
  });

  testWidgets('On the web the toolbar shows no «Excluir trecho» button', (
    tester,
  ) async {
    Widget bar({required bool isWeb}) => MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: EditTransportBar(
          isPlaying: false,
          position: Duration.zero,
          duration: const Duration(seconds: 60),
          onPlayPause: () {},
          isWeb: isWeb,
          onExcludeRange: () {},
        ),
      ),
    );

    await tester.pumpWidget(bar(isWeb: false));
    expect(find.text(_excludeRange), findsOneWidget);

    await tester.pumpWidget(bar(isWeb: true));
    expect(find.text(_excludeRange), findsNothing);
  });
}
