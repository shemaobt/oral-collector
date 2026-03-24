import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/platform/file_ops.dart' as file_ops;
import '../../../recording/data/providers.dart';
import '../../../recording/data/repositories/local_recording_repository.dart';
import '../../data/providers.dart';
import '../../domain/repositories/connectivity_service.dart';
import '../../domain/repositories/sync_engine.dart';
import 'sync_state.dart';

final syncNotifierProvider = NotifierProvider<SyncNotifier, SyncState>(
  SyncNotifier.new,
);

class SyncNotifier extends Notifier<SyncState> {
  StreamSubscription<bool>? _connectivitySub;
  DateTime? _speedSampleTime;
  int _speedSampleBytes = 0;
  final Map<String, int> _fileProgress = {};

  ConnectivityService get _connectivity =>
      ref.read(connectivityServiceProvider);
  SyncEngine get _syncEngine => ref.read(syncEngineProvider);
  LocalRecordingRepository get _recordingRepo =>
      ref.read(localRecordingRepositoryProvider);

  @override
  SyncState build() {
    ref.onDispose(_cleanup);
    _initConnectivity();
    return const SyncState();
  }

  Future<void> _initConnectivity() async {
    final online = await _connectivity.isOnline;
    state = state.copyWith(isOnline: online);

    _connectivitySub = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    await _refreshPendingCount();
  }

  void _onConnectivityChanged(bool online) {
    final wasOffline = !state.isOnline;
    state = state.copyWith(isOnline: online);

    if (online && wasOffline) {
      processQueue();
    }
  }

  Future<void> syncAll() async {
    await processQueue();
  }

  Future<void> syncOne(String recordingId) async {
    state = state.copyWith(uploadingId: recordingId, syncProgress: 0);
    _fileProgress.clear();

    try {
      final recording = await _recordingRepo.getRecordingById(recordingId);
      if (recording == null) return;

      state = state.copyWith(
        currentFileName: recording.title,
        totalQueueSizeBytes: recording.fileSizeBytes,
        totalUploadedBytes: 0,
        uploadSpeedBps: 0,
      );

      _speedSampleTime = DateTime.now();
      _speedSampleBytes = 0;

      await _syncEngine.uploadSingle(
        recordingId,
        deleteAfterUpload: state.autoRemoveAfterUpload,
        onProgress: _onUploadProgress,
      );

      state = state.copyWith(
        syncProgress: 100,
        clearUploadingId: true,
        clearCurrentFileName: true,
        lastSyncAt: DateTime.now(),
      );
    } on Exception {
      state = state.copyWith(
        clearUploadingId: true,
        clearCurrentFileName: true,
        syncProgress: 0,
      );
    }

    await _refreshPendingCount();
  }

  Future<void> retryFailed() async {
    await processQueue();
  }

  Future<void> resetAndRetry(String recordingId) async {
    await _recordingRepo.resetRetryCount(recordingId);
    await _refreshPendingCount();
    await syncOne(recordingId);
  }

  void updateSettings(SyncSettings settings) {
    state = state.copyWith(
      autoUploadWifiOnly: settings.autoUploadWifiOnly,
      autoRemoveAfterUpload: settings.autoRemoveAfterUpload,
    );
  }

  Future<int> getLocalStorageUsed() async {
    if (kIsWeb) return 0;

    final all = await _recordingRepo.getAllLocalRecordings();
    var totalBytes = 0;

    for (final recording in all) {
      try {
        if (await file_ops.fileExists(recording.localFilePath)) {
          totalBytes += await file_ops.fileLength(recording.localFilePath);
        }
      } on Exception catch (_) {}
    }

    return totalBytes;
  }

  Future<void> clearLocalCache() async {
    if (kIsWeb) return;

    final all = await _recordingRepo.getAllLocalRecordings();

    for (final recording in all) {
      try {
        await file_ops.deleteFile(recording.localFilePath);
      } on Exception catch (_) {}
    }

    await _recordingRepo.deleteAllRecordings();
    await _refreshPendingCount();
  }

  Future<void> processQueue() async {
    if (!state.isOnline) return;

    await _refreshPendingCount();
    if (state.pendingCount == 0) return;

    final pending = await _recordingRepo.getPendingUploads();
    final totalBytes = pending.fold(0, (sum, r) => sum + r.fileSizeBytes);

    _fileProgress.clear();

    if (pending.isNotEmpty) {
      state = state.copyWith(
        uploadingId: pending.first.id,
        currentFileName: pending.first.title,
        syncProgress: 0,
        totalQueueSizeBytes: totalBytes,
        totalUploadedBytes: 0,
        uploadSpeedBps: 0,
      );
    }

    _speedSampleTime = DateTime.now();
    _speedSampleBytes = 0;

    final isWifi = await _connectivity.isOnWifi;
    final concurrency = isWifi ? 3 : 1;

    await _syncEngine.processQueue(
      deleteAfterUpload: state.autoRemoveAfterUpload,
      wifiOnly: state.autoUploadWifiOnly,
      maxConcurrency: concurrency,
      onProgress: _onUploadProgress,
    );

    await _refreshPendingCount();

    state = state.copyWith(
      clearUploadingId: true,
      clearCurrentFileName: true,
      syncProgress: 100,
      lastSyncAt: DateTime.now(),
      totalUploadedBytes: totalBytes,
      uploadSpeedBps: 0,
    );
  }

  void _onUploadProgress(String recordingId, int bytesSent, int totalBytes) {
    if (totalBytes <= 0) return;

    _fileProgress[recordingId] = bytesSent;
    final totalSent = _fileProgress.values.fold(0, (a, b) => a + b);

    final now = DateTime.now();
    final elapsed = now.difference(_speedSampleTime ?? now);

    if (elapsed.inSeconds >= 2) {
      final bytesDelta = totalSent - _speedSampleBytes;
      final speed = bytesDelta / elapsed.inMilliseconds * 1000;
      state = state.copyWith(uploadSpeedBps: speed > 0 ? speed : 0);
      _speedSampleTime = now;
      _speedSampleBytes = totalSent;
    }

    state = state.copyWith(
      uploadingId: recordingId,
      syncProgress: state.totalQueueSizeBytes > 0
          ? (totalSent * 100 ~/ state.totalQueueSizeBytes)
          : 0,
      totalUploadedBytes: totalSent,
    );
  }

  Future<void> _refreshPendingCount() async {
    final pending = await _recordingRepo.getPendingUploads();
    final totalBytes = pending.fold(0, (sum, r) => sum + r.fileSizeBytes);
    state = state.copyWith(
      pendingCount: pending.length,
      totalQueueSizeBytes: totalBytes,
    );
  }

  void _cleanup() {
    _connectivitySub?.cancel();
  }
}
