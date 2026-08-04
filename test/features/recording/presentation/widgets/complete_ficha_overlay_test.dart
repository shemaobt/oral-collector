// ENG-374: where the floating "complete details" pill lands. Two things can
// already be sitting there — the wide layout's docked player strip, and the
// system's own gesture area — and the pill takes taps, so overlapping either
// one costs the user a control they cannot get back.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/core/theme/tokens.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_player_notifier.dart';
import 'package:oral_collector/features/recording/presentation/widgets/complete_ficha_overlay.dart';
import 'package:oral_collector/features/recording/presentation/widgets/complete_ficha_pill.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_hero_player.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

import '../../../../support/text_scale.dart';

class _MockAudioPlayer extends Mock implements AudioPlayer {}

/// A tablet/desktop viewport: the detail screen switches layouts at 700.
const _wideSize = Size(800, 600);

/// What an iPhone reserves at the bottom for the home indicator.
const _homeIndicator = 34.0;

_MockAudioPlayer _loadedPlayer() {
  final mock = _MockAudioPlayer();
  when(() => mock.dispose()).thenAnswer((_) async {});
  when(() => mock.setFilePath(any())).thenAnswer((_) async => Duration.zero);
  when(() => mock.duration).thenReturn(const Duration(seconds: 30));
  when(
    () => mock.durationStream,
  ).thenAnswer((_) => Stream.value(const Duration(seconds: 30)));
  when(
    () => mock.positionStream,
  ).thenAnswer((_) => Stream.value(Duration.zero));
  when(
    () => mock.playerStateStream,
  ).thenAnswer((_) => Stream.value(PlayerState(false, ProcessingState.ready)));
  return mock;
}

LocalRecordingEntity _recording() => LocalRecordingEntity(
  id: 'rec-overlay',
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

/// Mirrors the wide branch of RecordingDetailScreen: scrolling content with the
/// player strip docked at the bottom, and the pill floating over both.
Future<void> _pumpWideLayout(WidgetTester tester) async {
  await pumpAtTextScale(
    tester,
    size: _wideSize,
    overrides: [
      audioPlayerFactoryProvider.overrideWithValue(_loadedPlayer),
      audioPathResolverProvider.overrideWithValue((p) async => p),
    ],
    child: SizedBox.expand(
      child: Stack(
        children: [
          Builder(
            builder: (context) => Column(
              children: [
                const Expanded(child: SizedBox.expand()),
                RecordingHeroPlayer(
                  recording: _recording(),
                  colors: AppColors.of(context),
                  theme: Theme.of(context),
                ),
              ],
            ),
          ),
          CompleteFichaOverlay(pendencyCount: 3, onTap: () {}),
        ],
      ),
    ),
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 50));
}

/// A phone with a home indicator, pumped through a real Scaffold so the test
/// also proves the padding survives the trip down to the overlay. Returns the
/// body's context, which is the one the detail screen reads its reserve from.
Future<BuildContext> _pumpWithHomeIndicator(WidgetTester tester) async {
  tester.view.physicalSize = kPhoneSize * 3.0;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  BuildContext? captured;
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(bottom: _homeIndicator),
              viewPadding: const EdgeInsets.only(bottom: _homeIndicator),
            ),
            child: Scaffold(
              body: Stack(
                children: [
                  Builder(
                    builder: (bodyContext) {
                      captured = bodyContext;
                      return const SizedBox.expand();
                    },
                  ),
                  CompleteFichaOverlay(pendencyCount: 3, onTap: () {}),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return captured!;
}

void main() {
  testWidgets('the pill clears the docked player strip on a wide screen', (
    tester,
  ) async {
    await _pumpWideLayout(tester);

    // The strip is only representative with the seek slider actually in it.
    expect(find.byType(Slider), findsOneWidget);

    final pill = tester.getRect(find.byType(CompleteFichaPill));
    final player = tester.getRect(find.byType(RecordingHeroPlayer));

    expect(
      pill.overlaps(player),
      isFalse,
      reason:
          'the pill takes taps, so sitting on the player strip means the seek '
          'slider can no longer be dragged',
    );
  });

  testWidgets('the pill stays out of the system gesture area', (tester) async {
    await _pumpWithHomeIndicator(tester);

    final pill = tester.getRect(find.byType(CompleteFichaPill));

    expect(
      pill.bottom,
      lessThanOrEqualTo(kPhoneSize.height - _homeIndicator),
      reason: 'the pill reaches into the home indicator gesture zone',
    );
  });

  testWidgets('the pill keeps its own gap above the gesture area', (
    tester,
  ) async {
    await _pumpWithHomeIndicator(tester);

    final pill = tester.getRect(find.byType(CompleteFichaPill));

    // Not merely outside the gesture zone: the designed offset is measured from
    // the top of it, not from the physical bottom of the screen.
    expect(
      pill.bottom,
      closeTo(kPhoneSize.height - _homeIndicator - SpacingScale.s28, 0.01),
    );
  });

  testWidgets('the scroll reserve covers everything the pill occupies', (
    tester,
  ) async {
    final context = await _pumpWithHomeIndicator(tester);

    final pill = tester.getRect(find.byType(CompleteFichaPill));

    // The phone layout leaves this much room at the end of its scrollable. It
    // has to account for the gesture area too, or the pill still lands on the
    // last card of a fully scrolled page.
    expect(
      CompleteFichaOverlay.scrollReserve(context),
      greaterThanOrEqualTo(kPhoneSize.height - pill.top),
    );
  });
}
