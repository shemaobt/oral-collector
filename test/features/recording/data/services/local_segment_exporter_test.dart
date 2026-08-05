/// Pins the ffmpeg command strings and child-spec rules that the trim editor's
/// local save path used to build inline (lines ~784-846 of trim_editor_screen).
/// Extracted into [exportLocalSegments] so the orchestration is unit-testable
/// without a device: the ffmpeg runner, file-length probe, clock and documents
/// directory are all injected here.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/data/services/local_segment_exporter.dart';

void main() {
  final fixedNow = DateTime.fromMillisecondsSinceEpoch(1700000000000);
  final ts = fixedNow.millisecondsSinceEpoch;

  group('exportLocalSegments', () {
    test('boost-only save emits a whole-file volume re-encode and no index '
        'suffix on the single child title', () async {
      final commands = <String>[];
      final specs = await exportLocalSegments(
        const ExportLocalSegmentsRequest(
          sourceFilePath: '/audio/in.m4a',
          segments: [
            SegmentExportSpec(
              startSeconds: 0.0,
              endSeconds: 12.0,
              genreOverride: 'g1',
            ),
          ],
          gainDb: 3.0,
          boostOnly: true,
          originalTitle: 'My Story',
          parentGenreId: 'genreX',
        ),
        runner: (cmd) async {
          commands.add(cmd);
          return true;
        },
        fileLength: (_) async => 4242,
        clock: () => fixedNow,
        documentsDirectoryPath: () async => '/docs',
      );

      expect(commands, hasLength(1));
      expect(
        commands.single,
        '-y -i "/audio/in.m4a" -af "volume=3.00dB" '
        '-c:a aac -b:a 128k "/docs/split_${ts}_0.m4a"',
      );
      expect(specs, hasLength(1));
      final s = specs.single;
      // id is `<timestamp>_<index>_<parentGenreId hash>`; pin the structure
      // without re-deriving the hash (which would just mirror the impl).
      expect(s.id, startsWith('${ts}_0_'));
      expect(s.title, 'My Story');
      expect(s.localFilePath, '/docs/split_${ts}_0.m4a');
      expect(s.durationSeconds, 12.0);
      expect(s.fileSizeBytes, 4242);
      expect(s.genreOverride, 'g1');
    });

    test('split with gain emits trim + volume re-encode per kept segment with '
        'indexed titles', () async {
      final commands = <String>[];
      final specs = await exportLocalSegments(
        const ExportLocalSegmentsRequest(
          sourceFilePath: '/audio/in.m4a',
          segments: [
            SegmentExportSpec(
              startSeconds: 0.0,
              endSeconds: 5.5,
              subcategoryOverride: 'sub1',
            ),
            SegmentExportSpec(
              startSeconds: 5.5,
              endSeconds: 10.0,
              registerOverride: 'reg1',
            ),
          ],
          gainDb: -2.0,
          boostOnly: false,
          originalTitle: 'Tale',
          parentGenreId: 'g',
        ),
        runner: (cmd) async {
          commands.add(cmd);
          return true;
        },
        fileLength: (_) async => 100,
        clock: () => fixedNow,
        documentsDirectoryPath: () async => '/docs',
      );

      expect(commands, [
        '-y -i "/audio/in.m4a" -ss 0.0 -to 5.5 -af "volume=-2.00dB" '
            '-c:a aac -b:a 128k "/docs/split_${ts}_0.m4a"',
        '-y -i "/audio/in.m4a" -ss 5.5 -to 10.0 -af "volume=-2.00dB" '
            '-c:a aac -b:a 128k "/docs/split_${ts}_1.m4a"',
      ]);
      expect(specs.map((s) => s.title), ['Tale (1/2)', 'Tale (2/2)']);
      expect(specs[0].subcategoryOverride, 'sub1');
      expect(specs[1].registerOverride, 'reg1');
      expect(specs[0].durationSeconds, 5.5);
      expect(specs[1].durationSeconds, closeTo(4.5, 1e-9));
    });

    test('split without gain emits a stream-copy trim command', () async {
      final commands = <String>[];
      await exportLocalSegments(
        const ExportLocalSegmentsRequest(
          sourceFilePath: '/a.m4a',
          segments: [SegmentExportSpec(startSeconds: 1.0, endSeconds: 2.0)],
          gainDb: 0.0,
          boostOnly: false,
          originalTitle: 'X',
          parentGenreId: 'g',
        ),
        runner: (cmd) async {
          commands.add(cmd);
          return true;
        },
        fileLength: (_) async => 1,
        clock: () => fixedNow,
        documentsDirectoryPath: () async => '/docs',
      );

      expect(
        commands.single,
        '-y -i "/a.m4a" -ss 1.0 -to 2.0 -c copy "/docs/split_${ts}_0.m4a"',
      );
    });

    test('throws when the ffmpeg runner reports failure', () async {
      await expectLater(
        exportLocalSegments(
          const ExportLocalSegmentsRequest(
            sourceFilePath: '/a.m4a',
            segments: [SegmentExportSpec(startSeconds: 0, endSeconds: 1)],
            gainDb: 0.0,
            boostOnly: false,
            originalTitle: 'X',
            parentGenreId: 'g',
          ),
          runner: (_) async => false,
          fileLength: (_) async => 1,
          clock: () => fixedNow,
          documentsDirectoryPath: () async => '/docs',
        ),
        throwsException,
      );
    });
  });
}
