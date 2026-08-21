/// ENG-529: os segmentos também precisam ser resolvidos.
///
/// A âncora de uma sessão passa por `resolveRecordingPath` antes de ser usada,
/// porque o contêiner do aplicativo muda de lugar numa reinstalação ou num
/// restore. Os segmentos não passam: os dois lugares que montam a lista de
/// válidos filtram pela existência do caminho **literal**. Depois de o
/// contêiner mudar, uma sessão sem âncora tem todos os segmentos declarados
/// ausentes — com os arquivos ali no disco — e é tratada como sem áudio.
///
/// Diferente da ENG-528, em que as duas pontas discordavam e o resultado era
/// impasse, aqui as duas concordam e concordam errado: a sessão some.
///
/// Cada caso semeia a linha e os arquivos de verdade num diretório temporário,
/// dirige a entrada pública, e olha o que a pessoa consegue fazer com a
/// gravação. Nenhum assere qual caminho foi usado por dentro.
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/database/database_provider.dart';
import 'package:oral_collector/features/recording/data/repositories/recording_session_repository.dart';
import 'package:oral_collector/features/recording/data/services/recording_concat_service.dart';
import 'package:oral_collector/features/recording/data/services/recording_finalization_service.dart';
import 'package:oral_collector/features/recording/data/services/recovery_coordinator.dart';
import 'package:oral_collector/features/recording/data/services/segment_paths.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/interrupted_sessions_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ffmpeg não roda na VM; a concatenação é emulada copiando os bytes. Todo o
/// resto do caminho é o código de produção.
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

  late Directory docs;
  late AppDatabase db;
  late RecordingSessionRepository sessions;
  late ProviderContainer container;

  /// O contêiner sob o qual o aplicativo rodava antes de ser reinstalado. Ele
  /// não existe mais, e é esse o ponto.
  const oldContainer = '/var/mobile/Containers/Data/Application/OLD-UUID/docs';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    docs = await Directory.systemTemp.createTemp('eng529_');

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => docs.path);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    db = AppDatabase.forTesting(NativeDatabase.memory());
    sessions = RecordingSessionRepository(db);
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        recoveryCoordinatorProvider.overrideWith(
          (ref) =>
              RecoveryCoordinator(ref, directoryResolver: () async => docs),
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
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    // finalize() dispara as deleções de origem com unawaited(); deixe-as
    // pousarem antes de apagar o diretório recursivamente.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (docs.existsSync()) docs.deleteSync(recursive: true);
  });

  /// Um segmento reconhecível: cabeçalho WAV mínimo seguido de bytes que
  /// identificam qual segmento é, para o áudio final poder ser conferido.
  Uint8List segmentBytes(int index) {
    final marker = 'SEG$index'.codeUnits;
    return Uint8List.fromList([
      ...'RIFF'.codeUnits,
      ...List<int>.filled(40, 0),
      ...marker,
      ...List<int>.filled(64, index + 1),
    ]);
  }

  /// Uma sessão interrompida com segmentos no disco. [storedSegmentDir] é onde
  /// a linha **diz** que os segmentos estão; os arquivos são sempre escritos
  /// no diretório de documentos atual, que é onde o aplicativo os encontraria
  /// hoje — a não ser que [writeFiles] seja falso, o caso em que sumiram de
  /// verdade.
  Future<List<String>> seedInterruptedSession(
    String sessionId, {
    required String storedSegmentDir,
    int segmentCount = 2,
    bool writeFiles = true,
  }) async {
    final storedPaths = <String>[];
    for (var i = 0; i < segmentCount; i++) {
      if (writeFiles) {
        await File(
          SegmentPaths.forSegment(docs.path, sessionId, i),
        ).writeAsBytes(segmentBytes(i));
      }
      storedPaths.add(SegmentPaths.forSegment(storedSegmentDir, sessionId, i));
    }
    await sessions.insertSession(
      RecordingSessionsCompanion.insert(
        id: sessionId,
        projectId: 'proj-1',
        genreId: 'genre-1',
        subcategoryId: const Value('sub-1'),
        startedAt: DateTime(2026, 8, 12),
        segmentPathsJson: Value(jsonEncode(storedPaths)),
        totalDurationSeconds: Value(segmentCount.toDouble()),
        lastSegmentIndex: Value(segmentCount - 1),
      ),
    );
    await sessions.markCrashed(sessionId);
    return storedPaths;
  }

  Future<List<String>> offered() async {
    await container.read(recoveryCoordinatorProvider).refresh();
    return container
        .read(interruptedSessionsProvider)
        .map((s) => s.sessionId)
        .toList();
  }

  Future<bool> resume(String sessionId) => container
      .read(recordingSessionNotifierProvider.notifier)
      .loadInterruptedSession(sessionId);

  Future<RecordingResult?> save(String sessionId) => container
      .read(interruptedSessionsNotifierProvider.notifier)
      .save(sessionId);

  group('ENG-529: o áudio no disco sobrevive à mudança de contêiner', () {
    test(
      'uma sessão sem âncora continua alcançável depois da mudança',
      () async {
        await seedInterruptedSession(
          'sess-moved',
          storedSegmentDir: oldContainer,
        );
        expect(await offered(), contains('sess-moved'));

        expect(
          await resume('sess-moved'),
          isTrue,
          reason: 'os arquivos estão no disco, sob o nome que o app procura',
        );
        expect(
          await offered(),
          contains('sess-moved'),
          reason: 'retomar não pode fazer a gravação sumir da lista',
        );
        expect(
          File(
            SegmentPaths.forSegment(docs.path, 'sess-moved', 0),
          ).existsSync(),
          isTrue,
          reason: 'os segmentos que a correção passa a enxergar continuam lá',
        );
      },
    );

    test('uma sessão cujos segmentos sumiram continua sem áudio', () async {
      // A rede que impede a correção de fazer o app enxergar o que não existe:
      // nem o caminho guardado nem o nome no diretório atual resolvem.
      await seedInterruptedSession(
        'sess-gone',
        storedSegmentDir: oldContainer,
        writeFiles: false,
      );

      expect(await resume('sess-gone'), isFalse);
      expect(
        await offered(),
        isNot(contains('sess-gone')),
        reason: 'sem áudio nenhum, não há o que oferecer',
      );
    });

    test('o caminho normal continua como era', () async {
      await seedInterruptedSession('sess-normal', storedSegmentDir: docs.path);

      expect(await resume('sess-normal'), isTrue);
      expect(await offered(), contains('sess-normal'));
    });

    test(
      'salvar depois da mudança produz a gravação com o áudio certo',
      () async {
        await seedInterruptedSession(
          'sess-save',
          storedSegmentDir: oldContainer,
          segmentCount: 3,
        );

        final result = await save('sess-save');

        expect(
          result,
          isNotNull,
          reason: 'enxergar sem conseguir usar não é consertar',
        );
        final produced = await File(result!.filePath).readAsBytes();
        final text = String.fromCharCodes(produced);
        for (var i = 0; i < 3; i++) {
          expect(
            text,
            contains('SEG$i'),
            reason: 'o áudio salvo tem de conter os três segmentos, em ordem',
          );
        }
        expect(
          text.indexOf('SEG0'),
          lessThan(text.indexOf('SEG2')),
          reason: 'em ordem, não embaralhados',
        );
      },
    );
  });
}
