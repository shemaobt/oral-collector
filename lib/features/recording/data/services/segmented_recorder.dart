import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/platform/file_ops.dart' as file_ops;
import '../repositories/recording_session_repository.dart';
import 'segment_paths.dart';
import 'storage_guard.dart';
import 'wav_segment_sink.dart';

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
typedef AudioRecorderFactory = AudioRecorder Function();
typedef DocDirProvider = Future<String> Function();

class SegmentedRecorder {
  SegmentedRecorder({
    required RecordingSessionRepository sessionRepo,
    required StorageGuard storageGuard,
    this.segmentDuration = const Duration(seconds: 60),
    @visibleForTesting AudioRecorderFactory? recorderFactory,
    @visibleForTesting DocDirProvider? docDirProvider,
    @visibleForTesting bool configureAudioSession = true,
  }) : _sessionRepo = sessionRepo,
       _storageGuard = storageGuard,
       _recorderFactory = recorderFactory ?? AudioRecorder.new,
       _docDirProvider =
           docDirProvider ??
           (() async => (await getApplicationDocumentsDirectory()).path),
       _configureAudioSession = configureAudioSession;

  final RecordingSessionRepository _sessionRepo;
  final StorageGuard _storageGuard;
  final Duration segmentDuration;
  final AudioRecorderFactory _recorderFactory;
  final DocDirProvider _docDirProvider;
  final bool _configureAudioSession;

  static const int _sampleRate = 16000;
  static const int _numChannels = 1;
  static const int _bytesPerSample = 2;

  void Function(Duration totalSaved)? onCheckpoint;
  void Function(int estimatedSecondsRemaining)? onStorageCritical;
  void Function()? onStorageForceStop;
  void Function(Duration rotationLatency)? onSlowRotation;

  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _pcmSub;
  WavSegmentSink? _currentSink;
  String? _currentSegmentPath;
  String? _docDirPath;
  String? _sessionId;
  int _segIdx = -1;
  final List<String> _paths = <String>[];
  Duration _cumulativeFinalized = Duration.zero;
  int _bytesInCurrentSegment = 0;
  int _bytesPerSegment = 0;
  bool _isPaused = false;
  Future<void> _finalizeChain = Future<void>.value();
  InputDevice? _inputDevice;
  AmplitudeMapper? _amplitudeMapper;

  StreamController<double>? _amplitudeController;
  StreamSubscription<Amplitude>? _amplitudeSub;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;

  bool get isActive => _sessionId != null;
  Stream<double>? get amplitudeStream => _amplitudeController?.stream;
  Duration get totalSaved => _cumulativeFinalized;
  List<String> get segmentPaths => List.unmodifiable(_paths);
  String? get sessionId => _sessionId;

  Future<bool> startSession({
    required String sessionId,
    required AmplitudeMapper amplitudeMapper,
    InputDevice? inputDevice,
    List<String> resumeFromPaths = const [],
    Duration resumeFromDuration = Duration.zero,
  }) async {
    if (isActive) return false;

    _sessionId = sessionId;
    _paths
      ..clear()
      ..addAll(resumeFromPaths);
    _segIdx = resumeFromPaths.length - 1;
    _cumulativeFinalized = resumeFromDuration;
    _amplitudeMapper = amplitudeMapper;
    _inputDevice = inputDevice;
    _isPaused = false;
    _bytesInCurrentSegment = 0;
    _finalizeChain = Future<void>.value();

    _recorder = _recorderFactory();
    final hasPermission = await _recorder!.hasPermission();
    if (!hasPermission) {
      await _recorder!.dispose();
      _recorder = null;
      _sessionId = null;
      return false;
    }

    if (_configureAudioSession && !kIsWeb) {
      await _setupAudioSession();
    }

    _docDirPath = await _docDirProvider();
    _bytesPerSegment =
        _sampleRate *
        _numChannels *
        _bytesPerSample *
        segmentDuration.inSeconds;

    _amplitudeController = StreamController<double>.broadcast();

    _openNextSink();
    _subscribeToAmplitude();

    final stream = await _recorder!.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: _numChannels,
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
    );
    _pcmSub = stream.listen(
      _onPcmChunk,
      onError: (Object e) {
        debugPrint('SegmentedRecorder: PCM stream error: $e');
      },
    );

    debugPrint(
      'SegmentedRecorder: streaming started '
      '(bytesPerSegment=$_bytesPerSegment device=${_inputDevice?.id ?? "default"})',
    );

    return true;
  }

  Future<void> _setupAudioSession() async {
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
        'SegmentedRecorder: AudioSession configured (activated=$activated)',
      );
      await _interruptionSub?.cancel();
      _interruptionSub = audioSession.interruptionEventStream.listen((
        event,
      ) async {
        if (event.begin) {
          debugPrint(
            'SegmentedRecorder: audio session interruption began '
            '(type=${event.type})',
          );
          return;
        }
        debugPrint(
          'SegmentedRecorder: audio session interruption ended '
          '(type=${event.type}); re-activating',
        );
        try {
          await audioSession.setActive(true);
        } on Exception catch (e) {
          debugPrint(
            'SegmentedRecorder: re-activate after interruption failed: $e',
          );
        }
      });
    } on Exception catch (e) {
      debugPrint('SegmentedRecorder: AudioSession setup failed: $e');
    }
  }

  void _onPcmChunk(Uint8List chunk) {
    if (_isPaused || _currentSink == null) return;
    _currentSink!.appendBytes(chunk);
    _bytesInCurrentSegment += chunk.length;
    if (_bytesInCurrentSegment >= _bytesPerSegment) {
      _rotateSync();
    }
  }

  void _rotateSync() {
    final closing = _currentSink!;
    final closingPath = _currentSegmentPath!;
    final closingDuration = closing.currentDuration;
    _openNextSink();
    _finalizeChain = _finalizeChain.then(
      (_) => _finalizeClosedSegment(closing, closingPath, closingDuration),
    );
  }

  void _openNextSink() {
    _segIdx++;
    final path = SegmentPaths.forSegment(_docDirPath!, _sessionId!, _segIdx);
    _currentSink = WavSegmentSink.open(path, _sampleRate, _numChannels);
    _currentSegmentPath = path;
    _bytesInCurrentSegment = 0;
  }

  Future<void> _finalizeClosedSegment(
    WavSegmentSink closing,
    String closingPath,
    Duration closingDuration,
  ) async {
    final rotateStart = DateTime.now();
    try {
      await closing.close();
    } catch (e, st) {
      debugPrint('SegmentedRecorder: sink close failed: $e\n$st');
    }

    _paths.add(closingPath);
    _cumulativeFinalized += closingDuration;

    final sid = _sessionId;
    if (sid != null) {
      try {
        await _sessionRepo.appendSegment(
          sid,
          closingPath,
          closingDuration.inMilliseconds / 1000.0,
        );
      } catch (e, st) {
        debugPrint('SegmentedRecorder: appendSegment failed: $e\n$st');
      }
    }

    onCheckpoint?.call(_cumulativeFinalized);

    try {
      final storage = await _storageGuard.checkDuring();
      if (storage.severity == DuringSeverity.forceStop) {
        onStorageForceStop?.call();
      } else if (storage.severity == DuringSeverity.critical) {
        onStorageCritical?.call(storage.estimatedSeconds);
      }
    } catch (e, st) {
      debugPrint('SegmentedRecorder: storage check failed: $e\n$st');
    }

    final latency = DateTime.now().difference(rotateStart);
    if (latency > const Duration(milliseconds: 500)) {
      onSlowRotation?.call(latency);
    }
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
            final mapped = _isPaused
                ? 0.0
                : (_amplitudeMapper?.call(amp.current) ?? 0.0);
            _amplitudeController!.add(mapped);
          },
          onError: (Object e) {
            debugPrint('SegmentedRecorder: amplitude stream error: $e');
          },
        );
  }

  Future<void> pause() async {
    if (!isActive || _isPaused) return;
    // Pause is gated in Dart, not in the plugin. record_android's pause()
    // parks the read loop but keeps AudioRecord live, so frames buffered
    // during the pause replay as fast-forward on resume.
    _isPaused = true;
    if (_sessionId != null) {
      await _sessionRepo.setPaused(_sessionId!, true);
    }
  }

  Future<void> resume() async {
    if (!isActive || !_isPaused) return;
    _isPaused = false;
    if (_sessionId != null) {
      await _sessionRepo.setPaused(_sessionId!, false);
    }
  }

  Future<SegmentedRecordingResult?> finish() async {
    if (!isActive) return null;
    final sessionId = _sessionId!;

    await _pcmSub?.cancel();
    _pcmSub = null;
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    await _interruptionSub?.cancel();
    _interruptionSub = null;

    try {
      await _recorder?.stop();
    } catch (e) {
      debugPrint('SegmentedRecorder: recorder.stop on finish failed: $e');
    }

    final closing = _currentSink;
    final closingPath = _currentSegmentPath;
    if (closing != null && closingPath != null) {
      if (closing.dataBytes > 0) {
        final closingDuration = closing.currentDuration;
        _finalizeChain = _finalizeChain.then(
          (_) => _finalizeClosedSegment(closing, closingPath, closingDuration),
        );
      } else {
        try {
          await closing.closeWithoutPatch();
        } catch (_) {}
        try {
          await File(closingPath).delete();
        } catch (_) {}
      }
    }

    await _finalizeChain;

    await _amplitudeController?.close();
    _amplitudeController = null;
    await _recorder?.dispose();
    _recorder = null;
    _currentSink = null;
    _currentSegmentPath = null;

    final result = SegmentedRecordingResult(
      sessionId: sessionId,
      segmentPaths: List<String>.of(_paths),
      totalDuration: _cumulativeFinalized,
    );

    _sessionId = null;
    _paths.clear();
    _segIdx = -1;
    _cumulativeFinalized = Duration.zero;
    _bytesInCurrentSegment = 0;

    return result;
  }

  Future<void> discard() async {
    if (!isActive) return;
    final sessionId = _sessionId!;

    await _pcmSub?.cancel();
    _pcmSub = null;
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    await _interruptionSub?.cancel();
    _interruptionSub = null;

    try {
      await _recorder?.stop();
    } catch (_) {}

    await _finalizeChain;

    final closing = _currentSink;
    final closingPath = _currentSegmentPath;
    if (closing != null) {
      try {
        await closing.closeWithoutPatch();
      } catch (_) {}
    }
    if (closingPath != null) {
      try {
        await file_ops.deleteFile(closingPath);
      } catch (_) {}
    }

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
    _currentSink = null;
    _currentSegmentPath = null;

    _sessionId = null;
    _paths.clear();
    _segIdx = -1;
    _cumulativeFinalized = Duration.zero;
    _bytesInCurrentSegment = 0;
  }

  Future<void> dispose() async {
    await _pcmSub?.cancel();
    await _amplitudeSub?.cancel();
    await _interruptionSub?.cancel();
    _interruptionSub = null;
    final closing = _currentSink;
    if (closing != null) {
      try {
        await closing.closeWithoutPatch();
      } catch (_) {}
    }
    await _amplitudeController?.close();
    await _recorder?.dispose();
    _recorder = null;
    _amplitudeController = null;
    _currentSink = null;
    _currentSegmentPath = null;
  }
}
