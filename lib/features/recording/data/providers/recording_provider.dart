import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

// --- State ---

class RecordingState {
  final bool isRecording;
  final bool isPaused;
  final Duration elapsed;
  final String? currentGenreId;
  final String? currentSubcategoryId;
  final Stream<double>? amplitudeStream;

  const RecordingState({
    this.isRecording = false,
    this.isPaused = false,
    this.elapsed = Duration.zero,
    this.currentGenreId,
    this.currentSubcategoryId,
    this.amplitudeStream,
  });

  RecordingState copyWith({
    bool? isRecording,
    bool? isPaused,
    Duration? elapsed,
    String? currentGenreId,
    String? currentSubcategoryId,
    Stream<double>? amplitudeStream,
    bool clearGenreId = false,
    bool clearSubcategoryId = false,
    bool clearAmplitudeStream = false,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      elapsed: elapsed ?? this.elapsed,
      currentGenreId:
          clearGenreId ? null : (currentGenreId ?? this.currentGenreId),
      currentSubcategoryId: clearSubcategoryId
          ? null
          : (currentSubcategoryId ?? this.currentSubcategoryId),
      amplitudeStream: clearAmplitudeStream
          ? null
          : (amplitudeStream ?? this.amplitudeStream),
    );
  }
}

// --- Result type for stopRecording ---

class RecordingResult {
  final String filePath;
  final double durationSeconds;

  const RecordingResult({
    required this.filePath,
    required this.durationSeconds,
  });
}

// --- Providers ---

final recordingNotifierProvider =
    NotifierProvider<RecordingNotifier, RecordingState>(RecordingNotifier.new);

// --- Notifier ---

class RecordingNotifier extends Notifier<RecordingState> {
  AudioRecorder? _recorder;
  Timer? _elapsedTimer;

  @override
  RecordingState build() {
    ref.onDispose(_cleanup);
    return const RecordingState();
  }

  /// Start a new recording session for the given genre and subcategory.
  ///
  /// Requests microphone permission at point of use. Returns `false` if
  /// permission was denied (caller should show instructional dialog).
  Future<bool> startRecording(String genreId, String subcategoryId) async {
    _recorder ??= AudioRecorder();

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

    // Create amplitude stream (emits normalized 0.0–1.0 values).
    final ampStream = _recorder!
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .map((amp) => amp.current);

    state = RecordingState(
      isRecording: true,
      isPaused: false,
      elapsed: Duration.zero,
      currentGenreId: genreId,
      currentSubcategoryId: subcategoryId,
      amplitudeStream: ampStream,
    );

    _startElapsedTimer();
    return true;
  }

  /// Pause the current recording.
  Future<void> pauseRecording() async {
    if (!state.isRecording || state.isPaused) return;

    await _recorder?.pause();
    _elapsedTimer?.cancel();
    state = state.copyWith(isPaused: true);
  }

  /// Resume a paused recording.
  Future<void> resumeRecording() async {
    if (!state.isRecording || !state.isPaused) return;

    await _recorder?.resume();
    _startElapsedTimer();
    state = state.copyWith(isPaused: false);
  }

  /// Stop the current recording and return the file path and duration.
  ///
  /// Returns `null` if no recording is in progress.
  Future<RecordingResult?> stopRecording() async {
    if (!state.isRecording) return null;

    _elapsedTimer?.cancel();
    final durationSeconds = state.elapsed.inMilliseconds / 1000.0;

    final filePath = await _recorder?.stop();

    state = const RecordingState();

    if (filePath == null) return null;

    return RecordingResult(
      filePath: filePath,
      durationSeconds: durationSeconds,
    );
  }

  /// Discard the current recording without saving.
  Future<void> discardRecording() async {
    if (!state.isRecording) return;

    _elapsedTimer?.cancel();
    await _recorder?.stop();

    state = const RecordingState();
  }

  // --- Private helpers ---

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
    _recorder?.dispose();
    _recorder = null;
  }
}
