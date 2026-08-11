import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart' show Locale, WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/observability/error_reporter.dart';
import '../../../../core/platform/disk_space.dart' as disk_space;
import '../../../../core/platform/file_ops.dart' as file_ops;
import '../../../../l10n/app_localizations.dart';
import '../../../recording/data/providers.dart';
import '../../../recording/data/repositories/local_recording_repository.dart';
import '../../../recording/domain/server_deletion_policy.dart';
import '../../data/providers.dart';
import '../../data/services/upload_foreground_service.dart';
import '../../domain/repositories/connectivity_service.dart';
import '../../domain/repositories/sync_engine.dart';
import 'sync_state.dart';

const _kAutoUploadWifiOnlyKey = 'sync_auto_upload_wifi_only';
const _kAutoRemoveAfterUploadKey = 'sync_auto_remove_after_upload';

final syncNotifierProvider = NotifierProvider<SyncNotifier, SyncState>(
  SyncNotifier.new,
);

class SyncNotifier extends Notifier<SyncState> {
  StreamSubscription<bool>? _connectivitySub;
  bool _sawConnectivityEvent = false;
  bool _settingsTouched = false;
  DateTime? _speedSampleTime;
  int _speedSampleBytes = 0;
  final Map<String, int> _fileProgress = {};

  ConnectivityService get _connectivity =>
      ref.read(connectivityServiceProvider);
  SyncEngine get _syncEngine => ref.read(syncEngineProvider);
  LocalRecordingRepository get _recordingRepo =>
      ref.read(localRecordingRepositoryProvider);
  UploadForegroundService get _uploadForegroundService =>
      ref.read(uploadForegroundServiceProvider);

  Future<AppLocalizations> _resolveLocalizations() async {
    final Locale locale =
        ref.read(localeProvider) ??
        WidgetsBinding.instance.platformDispatcher.locale;
    return AppLocalizations.delegate.load(locale);
  }

  @override
  SyncState build() {
    ref.onDispose(_cleanup);
    _loadSettings();
    _initConnectivity();
    return const SyncState();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // The user can reach the switches before this continuation lands (the
    // SharedPreferences singleton is already warm from startup, so the load
    // resolves *after* an updateSettings that came later). Their choice is
    // newer than the disk, and updateSettings persisted it anyway — one flag
    // covers both fields because SyncSettings always carries both.
    if (_settingsTouched) return;
    state = state.copyWith(
      autoUploadWifiOnly: prefs.getBool(_kAutoUploadWifiOnlyKey),
      autoRemoveAfterUpload: prefs.getBool(_kAutoRemoveAfterUploadKey),
    );
  }

  Future<void> _initConnectivity() async {
    // Subscribe before awaiting the snapshot: onConnectivityChanged is a
    // broadcast stream with no replay, so a flip during the await would be lost.
    _connectivitySub = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    final online = await _connectivity.isOnline;
    // A live event during the await already set a fresher value; don't let the
    // now-stale snapshot clobber it.
    if (!_sawConnectivityEvent) {
      state = state.copyWith(isOnline: online);
    }

    await _refreshPendingCount();
  }

  void _onConnectivityChanged(bool online) {
    _sawConnectivityEvent = true;
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
    // Shared upload guard: syncOne and processQueue are mutually exclusive so
    // they cannot interleave shared state or start/stop the foreground service
    // concurrently. Bail if an upload op is already running. resetAndRetry must
    // NOT acquire this guard — it calls syncOne, and a re-entrant acquire would
    // make the inner syncOne bail and silently skip the upload.
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      // An upload is running, so no verdict from an earlier blocked pass is
      // still true. processQueue bails on the shared guard without recomputing
      // it, and that stale verdict is what the chip would report.
      state = state.copyWith(
        uploadingId: recordingId,
        syncProgress: 0,
        clearBlockReason: true,
      );
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
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> retryFailed() async {
    await processQueue();
  }

  Future<void> resetAndRetry(String recordingId) async {
    await _recordingRepo.resetRetryCount(recordingId);
    await _refreshPendingCount();
    await syncOne(recordingId);
  }

  /// Both flags are persisted: they were state-only, so a device parked on
  /// cellular got the Wi-Fi-only default back on every relaunch and its queue
  /// never drained (ENG-355).
  Future<void> updateSettings(SyncSettings settings) async {
    _settingsTouched = true;
    state = state.copyWith(
      autoUploadWifiOnly: settings.autoUploadWifiOnly,
      autoRemoveAfterUpload: settings.autoRemoveAfterUpload,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoUploadWifiOnlyKey, settings.autoUploadWifiOnly);
    await prefs.setBool(
      _kAutoRemoveAfterUploadKey,
      settings.autoRemoveAfterUpload,
    );
  }

  Future<int> getLocalStorageUsed() async {
    if (kIsWeb) return 0;

    final all = await _recordingRepo.getAllLocalRecordings();
    final sizes = await Future.wait(all.map((r) => _fileSize(r.localFilePath)));
    return sizes.fold<int>(0, (sum, n) => sum + n);
  }

  Future<int> _fileSize(String path) async {
    try {
      if (await file_ops.fileExists(path)) {
        return await file_ops.fileLength(path);
      }
    } on Exception catch (e, st) {
      ref.read(errorReporterProvider).reportError(e, st);
    }
    return 0;
  }

  Future<({int usedBytes, int freeBytes, int totalBytes})>
  getStorageSnapshot() async {
    final results = await Future.wait([
      getLocalStorageUsed(),
      disk_space.getFreeBytes(),
      disk_space.getTotalBytes(),
    ]);
    return (
      usedBytes: results[0],
      freeBytes: results[1],
      totalBytes: results[2],
    );
  }

  /// Drops the local copies the server already has and returns how many
  /// recordings stayed on the device.
  ///
  /// A recording the server never received exists nowhere else, so it is kept —
  /// clearing the cache used to delete it and an hour-long story was lost that
  /// way (ENG-407).
  ///
  /// A row is removed only once its file is actually gone. The row is the only
  /// handle on that file — the storage figure and every later clear walk the
  /// rows — so dropping it after a failed delete would strand the audio on disk
  /// for good and report space that was never freed. A kept row with its file
  /// is consistent, and the next clear retries it.
  Future<int> clearLocalCache() async {
    if (kIsWeb) return 0;

    final all = await _recordingRepo.getAllLocalRecordings();
    final discardable = all
        .where(
          (r) => serverHasRecording(
            serverId: r.serverId,
            uploadStatus: r.uploadStatus,
          ),
        )
        .toList();

    final deleted = await Future.wait(
      discardable.map((r) => _tryDeleteFile(r.localFilePath)),
    );
    final removableIds = [
      for (var i = 0; i < discardable.length; i++)
        if (deleted[i]) discardable[i].id,
    ];
    await _recordingRepo.deleteRecordingsByIds(removableIds);

    await _refreshPendingCount();
    return all.length - removableIds.length;
  }

  /// Deletes [path], reporting and swallowing any failure. Returns whether the
  /// file is gone — an absent file is a success, since `deleteFile` checks
  /// existence first and never throws for one.
  Future<bool> _tryDeleteFile(String path) async {
    try {
      await ref.read(deleteFileProvider)(path);
      return true;
    } on Exception catch (e, st) {
      ref.read(errorReporterProvider).reportError(e, st);
      return false;
    }
  }

  bool _isProcessing = false;

  Future<void> processQueue() async {
    if (!state.isOnline) {
      // Being offline is its own (already visible) condition; don't leave a
      // stale Wi-Fi-only verdict behind to be reported instead.
      state = state.copyWith(clearBlockReason: true);
      // Refuse the drain, but still report the queue honestly — callers change
      // its contents and then ask for a pass (the list's bulk retry does, and
      // works offline by design). The Wi-Fi-only branch inside _runQueue
      // refreshes before it blocks, for the same reason (ENG-404).
      await _refreshPendingCount();
      return;
    }
    // Shared upload guard (see syncOne): bail if an upload op is already in
    // flight so concurrent runs can't stop the foreground service mid-upload.
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      await _runQueue();
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _runQueue() async {
    await _refreshPendingCount();

    final isWifi = await _connectivity.isOnWifi;
    // The engine applies this policy too, but by returning quietly — and the
    // caller then wrote lastSyncAt for a queue that never ran. Decide here so
    // no run is reported, no foreground service is raised, and the UI can tell
    // the user why nothing moved (ENG-355).
    if (state.autoUploadWifiOnly && !isWifi) {
      // The gate holds back the uploads, not the metadata outbox (ENG-403):
      // this return is what the engine's own exemption would never be reached
      // through, so the drain is asked for explicitly here. `blockReason` still
      // says Wi-Fi, and truthfully — it describes the uploads, which really are
      // waiting. Nothing else is written: `lastSyncAt` and `syncProgress` would
      // report a queue run that did not happen, and `pendingCount` counts
      // uploads, which this drain does not change.
      await _syncEngine.processPendingMetadata();
      state = state.copyWith(blockReason: SyncBlockReason.wifiOnly);
      return;
    }
    state = state.copyWith(clearBlockReason: true);

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

    final concurrency = isWifi ? 3 : 1;

    // Keep the Android process alive while the queue runs so uploads continue
    // when the app is minimized; the foreground service is declared with
    // stopWithTask, so a swipe-away ends it (the queue resumes from the saved
    // offset on next launch). No-op on iOS/web. The title resolver only runs on
    // Android (inside start, after the platform guard).
    await _uploadForegroundService.start(
      titleResolver: () async =>
          (await _resolveLocalizations()).upload_inProgressNotificationTitle,
      body: pending.isNotEmpty ? (pending.first.title ?? '') : '',
    );
    try {
      await _syncEngine.processQueue(
        deleteAfterUpload: state.autoRemoveAfterUpload,
        wifiOnly: state.autoUploadWifiOnly,
        maxConcurrency: concurrency,
        onProgress: _onUploadProgress,
      );
    } finally {
      await _uploadForegroundService.stop();
    }

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
