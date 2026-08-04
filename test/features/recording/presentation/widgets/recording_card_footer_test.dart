/// The card footer after ENG-382: duration back, title trimmed, token gone.
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
import 'package:oral_collector/features/recording/domain/entities/review_flag.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_card.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

void main() {
  LocalRecordingEntity recording({
    String? title = 'Uma gravação',
    double durationSeconds = 60,
    List<ReviewFlag> reviewFlags = const [],
    String? storytellerId = 'st-1',
  }) => LocalRecordingEntity(
    id: 'rec-1',
    projectId: 'proj-1',
    genreId: 'genre-1',
    registerId: 'reg-1',
    title: title,
    description: 'Uma descrição longa o bastante para o piso da regra',
    storytellerId: storytellerId,
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
    reviewFlags: reviewFlags,
  );

  Future<void> pumpCard(
    WidgetTester tester,
    LocalRecordingEntity r, {
    Brightness brightness = Brightness.light,
  }) => tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: ThemeData(brightness: brightness),
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

    testWidgets('a forty-minute session is told apart from a misfire', (
      tester,
    ) async {
      await pumpCard(tester, recording(durationSeconds: 2400));

      expect(find.text('40:00'), findsOneWidget);
    });

    testWidgets('an hour-long session keeps its hours', (tester) async {
      await pumpCard(tester, recording(durationSeconds: 3900));

      expect(find.text('1:05:00'), findsOneWidget);
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

    testWidgets('still follows the locale clock rather than forcing 24h', (
      tester,
    ) async {
      await pumpCard(tester, recording(title: null));

      // 'en' reads a 12-hour clock. A 24-hour format would render '16:20:08'
      // and lose the meridiem — the defect PR #174 fixed.
      expect(find.textContaining('PM'), findsOneWidget);
    });
  });

  group('the pendency chip background', () {
    Color chipColor(WidgetTester tester, String label) {
      final container = tester.widget<Container>(
        find
            .ancestor(of: find.text(label), matching: find.byType(Container))
            .first,
      );
      return (container.decoration! as BoxDecoration).color!;
    }

    testWidgets('is unchanged in the light theme', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await pumpCard(
        tester,
        recording(
          storytellerId: null,
          reviewFlags: const [
            ReviewFlag(code: 'missing_storyteller', origin: 'system'),
          ],
        ),
      );

      // Retiring the token must not repaint the chip. surfaceAlt is a
      // different colour in light (0xFFEDE9D5) and would move the pixel.
      expect(
        chipColor(tester, l10n.recording_pendencyStoryteller),
        const Color(0xFFF1EEDE),
      );
    });

    testWidgets('is unchanged in the dark theme', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await pumpCard(
        tester,
        recording(
          storytellerId: null,
          reviewFlags: const [
            ReviewFlag(code: 'missing_storyteller', origin: 'system'),
          ],
        ),
        brightness: Brightness.dark,
      );

      expect(
        chipColor(tester, l10n.recording_pendencyStoryteller),
        const Color(0xFF302D22),
      );
    });
  });
}
