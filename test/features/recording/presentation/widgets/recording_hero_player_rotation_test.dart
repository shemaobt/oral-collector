// Regression test for ENG-69: rotating the device must not stop audio
// playback. The bug was that the AudioPlayer lived inside a StatefulWidget's
// State; the LayoutBuilder in RecordingDetailScreen swaps the entire subtree
// at the 700 px threshold during rotation, so the State (and its player)
// got disposed mid-playback. The harness below mirrors that LayoutBuilder
// so the regression is exercised end-to-end.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/core/theme/app_theme.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_player_notifier.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_hero_player.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

class _MockAudioPlayer extends Mock implements AudioPlayer {}

const _recordingId = 'rec-rotation';
const _filePath = '/tmp/rec-rotation.m4a';

LocalRecording _recording() => LocalRecording(
  id: _recordingId,
  projectId: 'proj-1',
  genreId: 'genre-1',
  title: 'Rotation test',
  durationSeconds: 30.0,
  fileSizeBytes: 1024,
  format: 'm4a',
  localFilePath: _filePath,
  gcsUrl: 'https://example.com/rec.m4a',
  uploadStatus: 'local',
  cleaningStatus: 'none',
  recordedAt: DateTime(2026, 5, 28),
  createdAt: DateTime(2026, 5, 28),
  retryCount: 0,
  uploadedBytes: 0,
);

// Mirrors RecordingDetailScreen's LayoutBuilder (recording_detail_screen.dart
// lines 1703-1801): two completely different subtrees pivoting on the
// 700 dp width threshold. This is the trigger for the original bug.
class _DetailLayoutHarness extends StatelessWidget {
  const _DetailLayoutHarness({required this.recording});

  final LocalRecording recording;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 700) {
            return Column(
              children: [
                Expanded(child: Container()),
                RecordingHeroPlayer(
                  recording: recording,
                  colors: colors,
                  theme: theme,
                ),
              ],
            );
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: RecordingHeroPlayer(
                    recording: recording,
                    colors: colors,
                    theme: theme,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 400)),
            ],
          );
        },
      ),
    );
  }
}

Widget _harness(ProviderContainer container, LocalRecording recording) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      home: _DetailLayoutHarness(recording: recording),
    ),
  );
}

void _stubMockPlayer(_MockAudioPlayer mock) {
  when(() => mock.dispose()).thenAnswer((_) async {});
  when(() => mock.setFilePath(any())).thenAnswer((_) async => null);
  when(() => mock.setUrl(any())).thenAnswer((_) async => null);
  when(
    () => mock.playerStateStream,
  ).thenAnswer((_) => Stream.value(PlayerState(true, ProcessingState.ready)));
  when(
    () => mock.positionStream,
  ).thenAnswer((_) => Stream.value(const Duration(seconds: 3)));
  when(
    () => mock.durationStream,
  ).thenAnswer((_) => Stream.value(const Duration(seconds: 30)));
  when(() => mock.duration).thenReturn(const Duration(seconds: 30));
  when(
    () => mock.playerState,
  ).thenReturn(PlayerState(true, ProcessingState.ready));
}

ProviderContainer _makeContainer(_MockAudioPlayer mockPlayer) {
  final container = ProviderContainer(
    overrides: [
      audioPlayerFactoryProvider.overrideWithValue(() => mockPlayer),
      audioPathResolverProvider.overrideWithValue((path) async => path),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUpAll(() {
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  testWidgets(
    'rotating across the LayoutBuilder 700 dp threshold neither disposes nor reloads the AudioPlayer',
    (tester) async {
      final mockPlayer = _MockAudioPlayer();
      _stubMockPlayer(mockPlayer);
      final container = _makeContainer(mockPlayer);

      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      // Portrait, width < 700 dp → CustomScrollView/SliverAppBar branch.
      binding.platformDispatcher.views.first.physicalSize = const Size(
        390,
        844,
      );

      await tester.pumpWidget(_harness(container, _recording()));
      // Drain the microtask the widget posts to call notifier.load().
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      // Rotate to landscape, width >= 700 dp → Column branch. The entire
      // RecordingHeroPlayer subtree is rebuilt under a different ancestor.
      binding.platformDispatcher.views.first.physicalSize = const Size(
        844,
        390,
      );
      await tester.pump();

      // Audio playback contract: the player must not have been torn down
      // by the rebuild, and load must not have been re-issued.
      verifyNever(() => mockPlayer.dispose());
      verify(() => mockPlayer.setFilePath(any())).called(1);
    },
  );

  testWidgets(
    'rotating from wide to phone layout neither disposes nor reloads the AudioPlayer',
    (tester) async {
      final mockPlayer = _MockAudioPlayer();
      _stubMockPlayer(mockPlayer);
      final container = _makeContainer(mockPlayer);

      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(
        844,
        390,
      );

      await tester.pumpWidget(_harness(container, _recording()));
      // Drain the microtask the widget posts to call notifier.load().
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      binding.platformDispatcher.views.first.physicalSize = const Size(
        390,
        844,
      );
      await tester.pump();

      verifyNever(() => mockPlayer.dispose());
      verify(() => mockPlayer.setFilePath(any())).called(1);
    },
  );

  testWidgets('unmounting the screen disposes the AudioPlayer', (tester) async {
    final mockPlayer = _MockAudioPlayer();
    _stubMockPlayer(mockPlayer);
    final container = _makeContainer(mockPlayer);

    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(390, 844);

    await tester.pumpWidget(_harness(container, _recording()));
    await container
        .read(recordingPlayerProvider(_recordingId).notifier)
        .load(filePath: _filePath);
    await tester.pump();

    // Replace the subtree so RecordingHeroPlayer unmounts.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      ),
    );
    await tester.pump();
    // Allow autoDispose to schedule and run.
    await tester.pump(const Duration(milliseconds: 10));

    verify(() => mockPlayer.dispose()).called(1);
  });
}
