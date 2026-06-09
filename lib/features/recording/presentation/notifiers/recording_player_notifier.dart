import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/services/audio_path_resolver.dart';
import 'recording_player_state.dart';

final audioPlayerFactoryProvider = Provider<AudioPlayer Function()>(
  (_) => AudioPlayer.new,
);

final audioPathResolverProvider = Provider<Future<String?> Function(String)>(
  (_) => resolveRecordingPath,
);

final recordingPlayerProvider = NotifierProvider.autoDispose
    .family<RecordingPlayerNotifier, RecordingPlayerState, String>(
      RecordingPlayerNotifier.new,
    );

class RecordingPlayerNotifier
    extends AutoDisposeFamilyNotifier<RecordingPlayerState, String> {
  late final AudioPlayer player;
  String? _lastKey;
  Future<void>? _inFlight;
  bool _disposed = false;

  @override
  RecordingPlayerState build(String arg) {
    player = ref.read(audioPlayerFactoryProvider)();
    // Riverpod 2.6.1 has no ref.mounted; flag dispose so post-await writes can
    // bail instead of mutating a disposed (autoDispose) notifier.
    ref.onDispose(() {
      _disposed = true;
      player.dispose();
    });
    return const RecordingPlayerState();
  }

  Future<void> load({String? filePath, String? url}) async {
    final key = '${filePath ?? ''}|${url ?? ''}';

    if (_lastKey == key) {
      if (_inFlight != null) return _inFlight;
      if (state.hasAudio || state.errorKind != null) return;
    }
    _lastKey = key;

    final future = _doLoad(filePath: filePath, url: url);
    _inFlight = future;
    try {
      await future;
    } finally {
      if (identical(_inFlight, future)) _inFlight = null;
    }
  }

  Future<void> _doLoad({String? filePath, String? url}) async {
    final hasFilePath = filePath != null && filePath.isNotEmpty;
    final hasUrl = url != null && url.isNotEmpty;

    state = const RecordingPlayerState(isLoading: true);

    if (!hasFilePath && !hasUrl) {
      state = const RecordingPlayerState(isLoading: false, hasAudio: false);
      return;
    }

    try {
      if (hasFilePath) {
        final resolver = ref.read(audioPathResolverProvider);
        final resolved = await resolver(filePath);
        if (_disposed) return;
        if (resolved != null) {
          await player.setFilePath(resolved);
          if (_disposed) return;
          state = const RecordingPlayerState(isLoading: false, hasAudio: true);
          return;
        }
        if (hasUrl) {
          await player.setUrl(url);
          if (_disposed) return;
          state = const RecordingPlayerState(isLoading: false, hasAudio: true);
          return;
        }
        state = const RecordingPlayerState(
          isLoading: false,
          hasAudio: false,
          errorKind: RecordingPlayerError.fileNotFound,
        );
        return;
      }
      await player.setUrl(url!);
      if (_disposed) return;
      state = const RecordingPlayerState(isLoading: false, hasAudio: true);
    } on Object catch (e, st) {
      if (_disposed) return;
      debugPrint('RecordingPlayerNotifier.load failed: $e\n$st');
      state = const RecordingPlayerState(
        isLoading: false,
        hasAudio: false,
        errorKind: RecordingPlayerError.loadFailed,
      );
    }
  }

  Future<void> togglePlay() async {
    final current = player.playerState;
    if (current.processingState == ProcessingState.completed) {
      await player.seek(Duration.zero);
      await player.play();
    } else if (current.playing) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  Future<void> seek(Duration position) async {
    await player.seek(position);
  }

  Future<void> stop() async {
    await player.stop();
  }
}
