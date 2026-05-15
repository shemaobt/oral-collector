enum StorageBannerSeverity { none, critical, forceStopped }

class RecordingState {
  final bool isRecording;
  final bool isPaused;
  final Duration elapsed;
  final String? currentGenreId;
  final String? currentSubcategoryId;
  final Stream<double>? amplitudeStream;
  final String? sessionId;
  final Duration? lastCheckpointAt;
  final bool showCheckpointToast;
  final StorageBannerSeverity storageBannerSeverity;
  final RecordingResult? autoStoppedResult;
  final bool isPendingResume;
  final bool wasResumedSession;
  final String? currentGenreName;
  final String? currentSubcategoryName;

  const RecordingState({
    this.isRecording = false,
    this.isPaused = false,
    this.elapsed = Duration.zero,
    this.currentGenreId,
    this.currentSubcategoryId,
    this.amplitudeStream,
    this.sessionId,
    this.lastCheckpointAt,
    this.showCheckpointToast = false,
    this.storageBannerSeverity = StorageBannerSeverity.none,
    this.autoStoppedResult,
    this.isPendingResume = false,
    this.wasResumedSession = false,
    this.currentGenreName,
    this.currentSubcategoryName,
  });

  RecordingState copyWith({
    bool? isRecording,
    bool? isPaused,
    Duration? elapsed,
    String? currentGenreId,
    String? currentSubcategoryId,
    Stream<double>? amplitudeStream,
    String? sessionId,
    Duration? lastCheckpointAt,
    bool? showCheckpointToast,
    StorageBannerSeverity? storageBannerSeverity,
    RecordingResult? autoStoppedResult,
    bool? isPendingResume,
    bool? wasResumedSession,
    String? currentGenreName,
    String? currentSubcategoryName,
    bool clearGenreId = false,
    bool clearSubcategoryId = false,
    bool clearAmplitudeStream = false,
    bool clearSessionId = false,
    bool clearLastCheckpoint = false,
    bool clearAutoStoppedResult = false,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      elapsed: elapsed ?? this.elapsed,
      currentGenreId: clearGenreId
          ? null
          : (currentGenreId ?? this.currentGenreId),
      currentSubcategoryId: clearSubcategoryId
          ? null
          : (currentSubcategoryId ?? this.currentSubcategoryId),
      amplitudeStream: clearAmplitudeStream
          ? null
          : (amplitudeStream ?? this.amplitudeStream),
      sessionId: clearSessionId ? null : (sessionId ?? this.sessionId),
      lastCheckpointAt: clearLastCheckpoint
          ? null
          : (lastCheckpointAt ?? this.lastCheckpointAt),
      showCheckpointToast: showCheckpointToast ?? this.showCheckpointToast,
      storageBannerSeverity:
          storageBannerSeverity ?? this.storageBannerSeverity,
      autoStoppedResult: clearAutoStoppedResult
          ? null
          : (autoStoppedResult ?? this.autoStoppedResult),
      isPendingResume: isPendingResume ?? this.isPendingResume,
      wasResumedSession: wasResumedSession ?? this.wasResumedSession,
      currentGenreName: clearGenreId
          ? null
          : (currentGenreName ?? this.currentGenreName),
      currentSubcategoryName: clearSubcategoryId
          ? null
          : (currentSubcategoryName ?? this.currentSubcategoryName),
    );
  }
}

class RecordingResult {
  final String filePath;
  final double durationSeconds;
  final String format;

  const RecordingResult({
    required this.filePath,
    required this.durationSeconds,
    this.format = 'm4a',
  });
}

enum NoiseSensitivity { low, medium, high }
