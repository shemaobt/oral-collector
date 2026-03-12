import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'recording_session_state.dart';

final noiseSensitivityProvider = StateProvider<NoiseSensitivity>(
  (ref) => NoiseSensitivity.medium,
);

final recordingSessionNotifierProvider =
    NotifierProvider<RecordingSessionNotifier, RecordingState>(
      RecordingSessionNotifier.new,
    );

class RecordingSessionNotifier extends Notifier<RecordingState> {
  AudioRecorder? _recorder;
  Timer? _elapsedTimer;
  StreamController<double>? _amplitudeController;
  StreamSubscription? _amplitudeSubscription;

  @override
  RecordingState build() {
    ref.onDispose(_cleanup);
    return const RecordingState();
  }

  Future<bool> startRecording(String genreId, String subcategoryId) async {
    if (state.isRecording) return true;

    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    _amplitudeController?.close();
    _amplitudeController = null;
    await _recorder?.dispose();
    _recorder = AudioRecorder();

    final hasPermission = await _recorder!.hasPermission();
    if (!hasPermission) {
      return false;
    }

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${dir.path}/recording_$timestamp.m4a';

    await _recorder!.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: filePath,
    );

    _amplitudeController = StreamController<double>.broadcast();

    try {
      _amplitudeSubscription = _recorder!
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((amp) {
            final sensitivity = ref.read(noiseSensitivityProvider);
            final threshold = switch (sensitivity) {
              NoiseSensitivity.low => -40.0,
              NoiseSensitivity.medium => -60.0,
              NoiseSensitivity.high => -80.0,
            };
            final dB = amp.current;
            final normalized = dB <= threshold
                ? 0.0
                : ((dB - threshold) / -threshold).clamp(0.0, 1.0);
            _amplitudeController?.add(normalized);
          });
    } catch (_) {}

    state = RecordingState(
      isRecording: true,
      isPaused: false,
      elapsed: Duration.zero,
      currentGenreId: genreId,
      currentSubcategoryId: subcategoryId,
      amplitudeStream: _amplitudeController!.stream,
    );

    _startElapsedTimer();
    return true;
  }

  Future<void> pauseRecording() async {
    if (!state.isRecording || state.isPaused) return;

    await _recorder?.pause();
    _elapsedTimer?.cancel();
    state = state.copyWith(isPaused: true);
  }

  Future<void> resumeRecording() async {
    if (!state.isRecording || !state.isPaused) return;

    await _recorder?.resume();
    _startElapsedTimer();
    state = state.copyWith(isPaused: false);
  }

  Future<RecordingResult?> stopRecording() async {
    if (!state.isRecording) return null;

    _elapsedTimer?.cancel();
    await _amplitudeSubscription?.cancel();
    _amplitudeController?.close();
    _amplitudeSubscription = null;
    _amplitudeController = null;
    final durationSeconds = state.elapsed.inMilliseconds / 1000.0;

    final filePath = await _recorder?.stop();

    state = const RecordingState();

    if (filePath == null) return null;

    return RecordingResult(
      filePath: filePath,
      durationSeconds: durationSeconds,
    );
  }

  Future<void> discardRecording() async {
    if (!state.isRecording) return;

    _elapsedTimer?.cancel();
    await _amplitudeSubscription?.cancel();
    _amplitudeController?.close();
    _amplitudeSubscription = null;
    _amplitudeController = null;
    await _recorder?.stop();

    state = const RecordingState();
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(
        elapsed: state.elapsed + const Duration(seconds: 1),
      );
    });
  }

  void _cleanup() {
    _elapsedTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _amplitudeController?.close();
    _recorder?.dispose();
    _recorder = null;
  }
}
