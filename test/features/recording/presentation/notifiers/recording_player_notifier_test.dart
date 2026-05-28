import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_player_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_player_state.dart';

class _MockAudioPlayer extends Mock implements AudioPlayer {}

const _recordingId = 'rec-test';

ProviderContainer _container({
  required _MockAudioPlayer mockPlayer,
  Future<String?> Function(String)? resolver,
}) {
  final container = ProviderContainer(
    overrides: [
      audioPlayerFactoryProvider.overrideWithValue(() => mockPlayer),
      if (resolver != null)
        audioPathResolverProvider.overrideWithValue(resolver),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void _stubBasicPlayerStubs(_MockAudioPlayer mockPlayer) {
  when(() => mockPlayer.dispose()).thenAnswer((_) async {});
  when(() => mockPlayer.stop()).thenAnswer((_) async {});
}

void main() {
  setUpAll(() {
    registerFallbackValue(Duration.zero);
  });

  group('RecordingPlayerNotifier.load', () {
    test(
      'with a resolved local filePath calls setFilePath and reports hasAudio',
      () async {
        final mockPlayer = _MockAudioPlayer();
        _stubBasicPlayerStubs(mockPlayer);
        when(() => mockPlayer.setFilePath(any())).thenAnswer((_) async => null);

        final container = _container(
          mockPlayer: mockPlayer,
          resolver: (path) async => '/docs/$path',
        );

        final notifier = container.read(
          recordingPlayerProvider(_recordingId).notifier,
        );
        await notifier.load(filePath: 'recording.m4a');

        verify(() => mockPlayer.setFilePath('/docs/recording.m4a')).called(1);
        final state = container.read(recordingPlayerProvider(_recordingId));
        expect(state.isLoading, isFalse);
        expect(state.hasAudio, isTrue);
        expect(state.errorKind, isNull);
      },
    );

    test(
      'when local file is missing and url is provided, falls back to setUrl',
      () async {
        final mockPlayer = _MockAudioPlayer();
        _stubBasicPlayerStubs(mockPlayer);
        when(() => mockPlayer.setUrl(any())).thenAnswer((_) async => null);

        final container = _container(
          mockPlayer: mockPlayer,
          resolver: (_) async => null,
        );
        final notifier = container.read(
          recordingPlayerProvider(_recordingId).notifier,
        );
        await notifier.load(
          filePath: 'missing.m4a',
          url: 'https://example.com/file.m4a',
        );

        verify(
          () => mockPlayer.setUrl('https://example.com/file.m4a'),
        ).called(1);
        final state = container.read(recordingPlayerProvider(_recordingId));
        expect(state.hasAudio, isTrue);
        expect(state.errorKind, isNull);
      },
    );

    test(
      'when local file is missing and no url is given, reports fileNotFound error',
      () async {
        final mockPlayer = _MockAudioPlayer();
        _stubBasicPlayerStubs(mockPlayer);

        final container = _container(
          mockPlayer: mockPlayer,
          resolver: (_) async => null,
        );
        final notifier = container.read(
          recordingPlayerProvider(_recordingId).notifier,
        );
        await notifier.load(filePath: 'missing.m4a');

        verifyNever(() => mockPlayer.setFilePath(any()));
        verifyNever(() => mockPlayer.setUrl(any()));
        final state = container.read(recordingPlayerProvider(_recordingId));
        expect(state.errorKind, RecordingPlayerError.fileNotFound);
        expect(state.hasAudio, isFalse);
        expect(state.isLoading, isFalse);
      },
    );

    test('when setFilePath throws, reports loadFailed error', () async {
      final mockPlayer = _MockAudioPlayer();
      _stubBasicPlayerStubs(mockPlayer);
      when(
        () => mockPlayer.setFilePath(any()),
      ).thenThrow(Exception('decoder boom'));

      final container = _container(
        mockPlayer: mockPlayer,
        resolver: (path) async => '/docs/$path',
      );
      final notifier = container.read(
        recordingPlayerProvider(_recordingId).notifier,
      );
      await notifier.load(filePath: 'broken.m4a');

      final state = container.read(recordingPlayerProvider(_recordingId));
      expect(state.errorKind, RecordingPlayerError.loadFailed);
      expect(state.hasAudio, isFalse);
      expect(state.isLoading, isFalse);
    });

    test(
      'with neither filePath nor url, reports no audio without error',
      () async {
        final mockPlayer = _MockAudioPlayer();
        _stubBasicPlayerStubs(mockPlayer);

        final container = _container(mockPlayer: mockPlayer);
        final notifier = container.read(
          recordingPlayerProvider(_recordingId).notifier,
        );
        await notifier.load();

        verifyNever(() => mockPlayer.setFilePath(any()));
        verifyNever(() => mockPlayer.setUrl(any()));
        final state = container.read(recordingPlayerProvider(_recordingId));
        expect(state.hasAudio, isFalse);
        expect(state.errorKind, isNull);
        expect(state.isLoading, isFalse);
      },
    );

    test(
      'reloading with the same filePath does not re-call setFilePath',
      () async {
        final mockPlayer = _MockAudioPlayer();
        _stubBasicPlayerStubs(mockPlayer);
        when(() => mockPlayer.setFilePath(any())).thenAnswer((_) async => null);

        final container = _container(
          mockPlayer: mockPlayer,
          resolver: (path) async => '/docs/$path',
        );
        final notifier = container.read(
          recordingPlayerProvider(_recordingId).notifier,
        );
        await notifier.load(filePath: 'rec.m4a');
        await notifier.load(filePath: 'rec.m4a');

        verify(() => mockPlayer.setFilePath('/docs/rec.m4a')).called(1);
      },
    );
  });

  group('RecordingPlayerNotifier.togglePlay', () {
    test('calls play when player reports not playing', () async {
      final mockPlayer = _MockAudioPlayer();
      _stubBasicPlayerStubs(mockPlayer);
      when(
        () => mockPlayer.playerState,
      ).thenReturn(PlayerState(false, ProcessingState.ready));
      when(() => mockPlayer.play()).thenAnswer((_) async {});

      final container = _container(mockPlayer: mockPlayer);
      final notifier = container.read(
        recordingPlayerProvider(_recordingId).notifier,
      );
      await notifier.togglePlay();

      verify(() => mockPlayer.play()).called(1);
    });

    test('calls pause when player reports playing', () async {
      final mockPlayer = _MockAudioPlayer();
      _stubBasicPlayerStubs(mockPlayer);
      when(
        () => mockPlayer.playerState,
      ).thenReturn(PlayerState(true, ProcessingState.ready));
      when(() => mockPlayer.pause()).thenAnswer((_) async {});

      final container = _container(mockPlayer: mockPlayer);
      final notifier = container.read(
        recordingPlayerProvider(_recordingId).notifier,
      );
      await notifier.togglePlay();

      verify(() => mockPlayer.pause()).called(1);
    });

    test('after completion, seeks to zero and plays from start', () async {
      final mockPlayer = _MockAudioPlayer();
      _stubBasicPlayerStubs(mockPlayer);
      when(
        () => mockPlayer.playerState,
      ).thenReturn(PlayerState(false, ProcessingState.completed));
      when(() => mockPlayer.seek(any())).thenAnswer((_) async {});
      when(() => mockPlayer.play()).thenAnswer((_) async {});

      final container = _container(mockPlayer: mockPlayer);
      final notifier = container.read(
        recordingPlayerProvider(_recordingId).notifier,
      );
      await notifier.togglePlay();

      verify(() => mockPlayer.seek(Duration.zero)).called(1);
      verify(() => mockPlayer.play()).called(1);
    });
  });

  group('RecordingPlayerNotifier lifecycle', () {
    test('disposing the container disposes the underlying player', () async {
      final mockPlayer = _MockAudioPlayer();
      _stubBasicPlayerStubs(mockPlayer);

      final container = ProviderContainer(
        overrides: [
          audioPlayerFactoryProvider.overrideWithValue(() => mockPlayer),
        ],
      );
      container.read(recordingPlayerProvider(_recordingId).notifier);
      container.dispose();

      verify(() => mockPlayer.dispose()).called(1);
    });
  });
}
