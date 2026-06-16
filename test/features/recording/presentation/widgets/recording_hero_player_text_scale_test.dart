// ENG-179: the recording detail hero player's error states must survive a
// large system font without overflowing their boxes — including the longer
// "file not found" string in non-English locales (pt is the primary locale).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_player_notifier.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_hero_player.dart';

import '../../../../support/text_scale.dart';

class _MockAudioPlayer extends Mock implements AudioPlayer {}

Future<String?> _identityResolver(String p) async => p;
Future<String?> _nullResolver(String p) async => null;

LocalRecording _recording({
  String localFilePath = '/tmp/rec.m4a',
  String gcsUrl = 'https://example.com/rec.m4a',
}) => LocalRecording(
  id: 'rec-hero',
  projectId: 'proj-1',
  genreId: 'genre-1',
  title: 'Test',
  durationSeconds: 30.0,
  fileSizeBytes: 1024,
  format: 'm4a',
  localFilePath: localFilePath,
  gcsUrl: gcsUrl,
  uploadStatus: 'local',
  cleaningStatus: 'none',
  recordedAt: DateTime(2026, 5, 28),
  createdAt: DateTime(2026, 5, 28),
  retryCount: 0,
  uploadedBytes: 0,
);

Future<void> _pump(
  WidgetTester tester,
  double scale, {
  required _MockAudioPlayer mock,
  required LocalRecording recording,
  Future<String?> Function(String) resolver = _identityResolver,
  Locale locale = const Locale('en'),
}) async {
  await pumpAtTextScale(
    tester,
    scale: scale,
    locale: locale,
    overrides: [
      audioPlayerFactoryProvider.overrideWithValue(() => mock),
      audioPathResolverProvider.overrideWithValue(resolver),
    ],
    child: Builder(
      builder: (context) => RecordingHeroPlayer(
        recording: recording,
        colors: AppColors.of(context),
        theme: Theme.of(context),
      ),
    ),
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 50));
}

void main() {
  for (final scale in const [1.0, 1.3, 2.0]) {
    // loadFailed: setFilePath throws after the path resolves.
    testWidgets('load-failed error has no overflow at ${scale}x', (
      tester,
    ) async {
      final mock = _MockAudioPlayer();
      when(() => mock.dispose()).thenAnswer((_) async {});
      when(() => mock.setFilePath(any())).thenThrow(Exception('boom'));
      await _pump(tester, scale, mock: mock, recording: _recording());
      expectNoOverflow(tester);
    });

    // fileNotFound: resolver returns null and there is no url fallback. Use the
    // pt locale because its message is materially longer than English and is
    // the worst case for the fixed-height error box.
    testWidgets('file-not-found error (pt) has no overflow at ${scale}x', (
      tester,
    ) async {
      final mock = _MockAudioPlayer();
      when(() => mock.dispose()).thenAnswer((_) async {});
      await _pump(
        tester,
        scale,
        mock: mock,
        recording: _recording(gcsUrl: ''),
        resolver: _nullResolver,
        locale: const Locale('pt'),
      );
      expectNoOverflow(tester);
    });
  }
}
