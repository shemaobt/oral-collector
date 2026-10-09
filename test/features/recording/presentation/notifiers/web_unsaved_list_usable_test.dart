/// ENG-519 (fatia 3): a lista de não salvas do navegador passa a funcionar.
///
/// A fatia 1 fez a captura no navegador registrar a sessão, a fatia 2 fez a
/// lista mostrá-la. Faltava abrir: `save()` — o método que a folha chama ao se
/// tocar numa gravação — começava com `if (kIsWeb) return null`, então a
/// gravação aparecia e não abria.
///
/// **Por que o formato é asserido aqui.** `kIsWeb` é constante de compilação e
/// vale `false` na VM, mesmo com `isWebPlatformProvider` sobrescrito: um caso
/// que só perguntasse "veio áudio?" percorreria o caminho do aparelho e ficaria
/// verde sem medir o navegador — foi assim que o caso equivalente da fatia 2
/// ficou verde afirmando algo falso. O caminho do aparelho deduz o formato da
/// extensão do arquivo e só conhece `wav` e `m4a`, então rotularia a gravação
/// do navegador como `m4a`. O formato é a impressão digital de qual ramo
/// respondeu — e não é detalhe interno: ele vira o MIME do upload.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
import 'package:oral_collector/features/recording/data/repositories/recording_session_repository.dart';
import 'package:oral_collector/features/recording/data/services/recording_concat_service.dart';
import 'package:oral_collector/features/recording/data/services/recording_finalization_service.dart';
import 'package:oral_collector/features/recording/data/services/recovery_coordinator.dart';
import 'package:oral_collector/features/recording/data/services/recovery_disk.dart';
import 'package:oral_collector/features/recording/data/services/segment_paths.dart';
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

/// ffmpeg não roda na VM; a concatenação é emulada copiando os bytes.
class _ByteCopyConcat implements RecordingConcatService {
  @override
  Future<String?> concatSegments({
    required List<String> segmentPaths,
    required String outputPath,
  }) async {
    final out = File(outputPath).openSync(mode: FileMode.write);
    try {
      for (final path in segmentPaths) {
        out.writeFromSync(await File(path).readAsBytes());
      }
    } finally {
      out.closeSync();
    }
    return outputPath;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FakeRecordConfig());
    registerFallbackValue(Duration.zero);
  });

  late Directory docs;
  late AppDatabase db;
  late RecordingSessionRepository sessions;
  late _MockAudioRecorder recorder;
  late StreamController<RecordState> recorderState;

  Uint8List audioBytes() => Uint8List.fromList([0x1a, 0x45, 0xdf, 0xa3, 0x07]);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    docs = await Directory.systemTemp.createTemp('eng519c_');

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => docs.path);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    db = AppDatabase.forTesting(NativeDatabase.memory());
    sessions = RecordingSessionRepository(db);

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
  });

  tearDown(() async {
    await recorderState.close();
    await db.close();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (docs.existsSync()) docs.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer({required bool isWeb}) {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        isWebPlatformProvider.overrideWithValue(isWeb),
        webAudioRecorderFactoryProvider.overrideWithValue(() => recorder),
        inputDeviceNotifierProvider.overrideWith(_FakeInputDeviceNotifier.new),
        recoveryCoordinatorProvider.overrideWith(
          (ref) => RecoveryCoordinator(
            ref,
            disk: RecoveryDisk(documentsPath: () async => docs.path),
          ),
        ),
        recordingFinalizationServiceProvider.overrideWithValue(
          RecordingFinalizationService(
            concat: _ByteCopyConcat(),
            documentsDirFn: () async => docs,
            compressFn: (src, dst) async {
              if (await File(src).length() < 44) return false;
              await File(dst).writeAsBytes(await File(src).readAsBytes());
              return true;
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Uma gravação feita no navegador e abandonada: a captura de produção, do
  /// início ao fim, sem ninguém salvar depois.
  Future<String> captureAndAbandon(ProviderContainer container) async {
    final started = await container
        .read(recordingSessionNotifierProvider.notifier)
        .startRecording('gen_narrative', 'sub_genealogy', projectId: 'proj-1');
    expect(started, isTrue);

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
  Future<List<InterruptedSession>> nextLaunch(
    ProviderContainer container,
  ) async {
    await container.read(recoveryCoordinatorProvider).scanOnStartup();
    return container.read(interruptedSessionsProvider);
  }

  group(
    'ENG-519 fatia 3: abrir a gravação que a lista do navegador oferece',
    () {
      test('vem o áudio dela, identificado como o que é', () async {
        final container = makeContainer(isWeb: true);
        final producedKey = await captureAndAbandon(container);

        final offered = await nextLaunch(container);
        expect(offered, hasLength(1));

        final result = await container
            .read(interruptedSessionsNotifierProvider.notifier)
            .save(offered.single.sessionId);

        expect(result, isNotNull, reason: 'aparecer sem abrir não é oferecer');
        expect(result!.filePath, producedKey);
        expect(await file_ops.readFileBytes(result.filePath), audioBytes());
        expect(
          result.format,
          'webm',
          reason: 'o formato diz qual ramo respondeu, e vira o MIME do upload',
        );
        expect(result.sessionId, offered.single.sessionId);
      });

      test(
        'uma gravação cujos bytes sumiram sai da lista em vez de não abrir',
        () async {
          // O risco de abrir por âncora: a faxina do ENG-426 pode ter levado os
          // bytes. A folha não faz nada com um nulo — a pessoa toca e nada
          // acontece, para sempre. Sair da lista é a resposta honesta.
          final container = makeContainer(isWeb: true);
          final producedKey = await captureAndAbandon(container);
          final offered = await nextLaunch(container);
          expect(offered, hasLength(1));

          await file_ops.deleteFile(producedKey);

          final result = await container
              .read(interruptedSessionsNotifierProvider.notifier)
              .save(offered.single.sessionId);

          expect(result, isNull);
          expect(
            await nextLaunch(container),
            isEmpty,
            reason: 'não pode continuar oferecendo o que não abre',
          );
        },
      );

      test(
        'no aparelho, abrir continua re-finalizando a partir dos segmentos',
        () async {
          final container = makeContainer(isWeb: false);
          const sessionId = 'sess-native';
          final segmentPaths = <String>[];
          for (var i = 0; i < 2; i++) {
            final path = SegmentPaths.forSegment(docs.path, sessionId, i);
            await File(path).writeAsBytes(
              Uint8List.fromList([
                ...'RIFF'.codeUnits,
                ...List<int>.filled(40, 0),
                ...'SEG$i'.codeUnits,
                ...List<int>.filled(64, i + 1),
              ]),
            );
            segmentPaths.add(path);
          }
          await sessions.insertSession(
            RecordingSessionsCompanion.insert(
              id: sessionId,
              projectId: 'proj-1',
              genreId: 'genre-1',
              startedAt: DateTime(2026, 8, 12),
              segmentPathsJson: Value(jsonEncode(segmentPaths)),
              totalDurationSeconds: const Value(2.0),
              lastSegmentIndex: const Value(1),
            ),
          );
          await sessions.markCrashed(sessionId);

          final result = await container
              .read(interruptedSessionsNotifierProvider.notifier)
              .save(sessionId);

          expect(
            result,
            isNotNull,
            reason: 'sem âncora, re-deriva dos segmentos',
          );
          final produced = String.fromCharCodes(
            await File(result!.filePath).readAsBytes(),
          );
          expect(produced, contains('SEG0'));
          expect(produced, contains('SEG1'));
        },
      );
    },
  );
}
