/// ENG-1190: o tempo da tela é o áudio escrito.
///
/// O gravador do aparelho entra pela interface de plataforma do `record`, com
/// o PCM alimentado à mão a 32 000 bytes por segundo. Cada caso lê o que a
/// tela mostra (`elapsed`) ou o que foi salvo, nunca o que o gravador guarda
/// por dentro. O relógio de um segundo não é esperado em nenhum caso: o
/// tempo real de cada um fica muito abaixo de um segundo.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/database/database_provider.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/services/segment_paths.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:oral_collector/shared/utils/format.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Future<bool> isRecording(String recorderId) async => true;

  @override
  Future<Amplitude> getAmplitude(String recorderId) async =>
      Amplitude(current: -30, max: -30);

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
  final stubbed = <MethodChannel>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    docs = await Directory.systemTemp.createTemp('eng1190_');
    pcm = StreamController<Uint8List>.broadcast();
    recorderState = StreamController<RecordState>.broadcast();

    realPlatform = RecordPlatform.instance;
    RecordPlatform.instance = _FakeRecordPlatform(
      pcm.stream,
      recorderState.stream,
    );

    void stub(String name, Future<Object?> Function(MethodCall) handler) {
      final channel = MethodChannel(name);
      messenger.setMockMethodCallHandler(channel, handler);
      stubbed.add(channel);
    }

    stub('plugins.flutter.io/path_provider', (_) async => docs.path);
    stub(
      'dexterous.com/flutter/local_notifications',
      (call) async => call.method == 'initialize' ? true : null,
    );
    AndroidFlutterLocalNotificationsPlugin.registerWith();

    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        isWebPlatformProvider.overrideWithValue(false),
      ],
    );
  });

  tearDown(() async {
    final notifier = container.read(recordingSessionNotifierProvider.notifier);
    await notifier.discardRecording();
    container.dispose();
    await pumpEventQueue();
    RecordPlatform.instance = realPlatform;
    await pcm.close();
    await recorderState.close();
    await db.close();
    if (docs.existsSync()) await docs.delete(recursive: true);
    for (final channel in stubbed) {
      messenger.setMockMethodCallHandler(channel, null);
    }
    stubbed.clear();
  });

  RecordingSessionNotifier notifier() =>
      container.read(recordingSessionNotifierProvider.notifier);

  Duration elapsed() =>
      container.read(recordingSessionNotifierProvider).elapsed;

  String shown() => formatElapsed(elapsed());

  Future<void> startNative() async {
    await notifier().startRecording('gen_narrative', 'sub_genealogy');
  }

  Future<void> feed(int seconds) async {
    for (var i = 0; i < seconds; i++) {
      pcm.add(Uint8List(32000));
      await pumpEventQueue();
    }
  }

  test('the screen\'s time is the audio written even when the periodic timer '
      'never fires', () async {
    await startNative();

    await feed(5);

    expect(shown(), '00:00:05');
  });

  test('a pause holds the screen\'s time and the saved duration to the audio '
      'written', () async {
    await startNative();

    await feed(3);
    await notifier().pauseRecording();
    await feed(2);
    await notifier().resumeRecording();
    await feed(3);

    expect(shown(), '00:00:06');

    final result = await notifier().stopRecording();
    expect(result, isNotNull);
    expect(result!.durationSeconds, closeTo(6, 0.5));
  });

  test('the screen\'s time stands still while paused', () async {
    await startNative();

    await feed(3);
    await notifier().pauseRecording();
    expect(shown(), '00:00:03');

    await feed(2);
    expect(shown(), '00:00:03');
  });

  test('a resumed session\'s time continues from the audio already '
      'written', () async {
    const sessionId = 'sess-resume';
    final segment = SegmentPaths.forSegment(docs.path, sessionId, 0);
    await File(segment).writeAsString('segment 0');
    await container
        .read(recordingSessionRepositoryProvider)
        .insertSession(
          RecordingSessionsCompanion.insert(
            id: sessionId,
            projectId: 'proj-1',
            genreId: 'gen_narrative',
            subcategoryId: const Value('sub_genealogy'),
            startedAt: DateTime(2026, 10, 8),
            segmentPathsJson: Value(jsonEncode([segment])),
            totalDurationSeconds: const Value(10),
            lastSegmentIndex: const Value(0),
          ),
        );

    expect(await notifier().loadInterruptedSession(sessionId), isTrue);
    await notifier().resumeRecording();
    await feed(2);

    expect(shown(), '00:00:12');
  });

  test('the screen\'s time does not dip when a segment closes', () async {
    await startNative();

    await feed(59);
    expect(shown(), '00:00:59');

    await feed(1);
    expect(shown(), '00:01:00');

    await feed(1);
    expect(shown(), '00:01:01');
  });
}
