import 'dart:async';
import 'dart:io' show File, Platform;
import 'dart:math' as math;

import 'package:audio_session/audio_session.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/platform/ffmpeg_ops.dart' as ffmpeg_ops;
import '../../../../core/platform/file_ops.dart' as file_ops;
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/format.dart' as fmt;
import '../../../project/presentation/notifiers/project_notifier.dart';
import '../../data/providers.dart';
import '../../data/services/recording_concat_service.dart';
import '../../data/services/recording_finalization_service.dart';
import '../../data/services/recording_foreground_service.dart';
import '../../data/services/recording_live_activity.dart';
import '../../data/services/recording_notification.dart';
import '../../data/services/recovery_coordinator.dart';
import '../../data/services/segment_paths.dart';
import '../../data/services/segmented_recorder.dart';
import '../../data/services/session_recovery.dart';
import '../../data/services/storage_guard.dart';
import '../../data/services/wav_concat.dart';
import 'input_device_notifier.dart';
import 'recording_session_state.dart';

final noiseSensitivityProvider = StateProvider<NoiseSensitivity>(
  (ref) => NoiseSensitivity.medium,
);

final storageGuardProvider = Provider<StorageGuard>((_) => StorageGuard());

final recordingConcatServiceProvider = Provider<RecordingConcatService>(
  (_) => RecordingConcatService(),
);

final recordingFinalizationServiceProvider =
    Provider<RecordingFinalizationService>((ref) {
      return RecordingFinalizationService(
        concat: ref.watch(recordingConcatServiceProvider),
      );
    });

final recordingForegroundServiceProvider = Provider<RecordingForegroundService>(
  (_) => RecordingForegroundService(),
);

final recordingSessionNotifierProvider =
    NotifierProvider<RecordingSessionNotifier, RecordingState>(
      RecordingSessionNotifier.new,
    );

/// Holds the recording that is awaiting a save/discard/re-record decision
/// from the user (i.e. the user is on the ConfirmationStep). `null` means
/// no recording is pending. Read by AppShell and screen-level PopScopes to
/// block accidental navigation that would orphan the audio file.
final pendingRecordingDecisionProvider = StateProvider<RecordingResult?>(
  (_) => null,
);

class RecordingSessionNotifier extends Notifier<RecordingState> {
  SegmentedRecorder? _segRecorder;
  AudioRecorder? _webRecorder;
  String? _webPendingKey;
  Timer? _elapsedTimer;
  Timer? _toastTimer;
  StreamController<double>? _webAmplitudeController;
  StreamSubscription<Amplitude>? _webAmplitudeSub;
  bool _liveActivityActive = false;
  StreamSubscription<dynamic>? _liveActivityUrlSub;
  AppLocalizations? _cachedL10n;
  String? _pendingResumeSessionId;
  List<String>? _pendingResumeSegmentPaths;
  Duration? _pendingResumeDuration;

  @override
  RecordingState build() {
    ref.onDispose(_cleanup);
    return const RecordingState();
  }

  Future<StorageCheck<PreStartSeverity>> checkStorageBeforeStart() {
    return ref.read(storageGuardProvider).checkBeforeStart();
  }

  void acknowledgeAutoStop() {
    if (state.autoStoppedResult != null) {
      state = state.copyWith(clearAutoStoppedResult: true);
    }
  }

  void acknowledgeLastStopError() {
    if (state.lastStopError != null) {
      state = state.copyWith(clearLastStopError: true);
    }
  }

  Future<void> reactivateAudioSession() async {
    if (!state.isRecording || kIsWeb) return;
    try {
      final session = await AudioSession.instance;
      await session.setActive(true);
      debugPrint(
        'RecordingSessionNotifier: audio session re-activated on resume',
      );
    } on Exception catch (e) {
      debugPrint('RecordingSessionNotifier: re-activate failed: $e');
    }
  }

  Future<bool> loadInterruptedSession(String sessionId) async {
    if (kIsWeb) return false;
    if (state.isRecording) return false;

    final sessionRepo = ref.read(recordingSessionRepositoryProvider);
    final session = await sessionRepo.getById(sessionId);
    if (session == null) return false;

    final paths = sessionRepo.decodeSegmentPaths(session);
    final validPaths = <String>[];
    for (final p in paths) {
      if (await file_ops.fileExists(p)) {
        validPaths.add(p);
      }
    }
    if (validPaths.isEmpty) {
      await sessionRepo.markDiscarded(session.id);
      await ref.read(recoveryCoordinatorProvider).refresh();
      return false;
    }

    await _cleanupOrphanedSegments(session.id, session.lastSegmentIndex);

    _pendingResumeSessionId = session.id;
    _pendingResumeSegmentPaths = validPaths;
    _pendingResumeDuration = Duration(
      milliseconds: (session.totalDurationSeconds * 1000).round(),
    );

    state = RecordingState(
      isRecording: true,
      isPaused: true,
      elapsed: _pendingResumeDuration!,
      currentGenreId: session.genreId,
      currentSubcategoryId: session.subcategoryId,
      sessionId: session.id,
      isPendingResume: true,
      wasResumedSession: true,
    );
    await ref.read(recoveryCoordinatorProvider).refresh();
    return true;
  }

  Future<void> cancelPendingResume() async {
    if (kIsWeb) return;
    final pendingSessionId = _pendingResumeSessionId;

    if (pendingSessionId != null && _segRecorder == null) {
      _pendingResumeSessionId = null;
      _pendingResumeSegmentPaths = null;
      _pendingResumeDuration = null;
      state = const RecordingState();
      await ref.read(recoveryCoordinatorProvider).refresh();
      return;
    }

    final activeSessionId = state.sessionId;
    final recorder = _segRecorder;
    if (recorder == null || activeSessionId == null) {
      return;
    }

    _elapsedTimer?.cancel();
    _toastTimer?.cancel();
    await recorder.finish();
    _segRecorder = null;

    final sessionRepo = ref.read(recordingSessionRepositoryProvider);
    await sessionRepo.markCrashed(activeSessionId);

    state = const RecordingState();
    await RecordingNotification.instance.clear();
    await _stopLiveActivityIfIOS();
    await _stopForegroundServiceIfAndroid();
    await ref.read(recoveryCoordinatorProvider).refresh();
  }

  Future<void> _cleanupOrphanedSegments(
    String sessionId,
    int lastFinalizedIndex,
  ) async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final prefix = SegmentPaths.prefixFor(dir.path, sessionId);
      final entries = await dir.list().toList();
      for (final entry in entries) {
        if (entry is! File) continue;
        final index = SegmentPaths.parseIndex(entry.path, prefix);
        if (index == null) continue;
        if (index > lastFinalizedIndex) {
          try {
            await entry.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  Future<bool> startRecording(
    String genreId,
    String subcategoryId, {
    String? projectId,
    String? genreName,
    String? subcategoryName,
  }) async {
    if (state.isRecording) return true;

    final mapper = _amplitudeMapperFor(ref.read(noiseSensitivityProvider));

    if (kIsWeb) {
      return _startWeb(genreId, subcategoryId, mapper);
    }

    final resolvedProjectId =
        projectId ?? ref.read(projectNotifierProvider).activeProject?.id ?? '';
    return _startNative(
      genreId,
      subcategoryId,
      resolvedProjectId,
      mapper,
      genreName: genreName,
      subcategoryName: subcategoryName,
    );
  }

  Future<bool> _startNative(
    String genreId,
    String subcategoryId,
    String projectId,
    AmplitudeMapper mapper, {
    String? genreName,
    String? subcategoryName,
  }) async {
    final sessionRepo = ref.read(recordingSessionRepositoryProvider);
    final storageGuard = ref.read(storageGuardProvider);

    final sessionId = _newSessionId();
    await sessionRepo.insertSession(
      RecordingSessionsCompanion.insert(
        id: sessionId,
        projectId: projectId,
        genreId: genreId,
        subcategoryId: subcategoryId.isEmpty
            ? const Value.absent()
            : Value(subcategoryId),
        startedAt: DateTime.now(),
      ),
    );

    await _segRecorder?.dispose();
    final recorder = SegmentedRecorder(
      sessionRepo: sessionRepo,
      storageGuard: storageGuard,
    );
    _segRecorder = recorder;
    _attachRecorderCallbacks(recorder);

    final ok = await recorder.startSession(
      sessionId: sessionId,
      amplitudeMapper: mapper,
      inputDevice: ref.read(inputDeviceNotifierProvider).selectedDevice,
    );
    if (!ok) {
      await sessionRepo.markDiscarded(sessionId);
      _segRecorder = null;
      return false;
    }

    state = RecordingState(
      isRecording: true,
      isPaused: false,
      elapsed: Duration.zero,
      currentGenreId: genreId,
      currentSubcategoryId: subcategoryId,
      currentGenreName: genreName,
      currentSubcategoryName: subcategoryName,
      amplitudeStream: recorder.amplitudeStream,
      sessionId: sessionId,
    );

    _startElapsedTimer();
    final liveActivityStarted = await _startLiveActivityIfIOS(sessionId);
    if (!liveActivityStarted) {
      await _showRecordingNotification();
    }
    await _startForegroundServiceIfAndroid();
    return true;
  }

  Future<bool> _startWeb(
    String genreId,
    String subcategoryId,
    AmplitudeMapper mapper,
  ) async {
    await _disposeWebRecorder();
    final recorder = AudioRecorder();
    final hasPermission = await recorder.hasPermission();
    if (!hasPermission) {
      await recorder.dispose();
      return false;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _webPendingKey = 'web_record_$timestamp';

    final device = ref.read(inputDeviceNotifierProvider).selectedDevice;
    await recorder.start(
      RecordConfig(encoder: AudioEncoder.opus, device: device),
      path: '',
    );

    _webRecorder = recorder;

    final ctrl = StreamController<double>.broadcast();
    _webAmplitudeController = ctrl;
    _webAmplitudeSub = recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
          if (ctrl.isClosed) return;
          ctrl.add(mapper(amp.current));
        });

    state = RecordingState(
      isRecording: true,
      isPaused: false,
      elapsed: Duration.zero,
      currentGenreId: genreId,
      currentSubcategoryId: subcategoryId,
      amplitudeStream: ctrl.stream,
    );

    _startElapsedTimer();
    return true;
  }

  Future<void> pauseRecording() async {
    if (!state.isRecording || state.isPaused) return;

    if (kIsWeb) {
      await _webRecorder?.pause();
    } else {
      await _segRecorder?.pause();
    }
    _elapsedTimer?.cancel();
    state = state.copyWith(isPaused: true);
  }

  Future<void> resumeRecording() async {
    if (!state.isRecording || !state.isPaused) return;

    if (!kIsWeb && _segRecorder == null && _pendingResumeSessionId != null) {
      final ok = await _startRecorderForResume();
      if (!ok) return;
      state = state.copyWith(isPaused: false);
      return;
    }

    if (kIsWeb) {
      await _webRecorder?.resume();
    } else {
      await _segRecorder?.resume();
    }
    _startElapsedTimer();
    state = state.copyWith(isPaused: false);
  }

  Future<bool> _startRecorderForResume() async {
    final sessionId = _pendingResumeSessionId;
    final segmentPaths = _pendingResumeSegmentPaths;
    final duration = _pendingResumeDuration;
    if (sessionId == null || segmentPaths == null || duration == null) {
      return false;
    }

    final sessionRepo = ref.read(recordingSessionRepositoryProvider);
    final storageGuard = ref.read(storageGuardProvider);

    await sessionRepo.markActive(sessionId);

    await _segRecorder?.dispose();
    final recorder = SegmentedRecorder(
      sessionRepo: sessionRepo,
      storageGuard: storageGuard,
    );
    _segRecorder = recorder;
    _attachRecorderCallbacks(recorder);

    final mapper = _amplitudeMapperFor(ref.read(noiseSensitivityProvider));
    final ok = await recorder.startSession(
      sessionId: sessionId,
      amplitudeMapper: mapper,
      inputDevice: ref.read(inputDeviceNotifierProvider).selectedDevice,
      resumeFromPaths: segmentPaths,
      resumeFromDuration: duration,
    );
    if (!ok) {
      _segRecorder = null;
      return false;
    }

    state = state.copyWith(
      amplitudeStream: recorder.amplitudeStream,
      sessionId: sessionId,
      isPendingResume: false,
      wasResumedSession: true,
    );

    _pendingResumeSessionId = null;
    _pendingResumeSegmentPaths = null;
    _pendingResumeDuration = null;

    _startElapsedTimer();
    final liveActivityStarted = await _startLiveActivityIfIOS(sessionId);
    if (!liveActivityStarted) {
      await _showRecordingNotification();
    }
    await _startForegroundServiceIfAndroid();

    await ref.read(recoveryCoordinatorProvider).refresh();
    return true;
  }

  void _attachRecorderCallbacks(SegmentedRecorder recorder) {
    recorder.onCheckpoint = (totalSaved) {
      _toastTimer?.cancel();
      state = state.copyWith(
        lastCheckpointAt: totalSaved,
        showCheckpointToast: true,
      );
      _toastTimer = Timer(const Duration(seconds: 2), () {
        state = state.copyWith(showCheckpointToast: false);
      });
    };

    recorder.onStorageCritical = (_) {
      if (state.storageBannerSeverity != StorageBannerSeverity.forceStopped) {
        state = state.copyWith(
          storageBannerSeverity: StorageBannerSeverity.critical,
        );
      }
    };

    recorder.onStorageForceStop = () {
      state = state.copyWith(
        storageBannerSeverity: StorageBannerSeverity.forceStopped,
      );
      scheduleMicrotask(() async {
        final result = await stopRecording();
        if (result != null) {
          state = state.copyWith(autoStoppedResult: result);
        }
      });
    };
  }

  Future<RecordingResult?> stopRecording() async {
    if (!state.isRecording || state.isFinalizing) return null;

    _elapsedTimer?.cancel();
    _toastTimer?.cancel();
    final elapsed = state.elapsed;

    if (kIsWeb) {
      return _stopWeb(elapsed);
    }
    return _stopNative(elapsed);
  }

  Future<RecordingResult?> _stopNative(Duration fallbackElapsed) async {
    final recorder = _segRecorder;
    final sessionId = state.sessionId;
    final sessionRepo = ref.read(recordingSessionRepositoryProvider);

    if (recorder == null) {
      final pendingSessionId = _pendingResumeSessionId;
      final pendingPaths = _pendingResumeSegmentPaths;
      final pendingDuration = _pendingResumeDuration;
      if (pendingSessionId != null &&
          pendingPaths != null &&
          pendingPaths.isNotEmpty) {
        _pendingResumeSessionId = null;
        _pendingResumeSegmentPaths = null;
        _pendingResumeDuration = null;
        state = const RecordingState();
        await RecordingNotification.instance.clear();
        await _stopLiveActivityIfIOS();
        await _stopForegroundServiceIfAndroid();

        final result = await _finalizeOrCrash(
          sessionId: pendingSessionId,
          segmentPaths: pendingPaths,
          totalDuration: pendingDuration ?? fallbackElapsed,
        );
        if (result != null) {
          await _cleanupOrphanedSegments(pendingSessionId, -1);
          await sessionRepo.markRecovered(pendingSessionId);
          await ref.read(recoveryCoordinatorProvider).refresh();
        }
        return result;
      }

      state = const RecordingState();
      await RecordingNotification.instance.clear();
      await _stopLiveActivityIfIOS();
      await _stopForegroundServiceIfAndroid();
      return null;
    }

    state = state.copyWith(finalizationStage: FinalizationStage.finalizing);

    // Capture session id up-front: SegmentedRecorder.finish() clears its
    // internal sessionId, and if finish() throws we still need to mark the
    // session crashed so the unsaved-recordings banner can rescue it.
    final activeSessionId = recorder.sessionId;

    SegmentedRecordingResult? sessionResult;
    Object? finishError;
    var degraded = false;
    try {
      sessionResult = await recorder.finish();
    } catch (e, st) {
      finishError = e;
      debugPrint('[stopNative] recorder.finish failed: $e\n$st');
      sessionResult = await _recoverFromDisk(sessionId);
      if (sessionResult != null) degraded = true;
    }
    _segRecorder = null;

    state = state.copyWith(
      isRecording: false,
      isPaused: false,
      elapsed: Duration.zero,
      clearAmplitudeStream: true,
      clearSessionId: true,
      clearLastCheckpoint: true,
      finalizationDegraded: degraded,
    );
    await RecordingNotification.instance.clear();
    await _stopLiveActivityIfIOS();
    await _stopForegroundServiceIfAndroid();

    final hasUsableResult =
        sessionResult != null && sessionResult.segmentPaths.isNotEmpty;
    if (!hasUsableResult) {
      final sessionIdForRecovery = sessionResult?.sessionId ?? activeSessionId;
      var recoverable = false;
      if (sessionIdForRecovery != null) {
        await sessionRepo.markCrashed(sessionIdForRecovery);
        await ref.read(recoveryCoordinatorProvider).refresh();
        recoverable = ref
            .read(interruptedSessionsProvider)
            .any((s) => s.sessionId == sessionIdForRecovery);
      }
      state = state.copyWith(
        finalizationStage: FinalizationStage.idle,
        finalizationError: 'No audio segments were saved.',
        lastStopError: RecordingStopError(
          kind: RecordingStopErrorKind.finishProducedNoSegments,
          recoverable: recoverable,
          technicalMessage: finishError?.toString(),
        ),
      );
      return null;
    }

    final totalDuration = sessionResult.totalDuration > Duration.zero
        ? sessionResult.totalDuration
        : fallbackElapsed;

    if (degraded) {
      state = state.copyWith(finalizationDegraded: true);
    }

    final result = await _finalizeWithStages(
      sessionId: sessionResult.sessionId,
      segmentPaths: sessionResult.segmentPaths,
      totalDuration: totalDuration,
    );
    if (result != null) {
      await sessionRepo.markCompleted(sessionResult.sessionId);
      state = const RecordingState();
    }
    return result;
  }

  Future<RecordingResult?> _finalizeWithStages({
    required String sessionId,
    required List<String> segmentPaths,
    required Duration totalDuration,
  }) async {
    if (segmentPaths.isEmpty) {
      state = state.copyWith(
        finalizationStage: FinalizationStage.idle,
        finalizationError: 'No audio segments were saved.',
      );
      return null;
    }

    final dir = await getApplicationDocumentsDirectory();
    String sourcePath;

    if (segmentPaths.length == 1) {
      sourcePath = segmentPaths.first;
    } else {
      state = state.copyWith(
        finalizationStage: FinalizationStage.combiningSegments,
      );
      final concat = ref.read(recordingConcatServiceProvider);
      final firstIsWav = segmentPaths.first.toLowerCase().endsWith('.wav');
      final concatExt = firstIsWav ? 'wav' : 'm4a';
      final concatPath = '${dir.path}/concat_$sessionId.$concatExt';

      String? concatResult;
      try {
        concatResult = await concat.concatSegments(
          segmentPaths: segmentPaths,
          outputPath: concatPath,
        );
      } catch (e, st) {
        debugPrint('[stopNative] concatSegments failed: $e\n$st');
        concatResult = null;
      }

      if (concatResult == null && firstIsWav) {
        try {
          final ok = await concatWavFilesInDart(
            segments: segmentPaths,
            outputPath: concatPath,
          );
          if (ok) {
            concatResult = concatPath;
            state = state.copyWith(finalizationDegraded: true);
          }
        } catch (e, st) {
          debugPrint('[stopNative] pure-dart WAV concat failed: $e\n$st');
        }
      }

      if (concatResult != null) {
        sourcePath = concatResult;
        for (final p in segmentPaths) {
          unawaited(_deleteFileSafe(p));
        }
      } else {
        sourcePath = segmentPaths.first;
        state = state.copyWith(finalizationDegraded: true);
      }
    }

    final isWav = sourcePath.toLowerCase().endsWith('.wav');
    if (isWav) {
      state = state.copyWith(
        finalizationStage: FinalizationStage.compressingAudio,
      );
      final m4aPath = '${dir.path}/recording_$sessionId.m4a';
      var ok = false;
      try {
        ok = await ffmpeg_ops.compressToM4a(sourcePath, m4aPath);
      } catch (e, st) {
        debugPrint('[stopNative] compressToM4a failed: $e\n$st');
        ok = false;
      }
      if (ok) {
        unawaited(_deleteFileSafe(sourcePath));
        return RecordingResult(
          filePath: m4aPath,
          durationSeconds: totalDuration.inMilliseconds / 1000.0,
        );
      }
      state = state.copyWith(finalizationDegraded: true);
      return RecordingResult(
        filePath: sourcePath,
        durationSeconds: totalDuration.inMilliseconds / 1000.0,
        format: 'wav',
      );
    }

    return RecordingResult(
      filePath: sourcePath,
      durationSeconds: totalDuration.inMilliseconds / 1000.0,
    );
  }

  Future<RecordingResult?> _finalizeOrCrash({
    required String sessionId,
    required List<String> segmentPaths,
    required Duration totalDuration,
  }) async {
    final sessionRepo = ref.read(recordingSessionRepositoryProvider);
    final finalizer = ref.read(recordingFinalizationServiceProvider);

    RecordingResult? result;
    Object? error;
    try {
      result = await finalizer.finalize(
        sessionId: sessionId,
        segmentPaths: segmentPaths,
        totalDuration: totalDuration,
      );
    } catch (e, st) {
      error = e;
      debugPrint(
        'RecordingSessionNotifier: finalize failed for $sessionId: $e\n$st',
      );
    }

    if (result != null) return result;

    await sessionRepo.markCrashed(sessionId);
    await ref.read(recoveryCoordinatorProvider).refresh();
    final recoverable = ref
        .read(interruptedSessionsProvider)
        .any((s) => s.sessionId == sessionId);
    state = state.copyWith(
      lastStopError: RecordingStopError(
        kind: RecordingStopErrorKind.finalizationFailed,
        recoverable: recoverable,
        technicalMessage: error?.toString(),
      ),
    );
    return null;
  }

  Future<SegmentedRecordingResult?> _recoverFromDisk(String? sessionId) async {
    if (sessionId == null) return null;
    try {
      final repo = ref.read(recordingSessionRepositoryProvider);
      final dir = await getApplicationDocumentsDirectory();
      return await recoverSessionFromDisk(
        repo: repo,
        sessionId: sessionId,
        documentsDir: dir,
      );
    } catch (e, st) {
      debugPrint('[stopNative] recoverFromDisk failed: $e\n$st');
      return null;
    }
  }

  void dismissFinalizationError() {
    state = state.copyWith(
      clearFinalizationError: true,
      finalizationStage: FinalizationStage.idle,
      finalizationDegraded: false,
    );
  }

  Future<RecordingResult?> _stopWeb(Duration fallbackElapsed) async {
    final recorder = _webRecorder;
    final pendingKey = _webPendingKey;
    if (recorder == null || pendingKey == null) {
      state = const RecordingState();
      return null;
    }

    state = state.copyWith(finalizationStage: FinalizationStage.finalizing);

    String? url;
    try {
      url = await recorder.stop();
    } catch (e, st) {
      debugPrint('[stopWeb] recorder.stop failed: $e\n$st');
      url = null;
    }
    await _disposeWebRecorder();

    state = state.copyWith(
      isRecording: false,
      isPaused: false,
      elapsed: Duration.zero,
      clearAmplitudeStream: true,
      clearSessionId: true,
      clearLastCheckpoint: true,
    );

    if (url == null || url.isEmpty) {
      state = state.copyWith(
        finalizationStage: FinalizationStage.idle,
        finalizationError: 'No audio was recorded.',
      );
      return null;
    }

    try {
      final bytes = await http.readBytes(Uri.parse(url));
      final format = _detectWebFormatFromUrl(url);
      final fullKey = '$pendingKey.$format';
      await file_ops.writeFileBytes(fullKey, bytes);
      state = const RecordingState();
      return RecordingResult(
        filePath: fullKey,
        durationSeconds: fallbackElapsed.inMilliseconds / 1000.0,
        format: format,
      );
    } catch (e, st) {
      debugPrint('[stopWeb] download failed: $e\n$st');
      state = state.copyWith(
        finalizationStage: FinalizationStage.idle,
        finalizationError: 'Failed to read recorded audio.',
      );
      return null;
    }
  }

  String _detectWebFormatFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.mp4') || lower.contains('mp4')) return 'mp4';
    if (lower.endsWith('.ogg') || lower.contains('ogg')) return 'ogg';
    return 'webm';
  }

  Future<void> discardRecording() async {
    if (!state.isRecording) return;

    _elapsedTimer?.cancel();
    _toastTimer?.cancel();

    if (kIsWeb) {
      await _disposeWebRecorder();
    } else {
      final pendingSessionId = _pendingResumeSessionId;
      if (pendingSessionId != null && _segRecorder == null) {
        final paths = _pendingResumeSegmentPaths ?? const <String>[];
        for (final p in paths) {
          await _deleteFileSafe(p);
        }
        await _cleanupOrphanedSegments(pendingSessionId, -1);
        await ref
            .read(recordingSessionRepositoryProvider)
            .markDiscarded(pendingSessionId);
        _pendingResumeSessionId = null;
        _pendingResumeSegmentPaths = null;
        _pendingResumeDuration = null;
        await ref.read(recoveryCoordinatorProvider).refresh();
      } else {
        await _segRecorder?.discard();
        _segRecorder = null;
        await RecordingNotification.instance.clear();
        await _stopLiveActivityIfIOS();
        await _stopForegroundServiceIfAndroid();
      }
    }

    state = const RecordingState();
  }

  Future<void> _showRecordingNotification() async {
    if (kIsWeb) return;
    final l10n = await _resolveLocalizations();
    await RecordingNotification.instance.showActive(
      title: l10n.recording_inProgressNotificationTitle,
      body: l10n.recording_inProgressNotificationBody,
    );
  }

  Future<AppLocalizations> _resolveLocalizations() async {
    final selected = ref.read(localeProvider);
    final locale =
        selected ?? WidgetsBinding.instance.platformDispatcher.locale;
    return AppLocalizations.delegate.load(locale);
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(
        elapsed: state.elapsed + const Duration(seconds: 1),
      );
      unawaited(_updateForegroundNotification());
      unawaited(_updateLiveActivity());
    });
  }

  Future<bool> _startLiveActivityIfIOS(String sessionId) async {
    if (kIsWeb || !Platform.isIOS) return false;
    final supported = await RecordingLiveActivity.instance.isSupported();
    if (!supported) return false;
    final started = await RecordingLiveActivity.instance.start(
      activityId: sessionId,
      genre: state.currentGenreName ?? '',
      subcategory: state.currentSubcategoryName ?? '',
    );
    if (!started) return false;
    _liveActivityActive = true;
    _liveActivityUrlSub?.cancel();
    _liveActivityUrlSub = RecordingLiveActivity.instance.urlSchemeStream.listen(
      (event) {
        final host = event.host;
        final path = event.path;
        if (host == 'stop-recording' || path == '/stop-recording') {
          scheduleMicrotask(_handleBackgroundStop);
        }
      },
    );
    return true;
  }

  Future<void> _stopLiveActivityIfIOS() async {
    if (kIsWeb || !Platform.isIOS) return;
    await _liveActivityUrlSub?.cancel();
    _liveActivityUrlSub = null;
    if (!_liveActivityActive) return;
    await RecordingLiveActivity.instance.stop();
    _liveActivityActive = false;
  }

  Future<void> _updateLiveActivity() async {
    if (kIsWeb || !Platform.isIOS || !_liveActivityActive) return;
    await RecordingLiveActivity.instance.update(
      elapsedLabel: fmt.formatElapsed(state.elapsed),
      isPaused: state.isPaused,
    );
  }

  Future<void> _startForegroundServiceIfAndroid() async {
    if (kIsWeb || !Platform.isAndroid) return;
    final l10n = await _resolveLocalizations();
    _cachedL10n = l10n;
    final service = ref.read(recordingForegroundServiceProvider);
    await service.start(
      content: RecordingForegroundServiceContent(
        title: l10n.recording_serviceNotificationTitle,
        body: _formatNotificationBody(l10n),
        stopActionLabel: l10n.recording_serviceNotificationStopAction,
      ),
      onStopRequested: () => scheduleMicrotask(_handleBackgroundStop),
    );
  }

  Future<void> _stopForegroundServiceIfAndroid() async {
    if (kIsWeb || !Platform.isAndroid) return;
    await ref.read(recordingForegroundServiceProvider).stop();
    _cachedL10n = null;
  }

  Future<void> _updateForegroundNotification() async {
    if (kIsWeb || !Platform.isAndroid) return;
    final l10n = _cachedL10n;
    if (l10n == null) return;
    await ref
        .read(recordingForegroundServiceProvider)
        .update(
          title: l10n.recording_serviceNotificationTitle,
          body: _formatNotificationBody(l10n),
        );
  }

  Future<void> _handleBackgroundStop() async {
    if (!state.isRecording) return;
    final result = await stopRecording();
    if (result != null) {
      state = state.copyWith(autoStoppedResult: result);
    }
  }

  String _formatNotificationBody(AppLocalizations l10n) {
    final elapsed = fmt.formatElapsed(state.elapsed);
    final genre = state.currentGenreName?.trim() ?? '';
    if (genre.isEmpty) return elapsed;
    return l10n.recording_serviceNotificationBody(elapsed, genre);
  }

  Future<void> _disposeWebRecorder() async {
    await _webAmplitudeSub?.cancel();
    _webAmplitudeSub = null;
    await _webAmplitudeController?.close();
    _webAmplitudeController = null;
    await _webRecorder?.dispose();
    _webRecorder = null;
    _webPendingKey = null;
  }

  Future<void> _deleteFileSafe(String path) async {
    try {
      await file_ops.deleteFile(path);
    } catch (_) {}
  }

  String _newSessionId() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    final rand = math.Random.secure().nextInt(0xFFFFFF).toRadixString(16);
    return 'sess_${millis}_$rand';
  }

  void _cleanup() {
    _elapsedTimer?.cancel();
    _toastTimer?.cancel();
    _segRecorder?.dispose();
    _segRecorder = null;
    _disposeWebRecorder();
    unawaited(_stopLiveActivityIfIOS());
    unawaited(_stopForegroundServiceIfAndroid());
  }
}

AmplitudeMapper _amplitudeMapperFor(NoiseSensitivity sensitivity) {
  final threshold = switch (sensitivity) {
    NoiseSensitivity.low => -40.0,
    NoiseSensitivity.medium => -60.0,
    NoiseSensitivity.high => -80.0,
  };
  return (double dB) {
    if (dB <= threshold) return 0.0;
    return ((dB - threshold) / -threshold).clamp(0.0, 1.0);
  };
}
