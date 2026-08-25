/// ENG-519 (fatia 1): a faxina do ENG-426 coleta bytes de gravação que o
/// navegador guardou e ninguém mais reclama. Assim que a captura no navegador
/// passa a deixar uma linha de sessão, esses bytes deixam de ser abandonados —
/// há uma linha apontando para eles, e a fatia 2 vai oferecê-los de volta.
/// Sem esta proteção o varredor apagaria em 24 horas o áudio que a sessão
/// acabou de registrar.
///
/// O par de casos aqui é o que impede a proteção de virar "nunca colete": o
/// primeiro exige que uma sessão viva salve o áudio dela, o segundo exige que
/// a faxina continue levando o que foi mesmo abandonado — inclusive quando há
/// outras sessões vivas no banco, apontando para outro lugar.
///
/// O armazenamento é o `idb_shim` em memória, a mesma implementação completa
/// de IndexedDB que os outros testes de navegador usam, e o banco é o Drift em
/// memória. As chaves em uso saem da consulta de produção, não de um conjunto
/// escrito à mão.
library;

import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/platform/web_file_store.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/data/repositories/recording_session_repository.dart';
import 'package:oral_collector/features/recording/data/services/web_audio_sweeper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late RecordingSessionRepository sessions;
  late LocalRecordingRepository recordings;
  late WebFileStore browserStorage;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    sessions = RecordingSessionRepository(db);
    recordings = LocalRecordingRepository(db);
    browserStorage = WebFileStore(newIdbFactoryMemory());
  });

  tearDown(() => db.close());

  Uint8List audioBytes() => Uint8List.fromList([0x1a, 0x45, 0xdf, 0xa3, 0x01]);

  String keyAgedHours(int hours) {
    final started = DateTime.now().subtract(Duration(hours: hours));
    return 'web_record_${started.millisecondsSinceEpoch}.webm';
  }

  /// A sessão que a captura no navegador deixa: ancorada na chave onde os
  /// bytes ficaram, e concluída.
  Future<void> seedSession({
    required String id,
    String? anchor,
    String status = 'completed',
  }) async {
    await sessions.insertSession(
      RecordingSessionsCompanion.insert(
        id: id,
        projectId: 'project-1',
        genreId: 'genre-1',
        subcategoryId: const Value('sub-1'),
        startedAt: DateTime.now().subtract(const Duration(hours: 48)),
      ),
    );
    if (anchor != null) {
      await sessions.completeWithFinalizedAudio(
        id,
        filePath: anchor,
        durationSeconds: 12.0,
      );
    }
    if (status != 'completed') await sessions.markDiscarded(id);
  }

  /// A composição que a inicialização do navegador usa: o que um upload
  /// pendente ainda precisa, mais o que uma sessão viva registrou.
  Future<void> sweep() => sweepOrphanWebAudio(
    listKeys: browserStorage.listKeys,
    deleteKey: browserStorage.delete,
    keysInUse: () async => {
      ...await recordings.getPendingWebUploadKeys(),
      ...await sessions.getLiveAudioAnchors(),
    },
  );

  test('o áudio de uma sessão viva sobrevive à faxina', () async {
    final key = keyAgedHours(48);
    await browserStorage.write(key, audioBytes());
    await seedSession(id: 'session-live', anchor: key);

    await sweep();

    expect(
      await browserStorage.exists(key),
      isTrue,
      reason: 'a sessão aponta para estes bytes; a fatia 2 vai oferecê-los',
    );
    expect(await browserStorage.read(key), equals(audioBytes()));
  });

  test('a faxina continua levando o que foi mesmo abandonado', () async {
    final abandoned = keyAgedHours(48);
    final stillWanted = keyAgedHours(50);
    await browserStorage.write(abandoned, audioBytes());
    await browserStorage.write(stillWanted, audioBytes());

    // Há sessões vivas no banco — só que nenhuma delas aponta para os bytes
    // abandonados. Uma proteção que poupasse o armazenamento inteiro só por
    // existir sessão viva passaria no caso anterior e falharia aqui.
    await seedSession(id: 'session-elsewhere', anchor: stillWanted);
    await seedSession(id: 'session-recording-now');

    await sweep();

    expect(
      await browserStorage.exists(abandoned),
      isFalse,
      reason: 'nada aponta para estes bytes; a faxina existe para levá-los',
    );
    // O que acontece com `stillWanted` é assunto do caso anterior. Aqui ele
    // existe só para haver sessão viva no banco enquanto a faxina roda.
  });

  test('o áudio de uma sessão descartada volta a ser coletável', () async {
    final key = keyAgedHours(48);
    await browserStorage.write(key, audioBytes());
    await seedSession(id: 'session-gone', anchor: key, status: 'discarded');

    await sweep();

    expect(
      await browserStorage.exists(key),
      isFalse,
      reason: 'descartada é resposta final: ninguém vai pedir estes bytes',
    );
  });
}
