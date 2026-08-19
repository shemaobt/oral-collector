import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/platform/web_file_store.dart';
import 'package:oral_collector/features/recording/data/services/web_audio_sweeper.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/input_device_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The browser writes recorded bytes to `oral_collector_files` when capture
/// stops, but the row that points at them is only written after the upload
/// succeeds. Every path that does not end in an upload — a reload on the
/// confirmation form, a closed tab, a failed upload — leaves the bytes with
/// nothing pointing at them (ENG-426).
///
/// The storage here is `idb_shim`'s in-memory factory: the same complete
/// implementation of the IndexedDB API that
/// `test/core/platform/web_file_store_test.dart` uses, running on the plain
/// Dart VM. It is the real store, not a stand-in that answers what the test
/// wants to hear, so what these tests observe is what a browser would keep or
/// lose.
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

  late WebFileStore browserStorage;

  setUp(() {
    browserStorage = WebFileStore(newIdbFactoryMemory());
  });

  Uint8List audioBytes() => Uint8List.fromList([0x1a, 0x45, 0xdf, 0xa3, 0x01]);

  int millisAgo(Duration age) =>
      DateTime.now().subtract(age).millisecondsSinceEpoch;

  Future<void> sweep({DateTime? now}) => sweepOrphanWebAudio(
    listKeys: browserStorage.listKeys,
    deleteKey: browserStorage.delete,
    keysInUse: () async => <String>{},
    now: now,
  );

  test('a recording left behind two days ago is collected', () async {
    final abandoned = 'web_record_${millisAgo(const Duration(hours: 48))}.webm';
    await browserStorage.write(abandoned, audioBytes());

    await sweep();

    expect(await browserStorage.exists(abandoned), isFalse);
    expect(await browserStorage.read(abandoned), isEmpty);
  });

  test('a recording made minutes ago is left alone', () async {
    // Someone standing on the confirmation form right now, or recording in
    // another tab: their audio is minutes old and must survive the sweep.
    final inUse = 'web_record_${millisAgo(const Duration(minutes: 5))}.webm';
    await browserStorage.write(inUse, audioBytes());

    await sweep();

    expect(await browserStorage.exists(inUse), isTrue);
    expect(await browserStorage.read(inUse), equals(audioBytes()));
  });

  test('bytes that are not a browser recording are never touched', () async {
    // Both keys are far older than the cutoff and both are still needed: the
    // first is audio downloaded from the server for offline playback, the
    // second a file the person imported. The imported one also carries a
    // millisecond timestamp in its name, so a sweeper that collected anything
    // old with a timestamp would take it.
    final cached = '/docs/recording_${millisAgo(const Duration(days: 9))}.m4a';
    final imported =
        '/docs/recordings/${millisAgo(const Duration(days: 30))}_entrevista.m4a';
    await browserStorage.write(cached, audioBytes());
    await browserStorage.write(imported, audioBytes());

    await sweep();

    expect(await browserStorage.read(cached), equals(audioBytes()));
    expect(await browserStorage.read(imported), equals(audioBytes()));
  });

  test('the sweeper collects the key the recorder actually produces', () async {
    // The other tests spell the key out by hand. If the recorder's prefix ever
    // changes, they stay green while the sweeper quietly stops sweeping. This
    // one drives the real browser capture path — `startRecording` through
    // `stopRecording` with the web branch switched on — and sweeps whatever
    // key that production code chose.
    SharedPreferences.setMockInitialValues({});
    final recorder = _MockAudioRecorder();
    final recorderState = StreamController<RecordState>.broadcast();
    addTearDown(recorderState.close);

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

    final container = ProviderContainer(
      overrides: [
        isWebPlatformProvider.overrideWithValue(true),
        webAudioRecorderFactoryProvider.overrideWithValue(() => recorder),
        inputDeviceNotifierProvider.overrideWith(_FakeInputDeviceNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    final session = container.read(recordingSessionNotifierProvider.notifier);
    expect(await session.startRecording('genre-1', 'sub-1'), isTrue);

    // The browser hands `stop()` a blob URL and the notifier reads it back over
    // http; on the VM that read goes to this client instead of a browser blob.
    final result = await http.runWithClient(
      session.stopRecording,
      () => MockClient((_) async => http.Response.bytes(audioBytes(), 200)),
    );
    final producedKey = result!.filePath;
    // On the VM the notifier's file_ops facade resolves to the native one, so
    // stopping wrote a real file next to the test. The browser would have
    // written it to IndexedDB, which is what the sweep below reads.
    addTearDown(() {
      final leftover = File(producedKey);
      if (leftover.existsSync()) leftover.deleteSync();
    });

    await browserStorage.write(producedKey, audioBytes());

    await sweep(now: DateTime.now().add(const Duration(hours: 25)));

    expect(await browserStorage.exists(producedKey), isFalse);
  });

  test('a storage failure does not bring the startup down', () async {
    Future<List<String>> refuseToEnumerate() async =>
        throw StateError('IndexedDB refused the read');
    Future<void> refuseToDelete(String key) async =>
        throw StateError('IndexedDB refused the write');

    await expectLater(
      sweepOrphanWebAudio(
        listKeys: refuseToEnumerate,
        deleteKey: browserStorage.delete,
        keysInUse: () async => <String>{},
      ),
      completes,
    );

    final abandoned = 'web_record_${millisAgo(const Duration(hours: 48))}.webm';
    await browserStorage.write(abandoned, audioBytes());

    await expectLater(
      sweepOrphanWebAudio(
        listKeys: browserStorage.listKeys,
        deleteKey: refuseToDelete,
        keysInUse: () async => <String>{},
      ),
      completes,
    );
  });
}
