// ENG-179: the recording detail info grid (duration/size/format tiles) must
// survive a large system font without overflowing the three-column row.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_info_grid.dart';

import '../../../../support/text_scale.dart';

LocalRecordingEntity _recording() => LocalRecordingEntity(
  id: 'rec-1',
  projectId: 'proj-1',
  genreId: 'genre-1',
  title: 'Test',
  durationSeconds: 3754.0,
  fileSizeBytes: 1024 * 1024,
  format: 'm4a',
  localFilePath: '/tmp/rec.m4a',
  gcsUrl: 'https://example.com/rec.m4a',
  uploadStatus: 'local',
  cleaningStatus: 'none',
  recordedAt: DateTime(2026, 5, 28),
  createdAt: DateTime(2026, 5, 28),
  retryCount: 0,
  uploadedBytes: 0,
);

Future<void> _pump(WidgetTester tester, double scale) async {
  await pumpAtTextScale(
    tester,
    scale: scale,
    child: Builder(
      builder: (context) => Align(
        alignment: Alignment.topCenter,
        child: RecordingInfoGrid(
          recording: _recording(),
          colors: AppColors.of(context),
          theme: Theme.of(context),
          formattedDuration: '1:02:34',
          formattedDate: 'May 28, 2026',
          formattedSize: '1.0 MB',
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  for (final scale in const [1.0, 1.3, 2.0]) {
    testWidgets('info grid has no overflow at ${scale}x', (tester) async {
      await _pump(tester, scale);
      expectNoOverflow(tester);
    });
  }
}
