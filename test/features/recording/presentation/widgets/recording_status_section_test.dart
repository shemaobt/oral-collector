/// The upload row of the detail screen's status card: each terminal status has
/// to read as its own thing, so a description gap is not mistaken for an
/// expired session or a dropped connection.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_status_section.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

LocalRecordingEntity _recording({required String uploadStatus}) =>
    LocalRecordingEntity(
      id: 'rec-1',
      projectId: 'proj-1',
      genreId: 'genre-1',
      title: 'Story',
      durationSeconds: 60,
      fileSizeBytes: 1024,
      format: 'm4a',
      localFilePath: '/tmp/rec-1.m4a',
      uploadStatus: uploadStatus,
      cleaningStatus: 'none',
      recordedAt: DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1),
      retryCount: 0,
      uploadedBytes: 0,
    );

Future<void> _pump(WidgetTester tester, String uploadStatus) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => RecordingStatusSection(
            recording: _recording(uploadStatus: uploadStatus),
            colors: AppColors.of(context),
            theme: Theme.of(context),
            onToggleCleaning: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a recording blocked on its description says so', (tester) async {
    await _pump(tester, 'failed_description');

    expect(find.text('Description too short'), findsOneWidget);
    expect(find.text('Upload Failed'), findsNothing);
  });

  testWidgets('a generic failure still reads as a generic failure', (
    tester,
  ) async {
    await _pump(tester, 'failed');

    expect(find.text('Upload Failed'), findsOneWidget);
    expect(find.text('Description too short'), findsNothing);
  });
}
