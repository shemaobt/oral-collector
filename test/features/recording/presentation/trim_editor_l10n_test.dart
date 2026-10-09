/// ENG-524: o editor de corte é a terceira tela da auditoria — o botão de
/// gravar o ajuste de volume ("Apply boost") está em inglês em sete idiomas,
/// árabe e chinês entre eles.
///
/// O mesmo arquivo carrega a outra metade da auditoria: duas chaves
/// classificadas como *coincidência legítima* — `trim_volume` e
/// `trim_segments`, que em francês se escrevem exatamente como em inglês —
/// ficam pinadas nos seus literais. O risco desta fatia não é deixar algo em
/// inglês, é "consertar" o que já estava certo, e essas duas são o que impede
/// uma varredura mecânica de traduzir palavras francesas.
///
/// O notifier é substituído por um falso porque o estado de edição (pontos de
/// corte, ganho) só é alcançável por gestos em widgets customizados — a mesma
/// razão dada em trim_editor_delegation_test.dart.
library;

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
import 'package:oral_collector/features/recording/presentation/trim_editor_screen.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/l10n/app_localizations_ar.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';
import 'package:oral_collector/l10n/app_localizations_hi.dart';
import 'package:oral_collector/l10n/app_localizations_zh.dart';

import '../../../support/text_scale.dart';

const _recordingId = 'rec-1';

class _MockPlayer extends Mock implements AudioPlayer {}

class _FakeTrimEditorNotifier extends TrimEditorNotifier {
  _FakeTrimEditorNotifier({
    required LocalRecordingEntity recording,
    required List<double> splitPoints,
    required double gainDb,
  }) : _recording = recording,
       _splitPoints = splitPoints,
       _gainDb = gainDb;

  // Private to satisfy avoid_public_notifier_properties; read in-file by tests.
  final LocalRecordingEntity _recording;
  final List<double> _splitPoints;
  final double _gainDb;

  @override
  TrimEditorState build(String arg) => TrimEditorState(
    recording: _recording,
    isLoading: false,
    totalDuration: const Duration(seconds: 10),
    splitPoints: _splitPoints,
    gainDb: _gainDb,
  );

  @override
  Future<void> load({required bool isWeb}) async {}
  @override
  void completeLoad({required Duration totalDuration}) {}
  @override
  void setUnavailable(String message) {}
}

void main() {
  late AppDatabase db;
  late LocalRecordingRepository repo;
  late _MockPlayer player;
  late LocalRecordingEntity recording;

  final en = AppLocalizationsEn();

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

  Future<void> pump(
    WidgetTester tester, {
    required String locale,
    required List<double> splitPoints,
    required double gainDb,
  }) async {
    await pumpAtTextScale(
      tester,
      locale: Locale(locale),
      // A roomy canvas: the waveform panel's segment row overflows a phone
      // width once there are splits (a pre-existing layout trait).
      size: const Size(1200, 1600),
      overrides: [
        audioPlayerFactoryProvider.overrideWithValue(() => player),
        fileExistsProvider.overrideWithValue((_) async => true),
        waveformLoaderProvider.overrideWithValue(
          (path, {required int targetCount}) async =>
              List<double>.filled(targetCount, 0.5),
        ),
        trimEditorProvider.overrideWith(
          () => _FakeTrimEditorNotifier(
            recording: recording,
            splitPoints: splitPoints,
            gainDb: gainDb,
          ),
        ),
      ],
      child: const TrimEditorScreen(recordingId: _recordingId),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  group('o editor de corte não fala inglês', () {
    final locales = <String, AppLocalizations>{
      'ar': AppLocalizationsAr(),
      'zh': AppLocalizationsZh(),
      'hi': AppLocalizationsHi(),
    };

    locales.forEach((tag, l10n) {
      testWidgets('$tag mostra o botão de aplicar volume no próprio idioma', (
        tester,
      ) async {
        // Sem cortes e com ganho: é o estado em que a ação vira "aplicar
        // volume" em vez de "gravar segmentos".
        await pump(tester, locale: tag, splitPoints: const [], gainDb: 3.0);

        expect(find.text(en.trim_applyBoost), findsNothing);
        expect(find.text(l10n.trim_applyBoost), findsOneWidget);
      });
    });
  });

  group('as coincidências legítimas continuam como estão', () {
    testWidgets('em francês, "Volume" e "Segments" seguem escritos assim', (
      tester,
    ) async {
      await pump(tester, locale: 'fr', splitPoints: const [0.5], gainDb: 0.0);

      expect(find.text('Volume'), findsOneWidget);
      expect(find.text('Segments'), findsOneWidget);
    });
  });
}
