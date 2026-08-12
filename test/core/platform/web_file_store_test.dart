import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:idb_shim/idb_client_memory.dart';

import 'package:oral_collector/core/platform/web_file_store.dart';

/// The in-memory idb factory is a complete implementation of the same
/// IndexedDB API the browser exposes, so it stands in for the browser's
/// storage engine: it outlives every [WebFileStore] built on it, exactly as
/// the browser's IndexedDB outlives the page that wrote to it. Dropping a
/// store and building a new one on the same factory is therefore a page
/// reload.
void main() {
  late IdbFactory browserStorage;

  setUp(() {
    browserStorage = newIdbFactoryMemory();
  });

  Uint8List bytes(List<int> values) => Uint8List.fromList(values);

  group('WebFileStore', () {
    test('reads back exactly the bytes it was given', () async {
      final store = WebFileStore(browserStorage);
      final audio = bytes([0x1a, 0x45, 0xdf, 0xa3, 0x00, 0xff, 0x7f]);

      await store.write('rec_1.webm', audio);

      expect(await store.read('rec_1.webm'), equals(audio));
      expect(await store.exists('rec_1.webm'), isTrue);
      expect(await store.length('rec_1.webm'), audio.length);
    });

    test('a recording written before a reload is readable after it', () async {
      final audio = bytes([1, 2, 3, 4, 5]);
      final beforeReload = WebFileStore(browserStorage);
      await beforeReload.write('rec_1.webm', audio);

      final afterReload = WebFileStore(browserStorage);

      expect(await afterReload.read('rec_1.webm'), equals(audio));
      expect(await afterReload.exists('rec_1.webm'), isTrue);
      expect(await afterReload.length('rec_1.webm'), 5);
    });

    test('the bytes live in the storage engine, not in Dart memory', () async {
      // Dropping a store instance is a weaker event than a reload: a reload
      // also destroys module-level and static Dart state, which an instance
      // outlives. A store that kept the bytes in process memory and ignored
      // the engine it was handed would satisfy the reload test above and
      // still lose the audio in a browser — that is the exact shape of the
      // defect. Only a second, unrelated engine can tell the two apart.
      await WebFileStore(browserStorage).write('rec_1.webm', bytes([1, 2, 3]));

      final otherEngine = WebFileStore(newIdbFactoryMemory());

      expect(await otherEngine.exists('rec_1.webm'), isFalse);
      expect(await otherEngine.read('rec_1.webm'), isEmpty);
    });

    test('an empty recording survives a reload as an empty file', () async {
      final beforeReload = WebFileStore(browserStorage);
      await beforeReload.write('empty.webm', bytes([]));

      final afterReload = WebFileStore(browserStorage);

      expect(await afterReload.exists('empty.webm'), isTrue);
      expect(await afterReload.length('empty.webm'), 0);
    });

    test('a recording deleted before a reload is gone after it', () async {
      final beforeReload = WebFileStore(browserStorage);
      await beforeReload.write('rec_1.webm', bytes([1, 2, 3]));
      await beforeReload.delete('rec_1.webm');

      final afterReload = WebFileStore(browserStorage);

      expect(await afterReload.exists('rec_1.webm'), isFalse);
      expect(await afterReload.read('rec_1.webm'), isEmpty);
      expect(await afterReload.length('rec_1.webm'), 0);
    });

    test('two tabs writing at once end up agreeing', () async {
      final firstTab = WebFileStore(browserStorage);
      final secondTab = WebFileStore(browserStorage);

      // Both tabs open the database for the first time here, concurrently.
      await Future.wait([
        firstTab.write('from_first.webm', bytes([1])),
        secondTab.write('from_second.webm', bytes([2])),
      ]);

      expect(await firstTab.read('from_second.webm'), equals(bytes([2])));
      expect(await secondTab.read('from_first.webm'), equals(bytes([1])));
    });

    group('edge cases', () {
      test('a path that was never written does not exist', () async {
        final store = WebFileStore(browserStorage);

        expect(await store.exists('never_written.webm'), isFalse);
        expect(await store.read('never_written.webm'), isEmpty);
        expect(await store.length('never_written.webm'), 0);
      });

      test('deleting a path that was never written does nothing', () async {
        final store = WebFileStore(browserStorage);

        await store.delete('never_written.webm');

        expect(await store.exists('never_written.webm'), isFalse);
      });

      test('deleting one recording leaves the others alone', () async {
        final store = WebFileStore(browserStorage);
        await store.write('rec_1.webm', bytes([1]));
        await store.write('rec_2.webm', bytes([2]));

        await store.delete('rec_1.webm');

        expect(await store.exists('rec_1.webm'), isFalse);
        expect(await store.read('rec_2.webm'), equals(bytes([2])));
      });

      test('writing the same path twice keeps the newer bytes', () async {
        final store = WebFileStore(browserStorage);
        await store.write('rec_1.webm', bytes([1, 2, 3]));

        await store.write('rec_1.webm', bytes([4, 5]));

        expect(await store.read('rec_1.webm'), equals(bytes([4, 5])));
        expect(await store.length('rec_1.webm'), 2);
      });

      test('empty bytes are a file that exists and has no content', () async {
        final store = WebFileStore(browserStorage);

        await store.write('empty.webm', bytes([]));

        expect(await store.exists('empty.webm'), isTrue);
        expect(await store.length('empty.webm'), 0);
        expect(await store.read('empty.webm'), isEmpty);
      });

      test('copy duplicates the bytes under the new path', () async {
        final store = WebFileStore(browserStorage);
        await store.write('source.webm', bytes([10, 20, 30]));

        await store.copy('source.webm', 'dest.webm');

        expect(await store.read('dest.webm'), equals(bytes([10, 20, 30])));
        expect(await store.read('source.webm'), equals(bytes([10, 20, 30])));
      });

      test('copying a path that does not exist writes nothing', () async {
        final store = WebFileStore(browserStorage);

        await store.copy('missing.webm', 'dest.webm');

        expect(await store.exists('dest.webm'), isFalse);
      });

      test('readChunk returns the slice asked for', () async {
        final store = WebFileStore(browserStorage);
        await store.write('rec_1.webm', bytes([0, 1, 2, 3, 4, 5, 6, 7]));

        expect(
          await store.readChunk('rec_1.webm', 2, 3),
          equals(bytes([2, 3, 4])),
        );
      });

      test('readChunk truncates at the end instead of throwing', () async {
        final store = WebFileStore(browserStorage);
        await store.write('rec_1.webm', bytes([0, 1, 2]));

        expect(
          await store.readChunk('rec_1.webm', 1, 100),
          equals(bytes([1, 2])),
        );
        expect(await store.readChunk('rec_1.webm', 9, 4), isEmpty);
        expect(await store.readChunk('missing.webm', 0, 4), isEmpty);
      });

      test(
        'readChunk reads from the start when the offset is negative',
        () async {
          final store = WebFileStore(browserStorage);
          await store.write('rec_1.webm', bytes([0, 1, 2]));

          expect(
            await store.readChunk('rec_1.webm', -5, 2),
            equals(bytes([0, 1])),
          );
        },
      );
    });
  });
}
