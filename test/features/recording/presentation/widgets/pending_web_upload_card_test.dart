import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/presentation/widgets/pending_web_upload_card.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

LocalRecordingEntity _entity({
  int uploadedBytes = 0,
  String? title = 'My pending upload',
}) => LocalRecordingEntity(
  id: 'rec-1',
  projectId: 'proj-1',
  genreId: 'genre-1',
  title: title,
  durationSeconds: 60,
  fileSizeBytes: 2048,
  format: 'm4a',
  localFilePath: '/tmp/test.m4a',
  uploadStatus: 'web_uploading',
  cleaningStatus: 'none',
  recordedAt: DateTime(2024, 1, 1),
  createdAt: DateTime(2024, 1, 1),
  retryCount: 0,
  uploadedBytes: uploadedBytes,
);

Widget _harness(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('renders the entity title and resume/discard actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        PendingWebUploadCard(
          hasStoredAudio: false,
          recording: _entity(),
          isResuming: false,
          onResume: () {},
          onDiscard: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('My pending upload'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
    expect(find.byIcon(LucideIcons.uploadCloud), findsOneWidget);
  });

  testWidgets('falls back to the filename when the entity has no title', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        PendingWebUploadCard(
          hasStoredAudio: false,
          recording: _entity(title: null),
          isResuming: false,
          onResume: () {},
          onDiscard: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('test.m4a'), findsOneWidget);
  });

  testWidgets('shows a progress bar when partially uploaded', (tester) async {
    await tester.pumpWidget(
      _harness(
        PendingWebUploadCard(
          hasStoredAudio: false,
          recording: _entity(uploadedBytes: 1024),
          isResuming: false,
          onResume: () {},
          onDiscard: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('shows no progress bar when nothing has uploaded yet', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        PendingWebUploadCard(
          hasStoredAudio: false,
          recording: _entity(uploadedBytes: 0),
          isResuming: false,
          onResume: () {},
          onDiscard: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('shows a spinner instead of the resume label while resuming', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        PendingWebUploadCard(
          hasStoredAudio: false,
          recording: _entity(),
          isResuming: true,
          onResume: () {},
          onDiscard: () {},
        ),
      ),
    );
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
  });
}
