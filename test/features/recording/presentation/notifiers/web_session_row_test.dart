/// ENG-519 (fatia 1): no aparelho, toda gravação nasce com uma linha de sessão
/// e termina ancorada ao arquivo que produziu. No navegador não havia linha
/// nenhuma — os bytes iam para o armazenamento e o registro do que eles são
/// morria com a aba.
///
/// Estes testes dirigem a captura de produção do navegador do início ao fim
/// (o `isWebPlatformProvider` ligado, a fábrica do gravador substituída, e o
/// `http.runWithClient` para o passo que lê a blob) e depois olham o banco.
/// Nada aqui monta a linha à mão.
///
/// Na VM a fachada `file_ops` resolve para a nativa, então o `stop` escreve um
/// arquivo de verdade em vez de gravar no IndexedDB. É por isso que o áudio é
/// procurado pela mesma fachada que a produção usou para escrevê-lo: a
/// pergunta que interessa — "a âncora aponta para onde os bytes foram parar?"
/// — é a mesma nas duas plataformas.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/database/database_provider.dart';
import 'package:oral_collector/core/platform/file_ops.dart' as file_ops;
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/input_device_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAudioRecorder extends Mock implements AudioRecorder {}

class _FakeRecordConfig extends Fake implements RecordConfig {}

class _FakeInputDeviceNotifier extends InputDeviceNotifier {
  @override
  InputDeviceState build() => const InputDeviceState();

  @override
  Future<void> refresh() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FakeRecordConfig());
    registerFallbackValue(Duration.zero);
  });

  late AppDatabase db;
  late _MockAudioRecorder recorder;
  late StreamController<RecordState> recorderState;
  late ProviderContainer container;

  Uint8List audioBytes() => Uint8List.fromList([0x1a, 0x45, 0xdf, 0xa3, 0x01]);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    recorder = _MockAudioRecorder();
    recorderState = StreamController<RecordState>.broadcast();

    when(() => recorder.hasPermission()).thenAnswer((_) async => true);
    when(
      () => recorder.start(any(), path: any(named: 'path')),
    ).thenAnswer((_) async {});
    when(
      () => recorder.onAmplitudeChanged(any()),
    ).thenAnswer((_) => const Stream<Amplitude>.empty());
    when(
      () => recorder.onStateChanged(),
    ).thenAnswer((_) => recorderState.stream);
    when(
      () => recorder.stop(),
    ).thenAnswer((_) async => 'https://recorder.invalid/captured-blob');
    when(() => recorder.dispose()).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        isWebPlatformProvider.overrideWithValue(true),
        webAudioRecorderFactoryProvider.overrideWithValue(() => recorder),
        inputDeviceNotifierProvider.overrideWith(_FakeInputDeviceNotifier.new),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await recorderState.close();
    await db.close();
  });

  Future<void> startWebRecording({
    String genreId = 'genre-1',
    String subcategoryId = 'sub-1',
  }) async {
    final started = await container
        .read(recordingSessionNotifierProvider.notifier)
        .startRecording(genreId, subcategoryId, projectId: 'project-1');
    expect(started, isTrue);
  }

  Future<String> stopWebRecording() async {
    final result = await http.runWithClient(
      container.read(recordingSessionNotifierProvider.notifier).stopRecording,
      () => MockClient((_) async => http.Response.bytes(audioBytes(), 200)),
    );
    expect(result, isNotNull);
    // A gravação escreveu um arquivo de verdade ao lado do teste, porque na VM
    // a fachada é a nativa. Some com ele ao fim do caso.
    addTearDown(() {
      final leftover = File(result!.filePath);
      if (leftover.existsSync()) leftover.deleteSync();
    });
    return result!.filePath;
  }

  test(
    'a gravação no navegador deixa uma sessão apontando para o áudio',
    () async {
      await startWebRecording();
      final producedKey = await stopWebRecording();

      final sessions = await container
          .read(recordingSessionRepositoryProvider)
          .findFinishedSessions();

      expect(
        sessions,
        hasLength(1),
        reason: 'a captura no navegador tem de deixar uma sessão concluída',
      );
      final session = sessions.single;
      expect(
        session.finalizedAudioPath,
        producedKey,
        reason:
            'a âncora tem de nomear o endereço onde os bytes foram escritos',
      );
      expect(
        await file_ops.readFileBytes(session.finalizedAudioPath!),
        equals(audioBytes()),
        reason:
            'o áudio tem de ser encontrável a partir do que a sessão registrou',
      );
    },
  );

  test('o resultado da captura no navegador carrega o id da sessão', () async {
    await startWebRecording();

    final result = await http.runWithClient(
      container.read(recordingSessionNotifierProvider.notifier).stopRecording,
      () => MockClient((_) async => http.Response.bytes(audioBytes(), 200)),
    );
    addTearDown(() {
      final leftover = File(result!.filePath);
      if (leftover.existsSync()) leftover.deleteSync();
    });

    final sessions = await container
        .read(recordingSessionRepositoryProvider)
        .findFinishedSessions();

    expect(result!.sessionId, isNotNull);
    expect(result.sessionId, sessions.single.id);
  });

  test('a sessão do navegador nasce com a categoria da gravação', () async {
    await startWebRecording(
      genreId: 'gen_narrative',
      subcategoryId: 'sub_genealogy',
    );

    final active = await container
        .read(recordingSessionRepositoryProvider)
        .findActiveSessions();

    expect(active, hasLength(1));
    expect(active.single.genreId, 'gen_narrative');
    expect(active.single.subcategoryId, 'sub_genealogy');

    // Esta cena é também a da aba fechada no meio da gravação: a linha fica
    // aberta e sem âncora, porque a âncora só é escrita no stop. Sem âncora
    // ela não protege byte nenhum da faxina — e não há byte a proteger, já
    // que no navegador os bytes também só chegam ao armazenamento no stop.
    expect(active.single.finalizedAudioPath, isNull);
    expect(
      await container
          .read(recordingSessionRepositoryProvider)
          .getLiveAudioAnchors(),
      isEmpty,
      reason: 'uma sessão sem áudio não pode desligar a faxina para sempre',
    );
  });

  test(
    'duas gravações seguidas no navegador não colidem de sessão nem de áudio',
    () async {
      await startWebRecording();
      final firstKey = await stopWebRecording();

      // Uma segunda aba grava com o mesmo código; o que separa as duas é a
      // chave, montada a partir do relógio. Duas capturas no mesmo milissegundo
      // se sobreporiam — o que este caso pede é que o id da sessão e a âncora
      // andem juntos, cada sessão apontando para o seu próprio áudio.
      await startWebRecording();
      final secondKey = await stopWebRecording();

      final sessions = await container
          .read(recordingSessionRepositoryProvider)
          .findFinishedSessions();

      expect(sessions, hasLength(2));
      expect(sessions.map((s) => s.id).toSet(), hasLength(2));
      expect(sessions.map((s) => s.finalizedAudioPath).toSet(), {
        firstKey,
        secondKey,
      });
    },
  );

  test('uma captura que não produz áudio não deixa sessão concluída', () async {
    when(() => recorder.stop()).thenAnswer((_) async => null);

    await startWebRecording();
    final result = await container
        .read(recordingSessionNotifierProvider.notifier)
        .stopRecording();

    expect(result, isNull);
    final repo = container.read(recordingSessionRepositoryProvider);
    expect(
      await repo.findFinishedSessions(),
      isEmpty,
      reason: 'sem áudio não há o que a fatia 2 possa oferecer',
    );
    expect(
      await repo.findActiveSessions(),
      isEmpty,
      reason: 'uma sessão que ficasse ativa apareceria como gravação em curso',
    );
  });
}
