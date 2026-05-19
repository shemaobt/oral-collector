import 'dart:async';
import 'dart:math' as math;

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
import '../../../project/presentation/notifiers/project_notifier.dart';
import '../../data/providers.dart';
import '../../data/services/recording_concat_service.dart';
import '../../data/services/recording_notification.dart';
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

final recordingSessionNotifierProvider =
    NotifierProvider<RecordingSessionNotifier, RecordingState>(
      RecordingSessionNotifier.new,
    );

class RecordingSessionNotifier extends Notifier<RecordingState> {
  SegmentedRecorder? _segRecorder;
  AudioRecorder? _webRecorder;
  String? _webPendingKey;
  Timer? _elapsedTimer;
  Timer? _toastTimer;
  StreamController<double>? _webAmplitudeController;
  StreamSubscription<Amplitude>? _webAmplitudeSub;

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

  Future<bool> startRecording(
    String genreId,
    String subcategoryId, {
    String? projectId,
  }) async {
    if (state.isRecording) return true;

    final mapper = _amplitudeMapperFor(ref.read(noiseSensitivityProvider));

    if (kIsWeb) {
      return _startWeb(genreId, subcategoryId, mapper);
    }

    final resolvedProjectId =
        projectId ?? ref.read(projectNotifierProvider).activeProject?.id ?? '';
    return _startNative(genreId, subcategoryId, resolvedProjectId, mapper);
  }

  Future<bool> _startNative(
    String genreId,
    String subcategoryId,
    String projectId,
    AmplitudeMapper mapper,
  ) async {
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
      amplitudeStream: recorder.amplitudeStream,
      sessionId: sessionId,
    );

    _startElapsedTimer();
    await _showRecordingNotification();
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

    if (kIsWeb) {
      await _webRecorder?.resume();
    } else {
      await _segRecorder?.resume();
    }
    _startElapsedTimer();
    state = state.copyWith(isPaused: false);
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
    if (recorder == null) {
      state = const RecordingState();
      await RecordingNotification.instance.clear();
      return null;
    }

    state = state.copyWith(finalizationStage: FinalizationStage.finalizing);

    SegmentedRecordingResult? sessionResult;
    var degraded = false;
    try {
      sessionResult = await recorder.finish();
    } catch (e, st) {
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

    if (sessionResult == null || sessionResult.segmentPaths.isEmpty) {
      state = state.copyWith(
        finalizationStage: FinalizationStage.idle,
        finalizationError: 'No audio segments were saved.',
      );
      return null;
    }

    final totalDuration = sessionResult.totalDuration > Duration.zero
        ? sessionResult.totalDuration
        : fallbackElapsed;

    final dir = await getApplicationDocumentsDirectory();
    String? sourcePath;

    if (sessionResult.segmentPaths.length == 1) {
      sourcePath = sessionResult.segmentPaths.first;
    } else {
      state = state.copyWith(
        finalizationStage: FinalizationStage.combiningSegments,
      );
      final concat = ref.read(recordingConcatServiceProvider);
      final firstIsWav = sessionResult.segmentPaths.first
          .toLowerCase()
          .endsWith('.wav');
      final concatExt = firstIsWav ? 'wav' : 'm4a';
      final concatPath =
          '${dir.path}/concat_${sessionResult.sessionId}.$concatExt';

      String? concatResult;
      try {
        concatResult = await concat.concatSegments(
          segmentPaths: sessionResult.segmentPaths,
          outputPath: concatPath,
        );
      } catch (e, st) {
        debugPrint('[stopNative] concatSegments failed: $e\n$st');
        concatResult = null;
      }

      if (concatResult == null && firstIsWav) {
        try {
          final ok = await concatWavFilesInDart(
            segments: sessionResult.segmentPaths,
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
        for (final p in sessionResult.segmentPaths) {
          unawaited(_deleteFileSafe(p));
        }
      } else {
        sourcePath = sessionResult.segmentPaths.first;
        state = state.copyWith(finalizationDegraded: true);
      }
    }

    final isWav = sourcePath.toLowerCase().endsWith('.wav');
    if (isWav) {
      state = state.copyWith(
        finalizationStage: FinalizationStage.compressingAudio,
      );
      final m4aPath = '${dir.path}/recording_${sessionResult.sessionId}.m4a';
      var ok = false;
      try {
        ok = await ffmpeg_ops.compressToM4a(sourcePath, m4aPath);
      } catch (e, st) {
        debugPrint('[stopNative] compressToM4a failed: $e\n$st');
        ok = false;
      }
      if (ok) {
        unawaited(_deleteFileSafe(sourcePath));
        state = const RecordingState();
        return RecordingResult(
          filePath: m4aPath,
          durationSeconds: totalDuration.inMilliseconds / 1000.0,
        );
      }
      state = state.copyWith(
        finalizationStage: FinalizationStage.idle,
        finalizationDegraded: true,
      );
      return RecordingResult(
        filePath: sourcePath,
        durationSeconds: totalDuration.inMilliseconds / 1000.0,
        format: 'wav',
      );
    }

    state = const RecordingState();
    return RecordingResult(
      filePath: sourcePath,
      durationSeconds: totalDuration.inMilliseconds / 1000.0,
    );
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
      await _segRecorder?.discard();
      _segRecorder = null;
      await RecordingNotification.instance.clear();
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
    });
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
