import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../recording/data/providers/local_recording_repository_provider.dart';
import '../../../recording/data/repositories/local_recording_repository.dart';
import '../repositories/connectivity_service.dart';
import '../repositories/sync_engine.dart';

// --- State ---

class SyncState {
  final bool isOnline;
  final int pendingCount;
  final String? uploadingId;
  final int syncProgress;
  final DateTime? lastSyncAt;
  final bool autoUploadWifiOnly;
  final bool autoRemoveAfterUpload;

  const SyncState({
    this.isOnline = false,
    this.pendingCount = 0,
    this.uploadingId,
    this.syncProgress = 0,
    this.lastSyncAt,
    this.autoUploadWifiOnly = true,
    this.autoRemoveAfterUpload = true,
  });

  SyncState copyWith({
    bool? isOnline,
    int? pendingCount,
    String? uploadingId,
    int? syncProgress,
    DateTime? lastSyncAt,
    bool? autoUploadWifiOnly,
    bool? autoRemoveAfterUpload,
    bool clearUploadingId = false,
    bool clearLastSyncAt = false,
  }) {
    return SyncState(
      isOnline: isOnline ?? this.isOnline,
      pendingCount: pendingCount ?? this.pendingCount,
      uploadingId:
          clearUploadingId ? null : (uploadingId ?? this.uploadingId),
      syncProgress: syncProgress ?? this.syncProgress,
      lastSyncAt:
          clearLastSyncAt ? null : (lastSyncAt ?? this.lastSyncAt),
      autoUploadWifiOnly: autoUploadWifiOnly ?? this.autoUploadWifiOnly,
      autoRemoveAfterUpload:
          autoRemoveAfterUpload ?? this.autoRemoveAfterUpload,
    );
  }
}

// --- Settings ---

class SyncSettings {
  final bool autoUploadWifiOnly;
  final bool autoRemoveAfterUpload;

  const SyncSettings({
    required this.autoUploadWifiOnly,
    required this.autoRemoveAfterUpload,
  });
}

// --- Providers ---

final connectivityServiceProvider = Provider<ConnectivityService>(
  (_) => ConnectivityService(),
);

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final recordingRepo = ref.watch(localRecordingRepositoryProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  return SyncEngine(
    recordingRepo: recordingRepo,
    connectivity: connectivity,
  );
});

final syncNotifierProvider =
    NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);

// --- Notifier ---

class SyncNotifier extends Notifier<SyncState> {
  StreamSubscription<bool>? _connectivitySub;

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

  /// Initialize connectivity monitoring and check initial status.
  Future<void> _initConnectivity() async {
    final online = await _connectivity.isOnline;
    state = state.copyWith(isOnline: online);

    _connectivitySub = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    await _refreshPendingCount();
  }

  /// Handle connectivity changes — auto-trigger sync when coming online.
  void _onConnectivityChanged(bool online) {
    final wasOffline = !state.isOnline;
    state = state.copyWith(isOnline: online);

    if (online && wasOffline) {
      processQueue();
    }
  }

  /// Sync all pending recordings.
  Future<void> syncAll() async {
    await processQueue();
  }

  /// Sync a single recording by ID.
  Future<void> syncOne(String recordingId) async {
    state = state.copyWith(uploadingId: recordingId, syncProgress: 0);

    try {
      final recording = await _recordingRepo.getRecordingById(recordingId);
      if (recording == null) return;

      await _recordingRepo.markAsUploading(recordingId);
      state = state.copyWith(syncProgress: 50);

      await _syncEngine.processQueue(
        deleteAfterUpload: state.autoRemoveAfterUpload,
      );

      state = state.copyWith(
        syncProgress: 100,
        clearUploadingId: true,
        lastSyncAt: DateTime.now(),
      );
    } on Exception {
      state = state.copyWith(clearUploadingId: true, syncProgress: 0);
    }

    await _refreshPendingCount();
  }

  /// Retry all failed recordings.
  Future<void> retryFailed() async {
    await processQueue();
  }

  /// Update sync settings (wifi-only, auto-remove).
  void updateSettings(SyncSettings settings) {
    state = state.copyWith(
      autoUploadWifiOnly: settings.autoUploadWifiOnly,
      autoRemoveAfterUpload: settings.autoRemoveAfterUpload,
    );
  }

  /// Get total bytes used by local recording files.
  Future<int> getLocalStorageUsed() async {
    final pending = await _recordingRepo.getPendingUploads();
    var totalBytes = 0;

    for (final recording in pending) {
      try {
        final file = File(recording.localFilePath);
        if (await file.exists()) {
          totalBytes += await file.length();
        }
      } on Exception {
        // Skip files that can't be accessed.
      }
    }

    return totalBytes;
  }

  /// Process the upload queue, updating state as uploads progress.
  Future<void> processQueue() async {
    if (!state.isOnline) return;

    await _refreshPendingCount();
    if (state.pendingCount == 0) return;

    final pending = await _recordingRepo.getPendingUploads();
    final total = pending.length;

    for (var i = 0; i < pending.length; i++) {
      final recording = pending[i];
      state = state.copyWith(
        uploadingId: recording.id,
        syncProgress: ((i / total) * 100).round(),
      );

      await _syncEngine.processQueue(
        deleteAfterUpload: state.autoRemoveAfterUpload,
      );

      await _refreshPendingCount();
    }

    state = state.copyWith(
      clearUploadingId: true,
      syncProgress: 100,
      lastSyncAt: DateTime.now(),
    );
  }

  /// Refresh the pending upload count from the database.
  Future<void> _refreshPendingCount() async {
    final pending = await _recordingRepo.getPendingUploads();
    state = state.copyWith(pendingCount: pending.length);
  }

  void _cleanup() {
    _connectivitySub?.cancel();
  }
}
