/// ENG-519 (fatia 1): o aparelho não muda.
///
/// A fatia inteira acontece no ramo do navegador, e o jeito de errar é fazer
/// isso vazar para o aparelho — onde a linha de sessão nasce antes da captura,
/// carrega projeto e categoria, e no fim aponta para o áudio finalizado.
///
/// Dirigir `_startNative` na VM exige o que o aparelho tem e a VM não. O
/// gravador entra pela interface de plataforma do `record`
/// (`RecordPlatform.instance`, exportada por `package:record/record.dart`),
/// que é a costura que o próprio plugin oferece. A notificação de gravação em
/// curso não tem costura equivalente e é acionada depois de a linha nascer e
/// de o gravador subir: a falha dela na VM é engolida aqui de propósito, e o
/// que o caso mede é o que ficou no banco e no estado quando isso aconteceu.
/// Nada de produção foi alterado para tornar este caso possível.
///
/// A outra metade — a sessão *concluída*, ancorada ao áudio finalizado — é
/// caracterizada por `finalized_audio_anchor_test.dart` (ENG-420), que roda o
/// finalizador de verdade. Esta fatia não toca nenhum dos dois caminhos.
library;

import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/database/database_provider.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// O gravador que o aparelho usaria. Só os métodos que a captura toca; o resto
/// grita, para um caminho novo não passar despercebido.
class _FakeRecordPlatform implements RecordPlatform {
  _FakeRecordPlatform(this._pcm, this._state);

  final Stream<Uint8List> _pcm;
  final Stream<RecordState> _state;

  @override
  Future<void> create(String recorderId) async {}

  @override
  Future<bool> hasPermission(String recorderId, {bool request = true}) async =>
      true;

  @override
  Future<Stream<Uint8List>> startStream(
    String recorderId,
    RecordConfig config,
  ) async => _pcm;

  @override
  Stream<RecordState> onStateChanged(String recorderId) => _state;

  @override
  Future<String?> stop(String recorderId) async => null;

  @override
  Future<void> dispose(String recorderId) async {}

  @override
  Future<void> cancel(String recorderId) async {}

  @override
  RecordIos? getIos(String recorderId) => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory docs;
  late AppDatabase db;
  late ProviderContainer container;
  late StreamController<Uint8List> pcm;
  late StreamController<RecordState> recorderState;
  late RecordPlatform realPlatform;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    docs = await Directory.systemTemp.createTemp('eng519a_');
    pcm = StreamController<Uint8List>.broadcast();
    recorderState = StreamController<RecordState>.broadcast();

    realPlatform = RecordPlatform.instance;
    RecordPlatform.instance = _FakeRecordPlatform(
      pcm.stream,
      recorderState.stream,
    );

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    void stub(String name, Future<Object?> Function(MethodCall) handler) {
      final channel = MethodChannel(name);
      messenger.setMockMethodCallHandler(channel, handler);
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    }

    stub('plugins.flutter.io/path_provider', (_) async => docs.path);
    stub('dexterous.com/flutter/local_notifications', (_) async => null);

    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        isWebPlatformProvider.overrideWithValue(false),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    RecordPlatform.instance = realPlatform;
    await pcm.close();
    await recorderState.close();
    await db.close();
    if (docs.existsSync()) await docs.delete(recursive: true);
  });

  test('no aparelho a linha de sessão continua nascendo antes da captura, '
      'com projeto e categoria', () async {
    try {
      await container
          .read(recordingSessionNotifierProvider.notifier)
          .startRecording(
            'gen_narrative',
            'sub_genealogy',
            projectId: 'project-1',
          );
    } on Object catch (_) {
      // O plugin de notificação não existe na VM (ver o cabeçalho). Se um dia
      // existir, este caso segue valendo — nada aqui depende da falha.
    }

    final active = await container
        .read(recordingSessionRepositoryProvider)
        .findActiveSessions();

    expect(active, hasLength(1), reason: 'uma gravação, uma linha');
    expect(active.single.projectId, 'project-1');
    expect(active.single.genreId, 'gen_narrative');
    expect(active.single.subcategoryId, 'sub_genealogy');
    expect(
      container.read(recordingSessionNotifierProvider).sessionId,
      active.single.id,
      reason: 'o estado da tela aponta para a linha que acabou de nascer',
    );

    // Encerra a captura enquanto o gravador falso ainda está instalado. O
    // descarte do container é assíncrono e terminaria depois do `tearDown`,
    // caindo no plugin de verdade que a VM não tem — uma falha que aparece ou
    // não conforme a ordem em que a suíte roda.
    await container
        .read(recordingSessionNotifierProvider.notifier)
        .discardRecording();
  });
}
