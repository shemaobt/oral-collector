import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/platform/file_ops.dart' as file_ops;
import '../repositories/recording_session_repository.dart';
import 'storage_guard.dart';

class SegmentedRecordingResult {
  const SegmentedRecordingResult({
    required this.sessionId,
    required this.segmentPaths,
    required this.totalDuration,
  });

  final String sessionId;
  final List<String> segmentPaths;
  final Duration totalDuration;
}

typedef AmplitudeMapper = double Function(double dB);

class SegmentedRecorder {
  SegmentedRecorder({
    required RecordingSessionRepository sessionRepo,
    required StorageGuard storageGuard,
    this.segmentDuration = const Duration(seconds: 60),
  }) : _sessionRepo = sessionRepo,
       _storageGuard = storageGuard;

  final RecordingSessionRepository _sessionRepo;
  final StorageGuard _storageGuard;
  final Duration segmentDuration;

  void Function(Duration totalSaved)? onCheckpoint;
  void Function(int estimatedSecondsRemaining)? onStorageCritical;
  void Function()? onStorageForceStop;
  void Function(Duration rotationLatency)? onSlowRotation;

  AudioRecorder? _recorder;
  String? _sessionId;
  int _segIdx = -1;
  final List<String> _paths = <String>[];
  Duration _cumulativeFinalized = Duration.zero;
  DateTime? _currentSegmentStartedAt;
  Timer? _rotateTimer;
  InputDevice? _inputDevice;
  AmplitudeMapper? _amplitudeMapper;

  StreamController<double>? _amplitudeController;
  StreamSubscription<Amplitude>? _amplitudeSub;

  bool get isActive => _sessionId != null;
  Stream<double>? get amplitudeStream => _amplitudeController?.stream;
  Duration get totalSaved => _cumulativeFinalized;
  List<String> get segmentPaths => List.unmodifiable(_paths);
  String? get sessionId => _sessionId;

  Future<bool> startSession({
    required String sessionId,
    required AmplitudeMapper amplitudeMapper,
    InputDevice? inputDevice,
  }) async {
    if (isActive) return false;

    _sessionId = sessionId;
    _paths.clear();
    _segIdx = -1;
    _cumulativeFinalized = Duration.zero;
    _amplitudeMapper = amplitudeMapper;
    _inputDevice = inputDevice;

    _recorder = AudioRecorder();
    final hasPermission = await _recorder!.hasPermission();
    if (!hasPermission) {
      await _recorder!.dispose();
      _recorder = null;
      _sessionId = null;
      return false;
    }

    if (!kIsWeb) {
      try {
        final audioSession = await AudioSession.instance;
        await audioSession.configure(
          AudioSessionConfiguration(
            avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
            avAudioSessionCategoryOptions:
                AVAudioSessionCategoryOptions.defaultToSpeaker |
                AVAudioSessionCategoryOptions.allowBluetooth |
                AVAudioSessionCategoryOptions.allowBluetoothA2dp,
            avAudioSessionMode: AVAudioSessionMode.defaultMode,
            avAudioSessionRouteSharingPolicy:
                AVAudioSessionRouteSharingPolicy.defaultPolicy,
            avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
          ),
        );
        final activated = await audioSession.setActive(true);
        debugPrint(
          'SegmentedRecorder: AudioSession configured '
          '(activated=$activated)',
        );
      } on Exception catch (e) {
        debugPrint('SegmentedRecorder: AudioSession setup failed: $e');
      }
    }

    _amplitudeController = StreamController<double>.broadcast();

    await _startNextSegment();
    _armRotateTimer();
    return true;
  }

  Future<void> _startNextSegment() async {
    _segIdx++;
    final dir = await getApplicationDocumentsDirectory();
    final idxStr = _segIdx.toString().padLeft(3, '0');
    final path = '${dir.path}/rec_${_sessionId}_$idxStr.wav';

    try {
      await _recorder!.start(
        RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 128000,
          device: _inputDevice,
          iosConfig: const IosRecordConfig(
            // ignore: deprecated_member_use
            manageAudioSession: false,
            categoryOptions: [
              IosAudioCategoryOption.defaultToSpeaker,
              IosAudioCategoryOption.allowBluetooth,
              IosAudioCategoryOption.allowBluetoothA2DP,
            ],
          ),
        ),
        path: path,
      );
      debugPrint(
        'SegmentedRecorder: started segment $idxStr at $path '
        '(device=${_inputDevice?.id ?? "default"})',
      );
    } catch (e, st) {
      debugPrint(
        'SegmentedRecorder: start FAILED for segment $idxStr: $e\n$st',
      );
      rethrow;
    }

    _currentSegmentStartedAt = DateTime.now();
    _subscribeToAmplitude();
  }

  void _subscribeToAmplitude() {
    _amplitudeSub?.cancel();
    final recorder = _recorder;
    if (recorder == null) return;
    var tick = 0;
    _amplitudeSub = recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen(
          (amp) {
            if (_amplitudeController == null ||
                _amplitudeController!.isClosed) {
              return;
            }
            if (tick % 10 == 0) {
              debugPrint(
                'SegmentedRecorder: amplitude current=${amp.current} '
                'max=${amp.max}',
              );
            }
            tick++;
            final mapped = _amplitudeMapper?.call(amp.current) ?? 0.0;
            _amplitudeController!.add(mapped);
          },
          onError: (Object e) {
            debugPrint('SegmentedRecorder: amplitude stream error: $e');
          },
        );
  }

  void _armRotateTimer() {
    _rotateTimer?.cancel();
    _rotateTimer = Timer.periodic(segmentDuration, (_) => _rotateSegment());
  }

  Future<void> _rotateSegment() async {
    if (_recorder == null || _sessionId == null) return;

    final rotateStart = DateTime.now();

    await _amplitudeSub?.cancel();
    _amplitudeSub = null;

    final closedPath = await _recorder!.stop();
    final segStartedAt = _currentSegmentStartedAt ?? rotateStart;
    final segDuration = rotateStart.difference(segStartedAt);

    if (closedPath != null && closedPath.isNotEmpty) {
      _paths.add(closedPath);
      _cumulativeFinalized += segDuration;
      await _sessionRepo.appendSegment(
        _sessionId!,
        closedPath,
        segDuration.inMilliseconds / 1000.0,
      );
    }

    onCheckpoint?.call(_cumulativeFinalized);

    final storage = await _storageGuard.checkDuring();
    if (storage.severity == DuringSeverity.forceStop) {
      onStorageForceStop?.call();
      _rotateTimer?.cancel();
      return;
    }
    if (storage.severity == DuringSeverity.critical) {
      onStorageCritical?.call(storage.estimatedSeconds);
    }

    await _startNextSegment();

    final rotationLatency = DateTime.now().difference(rotateStart);
    if (rotationLatency > const Duration(milliseconds: 500)) {
      onSlowRotation?.call(rotationLatency);
    }
  }

  Future<void> pause() async {
    if (!isActive) return;
    _rotateTimer?.cancel();
    _rotateTimer = null;
    await _recorder?.pause();
    if (_sessionId != null) {
      await _sessionRepo.setPaused(_sessionId!, true);
    }
  }

  Future<void> resume() async {
    if (!isActive) return;
    await _recorder?.resume();
    if (_sessionId != null) {
      await _sessionRepo.setPaused(_sessionId!, false);
    }

    final startedAt = _currentSegmentStartedAt;
    if (startedAt != null &&
        DateTime.now().difference(startedAt) >= segmentDuration) {
      await _rotateSegment();
    } else {
      _armRotateTimer();
    }
  }

  Future<SegmentedRecordingResult?> finish() async {
    if (!isActive) return null;
    final sessionId = _sessionId!;

    _rotateTimer?.cancel();
    _rotateTimer = null;
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;

    final closedPath = await _recorder?.stop();
    final segStartedAt = _currentSegmentStartedAt;
    if (segStartedAt != null && closedPath != null && closedPath.isNotEmpty) {
      final segDuration = DateTime.now().difference(segStartedAt);
      final segFile = File(closedPath);
      final fileSize = await segFile.exists() ? await segFile.length() : -1;
      debugPrint(
        'SegmentedRecorder: finished segment at $closedPath '
        'duration=${segDuration.inMilliseconds}ms size=${fileSize}bytes',
      );
      _paths.add(closedPath);
      _cumulativeFinalized += segDuration;
      await _sessionRepo.appendSegment(
        sessionId,
        closedPath,
        segDuration.inMilliseconds / 1000.0,
      );
    } else {
      debugPrint(
        'SegmentedRecorder: finish called but no closedPath (path=$closedPath)',
      );
    }

    await _sessionRepo.markCompleted(sessionId);

    await _amplitudeController?.close();
    _amplitudeController = null;
    await _recorder?.dispose();
    _recorder = null;

    final result = SegmentedRecordingResult(
      sessionId: sessionId,
      segmentPaths: List<String>.of(_paths),
      totalDuration: _cumulativeFinalized,
    );

    _sessionId = null;
    _paths.clear();
    _segIdx = -1;
    _cumulativeFinalized = Duration.zero;
    _currentSegmentStartedAt = null;

    return result;
  }

  Future<void> discard() async {
    if (!isActive) return;
    final sessionId = _sessionId!;

    _rotateTimer?.cancel();
    _rotateTimer = null;
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;

    try {
      await _recorder?.stop();
    } catch (_) {}

    for (final path in _paths) {
      try {
        await file_ops.deleteFile(path);
      } catch (_) {}
    }

    await _sessionRepo.markDiscarded(sessionId);

    await _amplitudeController?.close();
    _amplitudeController = null;
    await _recorder?.dispose();
    _recorder = null;

    _sessionId = null;
    _paths.clear();
    _segIdx = -1;
    _cumulativeFinalized = Duration.zero;
    _currentSegmentStartedAt = null;
  }

  Future<void> dispose() async {
    _rotateTimer?.cancel();
    await _amplitudeSub?.cancel();
    await _amplitudeController?.close();
    await _recorder?.dispose();
    _recorder = null;
    _amplitudeController = null;
  }
}
