import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_player_notifier.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_player_controls.dart';
import 'package:oral_collector/features/recording/presentation/widgets/seek_wave.dart';

import '../../../../support/text_scale.dart';

class _MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  testWidgets('the wave stays tappable at 320dp, text 2.0, one hour or more', (
    tester,
  ) async {
    final player = _MockAudioPlayer();
    when(() => player.dispose()).thenAnswer((_) async {});
    when(
      () => player.durationStream,
    ).thenAnswer((_) => Stream.value(const Duration(hours: 1, minutes: 5)));
    when(() => player.positionStream).thenAnswer(
      (_) => Stream.value(const Duration(hours: 1, minutes: 3, seconds: 12)),
    );
    when(() => player.playerStateStream).thenAnswer(
      (_) => Stream.value(PlayerState(false, ProcessingState.ready)),
    );

    await pumpAtTextScale(
      tester,
      scale: 2.0,
      size: const Size(320, 640),
      overrides: [audioPlayerFactoryProvider.overrideWithValue(() => player)],
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: RecordingPlayerControls(recordingId: 'rec'),
      ),
    );
    await tester.pump();

    expectNoOverflow(tester);
    expect(
      tester.getSize(find.byType(SeekWave)).width,
      greaterThanOrEqualTo(72),
    );
  });
}
