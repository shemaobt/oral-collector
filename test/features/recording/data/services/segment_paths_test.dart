import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/features/recording/data/services/segment_paths.dart';

void main() {
  group('SegmentPaths', () {
    test('forSegment formats with zero-padded index', () {
      expect(
        SegmentPaths.forSegment('/dir', 'sess_abc', 0),
        '/dir/rec_sess_abc_000.wav',
      );
      expect(
        SegmentPaths.forSegment('/dir', 'sess_abc', 42),
        '/dir/rec_sess_abc_042.wav',
      );
      expect(
        SegmentPaths.forSegment('/dir', 'sess_abc', 1234),
        '/dir/rec_sess_abc_1234.wav',
      );
    });

    test('prefixFor returns the directory + recording prefix', () {
      expect(
        SegmentPaths.prefixFor('/dir', 'sess_abc'),
        '/dir/rec_sess_abc_',
      );
    });

    test('parseIndex extracts the index when the path matches', () {
      final prefix = SegmentPaths.prefixFor('/dir', 'sess_abc');
      expect(SegmentPaths.parseIndex('/dir/rec_sess_abc_000.wav', prefix), 0);
      expect(SegmentPaths.parseIndex('/dir/rec_sess_abc_042.wav', prefix), 42);
      expect(SegmentPaths.parseIndex('/dir/rec_sess_abc_1234.wav', prefix), 1234);
    });

    test('parseIndex returns null when path is not a segment file', () {
      final prefix = SegmentPaths.prefixFor('/dir', 'sess_abc');
      expect(SegmentPaths.parseIndex('/dir/other.wav', prefix), isNull);
      expect(
        SegmentPaths.parseIndex('/dir/rec_other_session_000.wav', prefix),
        isNull,
      );
      expect(
        SegmentPaths.parseIndex('/dir/rec_sess_abc_000.m4a', prefix),
        isNull,
      );
      expect(
        SegmentPaths.parseIndex('/dir/rec_sess_abc_notanumber.wav', prefix),
        isNull,
      );
    });

    test('parseIndex round-trips with forSegment', () {
      final prefix = SegmentPaths.prefixFor('/foo', 'bar');
      for (final i in [0, 1, 7, 42, 999, 1234]) {
        final path = SegmentPaths.forSegment('/foo', 'bar', i);
        expect(SegmentPaths.parseIndex(path, prefix), i);
      }
    });
  });
}
