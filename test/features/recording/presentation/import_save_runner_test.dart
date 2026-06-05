import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/presentation/file_import_entry.dart';
import 'package:oral_collector/features/recording/presentation/import_save_runner.dart';

FileImportEntry _entry(String id) => FileImportEntry(
  id: id,
  path: 'p',
  fileName: '$id.m4a',
  sizeBytes: 1,
  format: 'm4a',
  durationSeconds: 1.0,
);

void main() {
  group('runImportSave', () {
    test(
      'retry após falha parcial não reenvia entradas já concluídas',
      () async {
        final calls = <String>[];
        final completed = <String>{};
        final entries = [_entry('1'), _entry('2')];
        var failSecond = true;

        Future<void> saveOne(FileImportEntry e) async {
          calls.add(e.id);
          if (e.id == '2' && failSecond) throw Exception('boom');
        }

        await expectLater(
          runImportSave(entries, completed, saveOne),
          throwsException,
        );
        expect(calls, ['1', '2']);
        expect(completed, {'1'});

        failSecond = false;
        await runImportSave(entries, completed, saveOne);

        expect(calls, ['1', '2', '2']);
        expect(completed, {'1', '2'});
      },
    );

    test('onProgress reporta contagem cumulativa de concluídas', () async {
      final counts = <int>[];

      await runImportSave(
        [_entry('1'), _entry('2')],
        <String>{},
        (_) async {},
        onProgress: counts.add,
      );

      expect(counts, [1, 2]);
    });
  });
}
