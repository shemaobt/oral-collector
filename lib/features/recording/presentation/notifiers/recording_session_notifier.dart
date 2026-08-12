import 'dart:async';
import 'dart:io' show File, Platform;
import 'dart:math' as math;

import 'package:audio_session/audio_session.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/observability/error_reporter.dart';
import '../../../../core/platform/file_ops.dart' as file_ops;
import '../../../../core/platform/recording_active_flag.dart';
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
import 'input_device_notifier.dart';
import 'recording_session_state.dart';
import 'single_flight_runner.dart';

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
        reporter: ref.watch(errorReporterProvider),
      );
    });

final recordingForegroundServiceProvider = Provider<RecordingForegroundService>(
  (_) => RecordingForegroundService(),
);

/// Injectable so the browser capture path can be driven in VM tests, where
/// `kIsWeb` is always false.
final isWebPlatformProvider = Provider<bool>((_) => kIsWeb);

/// Injectable web recorder, so a browser that ends capture on its own — the
/// microphone taken by another tab or app, the default device changing — can
/// be reproduced without a browser.
final webAudioRecorderFactoryProvider = Provider<AudioRecorder Function()>(
  (_) => AudioRecorder.new,
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
  static final _log = Logger('RecordingSessionNotifier');

  SegmentedRecorder? _segRecorder;
  AudioRecorder? _webRecorder;
  String? _webPendingKey;
  Timer? _elapsedTimer;
  Timer? _toastTimer;
  StreamController<double>? _webAmplitudeController;
  StreamSubscription<Amplitude>? _webAmplitudeSub;
  StreamSubscription<RecordState>? _webStateSub;
  bool _liveActivityActive = false;
  StreamSubscription<dynamic>? _liveActivityUrlSub;
  AppLocalizations? _cachedL10n;
  String? _pendingResumeSessionId;
  List<String>? _pendingResumeSegmentPaths;
  Duration? _pendingResumeDuration;
  bool _isStopping = false;

  // Coalesce the 1 Hz platform updates so a slow channel call can't stack, and
  // surface their errors instead of dropping the fire-and-forget futures.
  late final ErrorReporter _platformReporter = ref.read(errorReporterProvider);
  late final SingleFlightRunner _fgUpdateRunner = SingleFlightRunner(
    _updateForegroundNotification,
    onError: (e, st) => _platformReporter.reportError(e, st),
  );
  late final SingleFlightRunner _liveActivityRunner = SingleFlightRunner(
    _updateLiveActivity,
    onError: (e, st) => _platformReporter.reportError(e, st),
  );

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
      _log.info('audio session re-activated on resume');
    } on Exception catch (e) {
      _log.warning('re-activate failed', e);
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
      await const RecordingActiveFlag().markInactive();
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

    await const RecordingActiveFlag().markInactive();
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

    if (ref.read(isWebPlatformProvider)) {
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

    await const RecordingActiveFlag().markActive();

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
    final recorder = ref.read(webAudioRecorderFactoryProvider)();
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

    // The elapsed counter is a plain Timer and the waveform is fed by the
    // microphone stream, not by the recorder — both keep looking healthy long
    // after capture has ended. Watching the recorder itself is the only way to
    // tell the person now instead of at stop, when there is nothing left.
    _webStateSub = recorder.onStateChanged().listen((recordState) {
      if (recordState != RecordState.stop) return;
      unawaited(_handleCaptureLost());
    });

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

    await const RecordingActiveFlag().markActive();

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
    // Synchronous reentrancy guard: a user stop and a background stop (FGS
    // action / Live Activity deep-link) can fire near-simultaneously. Set the
    // flag before any await so the second entrant bails regardless of how far
    // the state machine has advanced.
    if (_isStopping || !state.isRecording || state.isFinalizing) return null;
    _isStopping = true;
    try {
      _elapsedTimer?.cancel();
      _toastTimer?.cancel();
      final elapsed = state.elapsed;

      if (ref.read(isWebPlatformProvider)) {
        return await _stopWeb(elapsed);
      }
      return await _stopNative(elapsed);
    } finally {
      _isStopping = false;
    }
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
        await const RecordingActiveFlag().markInactive();
        state = const RecordingState(
          finalizationStage: FinalizationStage.finalizing,
        );
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
          state = const RecordingState();
        }
        return result;
      }

      await const RecordingActiveFlag().markInactive();
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
      _log.severe('[stopNative] recorder.finish failed', e, st);
      sessionResult = await _recoverFromDisk(sessionId);
      if (sessionResult != null) degraded = true;
    }
    _segRecorder = null;

    await const RecordingActiveFlag().markInactive();
    state = state.copyWith(
      isRecording: false,
      isPaused: false,
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
        finalizationErrorKind: FinalizationErrorKind.noSegments,
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

    final result = await _finalizeOrCrash(
      sessionId: sessionResult.sessionId,
      segmentPaths: sessionResult.segmentPaths,
      totalDuration: totalDuration,
    );
    if (result != null) {
      // The file exists as soon as _finalizeOrCrash returns, and until the row
      // points at it nothing does (ENG-420).
      await sessionRepo.completeWithFinalizedAudio(
        sessionResult.sessionId,
        filePath: result.filePath,
        durationSeconds: result.durationSeconds,
      );
      state = const RecordingState();
    }
    return result;
  }

  Future<RecordingResult?> _finalizeOrCrash({
    required String sessionId,
    required List<String> segmentPaths,
    required Duration totalDuration,
  }) async {
    final sessionRepo = ref.read(recordingSessionRepositoryProvider);
    final finalizer = ref.read(recordingFinalizationServiceProvider);

    FinalizationOutcome? outcome;
    Object? error;
    try {
      outcome = await finalizer.finalize(
        sessionId: sessionId,
        segmentPaths: segmentPaths,
        totalDuration: totalDuration,
        onStage: (stage) {
          state = state.copyWith(finalizationStage: stage);
        },
      );
    } catch (e, st) {
      error = e;
      _log.severe('finalize failed for $sessionId', e, st);
    }

    if (outcome != null) {
      if (outcome.degraded) {
        state = state.copyWith(finalizationDegraded: true);
      }
      return outcome.result;
    }

    await sessionRepo.markCrashed(sessionId);
    await ref.read(recoveryCoordinatorProvider).refresh();
    final recoverable = ref
        .read(interruptedSessionsProvider)
        .any((s) => s.sessionId == sessionId);
    // outcome == null with non-empty segmentPaths only happens when the
    // service threw (every other branch returns a FinalizationOutcome).
    // Empty segments are filtered before reaching this method, so an error
    // here means the pipeline crashed — surface the more precise kind.
    final errorKind = error != null
        ? FinalizationErrorKind.finalizationFailed
        : FinalizationErrorKind.noSegments;
    state = state.copyWith(
      finalizationStage: FinalizationStage.idle,
      finalizationErrorKind: errorKind,
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
      _log.severe('[stopNative] recoverFromDisk failed', e, st);
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
      await const RecordingActiveFlag().markInactive();
      state = const RecordingState();
      return null;
    }

    state = state.copyWith(finalizationStage: FinalizationStage.finalizing);

    String? url;
    try {
      url = await recorder.stop();
    } catch (e, st) {
      _log.severe('[stopWeb] recorder.stop failed', e, st);
      url = null;
    }
    await _disposeWebRecorder();

    await const RecordingActiveFlag().markInactive();
    state = state.copyWith(
      isRecording: false,
      isPaused: false,
      clearAmplitudeStream: true,
      clearSessionId: true,
      clearLastCheckpoint: true,
    );

    if (url == null || url.isEmpty) {
      state = state.copyWith(
        finalizationStage: FinalizationStage.idle,
        finalizationErrorKind: FinalizationErrorKind.noAudio,
      );
      return null;
    }

    try {
      final bytes = await http.readBytes(Uri.parse(url));
      // Web records with a fixed Opus encoder (see _startWeb); record_web
      // packages Opus into a WebM container, so the format is always 'webm'.
      const format = 'webm';
      final fullKey = '$pendingKey.$format';
      await file_ops.writeFileBytes(fullKey, bytes);
      state = const RecordingState();
      return RecordingResult(
        filePath: fullKey,
        durationSeconds: fallbackElapsed.inMilliseconds / 1000.0,
        format: format,
      );
    } catch (e, st) {
      _log.severe('[stopWeb] download failed', e, st);
      state = state.copyWith(
        finalizationStage: FinalizationStage.idle,
        finalizationErrorKind: FinalizationErrorKind.downloadFailed,
      );
      return null;
    }
  }

  Future<void> discardRecording() async {
    if (!state.isInProgress) return;

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

    await const RecordingActiveFlag().markInactive();
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
      _fgUpdateRunner.run();
      _liveActivityRunner.run();
    });
  }

  Future<bool> _startLiveActivityIfIOS(String sessionId) async {
    if (kIsWeb || !Platform.isIOS) return false;
    final supported = await RecordingLiveActivity.instance.isSupported();
    if (!supported) return false;
    final l10n = await _resolveLocalizations();
    final started = await RecordingLiveActivity.instance.start(
      activityId: sessionId,
      genre: state.currentGenreName ?? '',
      subcategory: state.currentSubcategoryName ?? '',
      localizedRecordingStatus: l10n.liveActivity_recordingStatus,
      localizedRecordingPausedStatus: l10n.liveActivity_recordingPausedStatus,
      localizedStopAction: l10n.recording_serviceNotificationStopAction,
    );
    if (!started) return false;
    _liveActivityActive = true;
    unawaited(_liveActivityUrlSub?.cancel());
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

  /// Capture ended without anyone asking. Whatever the browser had is gone by
  /// the time this fires, so the only thing left worth doing is saying so
  /// immediately rather than letting the counter run to eighteen minutes.
  Future<void> _handleCaptureLost() async {
    if (_isStopping || !state.isRecording) return;

    _elapsedTimer?.cancel();
    _toastTimer?.cancel();
    state = state.copyWith(
      isRecording: false,
      isPaused: false,
      clearAmplitudeStream: true,
      clearSessionId: true,
      finalizationStage: FinalizationStage.idle,
      finalizationErrorKind: FinalizationErrorKind.captureInterrupted,
    );

    await _disposeWebRecorder();
    await const RecordingActiveFlag().markInactive();
  }

  Future<void> _disposeWebRecorder() async {
    await _webStateSub?.cancel();
    _webStateSub = null;
    await _webAmplitudeSub?.cancel();
    _webAmplitudeSub = null;
    await _webAmplitudeController?.close();
    _webAmplitudeController = null;
    await _webRecorder?.dispose();
    _webRecorder = null;
    _webPendingKey = null;
  }

  Future<void> _deleteFileSafe(String path) async {
    // Best-effort delete stays non-throwing, but surface a genuine failure
    // (file_ops.deleteFile no-ops on a missing file) instead of swallowing it —
    // mirrors RecordingFinalizationService._deleteFileSafe.
    try {
      await file_ops.deleteFile(path);
    } catch (e, st) {
      _platformReporter.reportError(e, st);
    }
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
    unawaited(_disposeWebRecorder());
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
