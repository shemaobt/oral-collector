// ENG-179: the recording detail "Actions" tiles must survive a large system
// font (MediaQuery textScaler) without overflowing the fixed tile box.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_quick_actions.dart';

import '../../../../support/text_scale.dart';

LocalRecording _recording() => LocalRecording(
  id: 'rec-1',
  projectId: 'proj-1',
  genreId: 'genre-1',
  title: 'Test',
  durationSeconds: 30.0,
  fileSizeBytes: 1024,
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
      builder: (context) => RecordingQuickActions(
        recording: _recording(),
        colors: AppColors.of(context),
        theme: Theme.of(context),
        canEdit: true,
        isUnclassified: true,
        onTrim: () {},
        onToggleCleaning: () {},
        onMoveCategory: () {},
        onDelete: () {},
      ),
    ),
  );
  await tester.pump();
}

void main() {
  for (final scale in const [1.0, 1.3, 2.0]) {
    testWidgets('action tiles have no overflow at ${scale}x', (tester) async {
      await _pump(tester, scale);
      expectNoOverflow(tester);
    });
  }
}
