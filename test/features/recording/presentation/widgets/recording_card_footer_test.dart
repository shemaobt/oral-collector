/// The card footer after ENG-382: the duration is back, and the untitled
/// fallback lost its weekday.
///
/// The duration is here against the ENG-374 trade rule, and only earns its
/// place if it answers the question that motivated the amendment — telling an
/// accidental three-second misfire apart from a real session. A test that only
/// asserted "some duration is shown" would pass with a minutes-only format and
/// let exactly that failure through, so both ends of the range are pinned.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_card.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

void main() {
  LocalRecordingEntity recording({
    String? title = 'Uma gravação',
    double durationSeconds = 60,
  }) => LocalRecordingEntity(
    id: 'rec-1',
    projectId: 'proj-1',
    genreId: 'genre-1',
    registerId: 'reg-1',
    title: title,
    description: 'Uma descrição longa o bastante para o piso da regra',
    storytellerId: 'st-1',
    durationSeconds: durationSeconds,
    fileSizeBytes: 1024,
    format: 'm4a',
    localFilePath: '/a.m4a',
    uploadStatus: 'uploaded',
    serverId: 'srv-1',
    cleaningStatus: 'none',
    recordedAt: DateTime(2026, 3, 10, 16, 20, 8),
    createdAt: DateTime(2026, 3, 10),
    retryCount: 0,
    uploadedBytes: 0,
  );

  Future<void> pumpCard(WidgetTester tester, LocalRecordingEntity r) =>
      tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: RecordingCard(
                recording: r,
                genreName: 'Conto',
                subcategoryName: 'Origem',
                registerName: 'Formal',
                onTap: () {},
              ),
            ),
          ),
        ),
      );

  group('the duration', () {
    testWidgets('a three-second misfire reads as seconds, not as zero', (
      tester,
    ) async {
      await pumpCard(tester, recording(durationSeconds: 3));

      expect(find.text('00:03'), findsOneWidget);
    });

    testWidgets('an hour-long session keeps its hours', (tester) async {
      await pumpCard(tester, recording(durationSeconds: 3900));

      expect(find.text('1:05:00'), findsOneWidget);
    });

    testWidgets('a screen reader hears the units the glyphs only imply', (
      tester,
    ) async {
      // '00:03' and '1:05:00' are read out as digit pairs, and mm:ss sounds
      // like hh:mm — the one distinction the duration is here to make is the
      // one that does not survive being spoken.
      await pumpCard(tester, recording(durationSeconds: 3));
      expect(tester.widget<Text>(find.text('00:03')).semanticsLabel, '3s');

      await pumpCard(tester, recording(durationSeconds: 3900));
      expect(tester.widget<Text>(find.text('1:05:00')).semanticsLabel, '1h 5m');
    });
  });

  group('the untitled-recording title', () {
    testWidgets('shows the clock time and drops the weekday', (tester) async {
      await pumpCard(tester, recording(title: null));

      // The date column on the same row already places the recording in time;
      // the weekday in the title was a second reading of the same instant.
      expect(find.textContaining('Tuesday'), findsNothing);
      expect(find.textContaining('4:20:08'), findsOneWidget);
    });
  });
}
