import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/data/services/recording_trash.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory docs;

  setUp(() {
    docs = Directory.systemTemp.createTempSync('recording_trash_');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => docs.path);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  });

  tearDown(() => docs.deleteSync(recursive: true));

  test(
    'audio recorded days ago and trashed now survives the next prune',
    () async {
      final audio = File('${docs.path}/story.m4a')..writeAsBytesSync([1, 2, 3]);
      audio.setLastModifiedSync(
        DateTime.now().subtract(const Duration(days: 3)),
      );

      await RecordingTrash.putInTrash(
        sourcePath: audio.path,
        metadata: {'id': 'rec-1'},
      );
      await RecordingTrash.pruneOldTrash();

      final trashedAudio = Directory('${docs.path}/.trash')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('_story.m4a'));
      expect(trashedAudio, hasLength(1));
    },
  );
}
