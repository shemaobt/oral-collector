/// ENG-519 (fatia 2): a recuperação passa a enxergar o navegador.
///
/// A fatia 1 fez a captura no navegador registrar uma sessão e a faxina poupar
/// os bytes dela. Ninguém lia essa sessão: o coordenador — que é quem alimenta
/// a lista de não salvas — estava atrás de um `if (!kIsWeb)` e nem compilava
/// para lá.
///
/// Estes casos dirigem a captura de produção do navegador do começo ao fim,
/// simulam a abertura seguinte do aplicativo e leem a lista que a interface
/// consome. Nenhum monta linha à mão e nenhum assere estado interno.
///
/// Na VM a fachada `file_ops` resolve para a nativa, então o stop escreve um
/// arquivo de verdade em vez de gravar no IndexedDB — a mesma escolha que a
/// fatia 1 fez, e pela mesma razão: a pergunta que interessa ("a âncora aponta
/// para onde os bytes foram parar?") é a mesma nas duas plataformas.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/database/database_provider.dart';
import 'package:oral_collector/core/platform/file_ops.dart' as file_ops;
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/services/recovery_coordinator.dart';
import 'package:oral_collector/features/recording/data/services/recovery_disk.dart';
import 'package:oral_collector/features/recording/data/services/segment_paths.dart';
import 'package:oral_collector/features/recording/data/services/web_audio_sweeper.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/input_device_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/interrupted_sessions_notifier.dart';
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

  late Directory docs;
  late AppDatabase db;
  late _MockAudioRecorder recorder;
  late StreamController<RecordState> recorderState;
  late ProviderContainer container;

  Uint8List audioBytes() => Uint8List.fromList([0x1a, 0x45, 0xdf, 0xa3, 0x01]);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    docs = await Directory.systemTemp.createTemp('eng519b_');

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => docs.path);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

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
        recoveryCoordinatorProvider.overrideWith(
          (ref) => RecoveryCoordinator(
            ref,
            disk: RecoveryDisk(documentsPath: () async => docs.path),
          ),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await recorderState.close();
    await db.close();
    if (docs.existsSync()) docs.deleteSync(recursive: true);
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
    addTearDown(() {
      final leftover = File(result!.filePath);
      if (leftover.existsSync()) leftover.deleteSync();
    });
    return result!.filePath;
  }

  /// A próxima vez que a pessoa abre o aplicativo.
  Future<List<InterruptedSession>> nextLaunch() async {
    await container.read(recoveryCoordinatorProvider).scanOnStartup();
    return container.read(interruptedSessionsProvider);
  }

  group('ENG-519 fatia 2: a lista de não salvas no navegador', () {
    test(
      'uma gravação abandonada no navegador aparece para ser retomada',
      () async {
        await startWebRecording(
          genreId: 'gen_narrative',
          subcategoryId: 'sub_genealogy',
        );
        await stopWebRecording();

        final offered = await nextLaunch();

        expect(offered, hasLength(1));
        expect(offered.single.genreId, 'gen_narrative');
        expect(
          offered.single.subcategoryId,
          'sub_genealogy',
          reason: 'a categoria que a pessoa escolheu tem de voltar com ela',
        );
      },
    );

    test('abrir a gravação da lista leva ao áudio dela', () async {
      await startWebRecording();
      final producedKey = await stopWebRecording();

      final offered = await nextLaunch();
      expect(offered, hasLength(1));

      final result = await container
          .read(interruptedSessionsNotifierProvider.notifier)
          .save(offered.single.sessionId);

      expect(result, isNotNull);
      expect(
        result!.filePath,
        producedKey,
        reason: 'aparecer sem poder usar não é resolver',
      );
      expect(await file_ops.readFileBytes(result.filePath), audioBytes());
    });

    test('descartar pela lista apaga os bytes e tira a gravação', () async {
      // A sessão é pedida ao banco, não à lista: descartar já funcionava no
      // navegador antes desta fatia — é de banco e de armazenamento, sem
      // disco — e este caso é a rede que garante que continua funcionando.
      // Buscá-la pela lista faria o caso medir a fatia em vez do descarte.
      await startWebRecording();
      final producedKey = await stopWebRecording();
      final sessions = await container
          .read(recordingSessionRepositoryProvider)
          .findFinishedSessions();

      await container
          .read(interruptedSessionsNotifierProvider.notifier)
          .discard(sessions.single.id);

      expect(await file_ops.fileExists(producedKey), isFalse);
      expect(container.read(interruptedSessionsProvider), isEmpty);
    });

    test('a captura que não produziu áudio não fica pendurada', () async {
      // A aba fechada no meio da gravação: a linha ficou aberta e a âncora
      // nunca foi escrita, porque no navegador os bytes só chegam ao
      // armazenamento no stop. Não há áudio para oferecer.
      await startWebRecording();

      final offered = await nextLaunch();

      expect(offered, isEmpty, reason: 'não há áudio para oferecer');
      expect(
        await container
            .read(recordingSessionRepositoryProvider)
            .findActiveSessions(),
        isEmpty,
        reason: 'e a linha não pode ficar viva indefinidamente',
      );
      // O desfecho escolhido: encerrada como descartada. É o que a mantém
      // fora da lista e o que solta a faxina — getLiveAudioAnchors ignora
      // sessões descartadas, então nada fica preso por causa dela.
      expect(
        await container
            .read(recordingSessionRepositoryProvider)
            .getLiveAudioAnchors(),
        isEmpty,
      );
    });

    test(
      'a faxina não coleta os bytes de uma gravação que a lista oferece',
      () async {
        // O pior desfecho possível seria a faxina levar o áudio que a lista
        // acabou de prometer. A proteção veio na fatia 1; este caso confirma que
        // ela cobre o caminho novo, com a gravação já envelhecida além do corte.
        await startWebRecording();
        final producedKey = await stopWebRecording();
        final offered = await nextLaunch();
        expect(offered, hasLength(1));

        await sweepOrphanWebAudio(
          listKeys: () async => [producedKey],
          deleteKey: file_ops.deleteFile,
          keysInUse: () async => container
              .read(recordingSessionRepositoryProvider)
              .getLiveAudioAnchors(),
          now: DateTime.now().add(webOrphanAudioMaxAge * 2),
        );

        expect(await file_ops.fileExists(producedKey), isTrue);
      },
    );

    test('no aparelho a recuperação continua varrendo o disco', () async {
      // A rede contra a separação mudar o aparelho por acidente: um segmento
      // que nunca chegou ao banco só é encontrado varrendo o diretório, e essa
      // varredura tem de continuar acontecendo.
      final native = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          recoveryCoordinatorProvider.overrideWith(
            (ref) => RecoveryCoordinator(
              ref,
              disk: RecoveryDisk(documentsPath: () async => docs.path),
            ),
          ),
        ],
      );
      addTearDown(native.dispose);

      await native
          .read(recordingSessionRepositoryProvider)
          .insertSession(
            RecordingSessionsCompanion.insert(
              id: 'sess-native',
              projectId: 'project-1',
              genreId: 'genre-1',
              startedAt: DateTime(2026, 8, 12),
              status: const Value('active'),
            ),
          );
      await File(
        SegmentPaths.forSegment(docs.path, 'sess-native', 0),
      ).writeAsBytes(_repairableWav());

      await native.read(recoveryCoordinatorProvider).scanOnStartup();

      expect(
        native.read(interruptedSessionsProvider).map((s) => s.sessionId),
        contains('sess-native'),
        reason: 'o segmento órfão só aparece se o disco for varrido',
      );
    });
  });
}

/// Um WAV em voo: cabeçalho real, tamanhos placeholder, um segundo de PCM.
List<int> _repairableWav() {
  Uint8List u32(int v) =>
      Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.little);
  Uint8List u16(int v) =>
      Uint8List(2)..buffer.asByteData().setUint16(0, v, Endian.little);
  final header = BytesBuilder()
    ..add('RIFF'.codeUnits)
    ..add(u32(0))
    ..add('WAVE'.codeUnits)
    ..add('fmt '.codeUnits)
    ..add(u32(16))
    ..add(u16(1))
    ..add(u16(1))
    ..add(u32(16000))
    ..add(u32(32000))
    ..add(u16(2))
    ..add(u16(16))
    ..add('data'.codeUnits)
    ..add(u32(0));
  return [...header.toBytes(), ...Uint8List(32000)];
}
