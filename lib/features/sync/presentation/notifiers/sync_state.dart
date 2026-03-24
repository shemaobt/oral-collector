class SyncState {
  final bool isOnline;
  final int pendingCount;
  final String? uploadingId;
  final int syncProgress;
  final DateTime? lastSyncAt;
  final bool autoUploadWifiOnly;
  final bool autoRemoveAfterUpload;
  final int totalQueueSizeBytes;
  final int totalUploadedBytes;
  final String? currentFileName;
  final double uploadSpeedBps;

  const SyncState({
    this.isOnline = false,
    this.pendingCount = 0,
    this.uploadingId,
    this.syncProgress = 0,
    this.lastSyncAt,
    this.autoUploadWifiOnly = true,
    this.autoRemoveAfterUpload = true,
    this.totalQueueSizeBytes = 0,
    this.totalUploadedBytes = 0,
    this.currentFileName,
    this.uploadSpeedBps = 0,
  });

  Duration? get estimatedTimeRemaining {
    if (uploadSpeedBps <= 0) return null;
    final remaining = totalQueueSizeBytes - totalUploadedBytes;
    if (remaining <= 0) return null;
    return Duration(seconds: (remaining / uploadSpeedBps).ceil());
  }

  SyncState copyWith({
    bool? isOnline,
    int? pendingCount,
    String? uploadingId,
    int? syncProgress,
    DateTime? lastSyncAt,
    bool? autoUploadWifiOnly,
    bool? autoRemoveAfterUpload,
    int? totalQueueSizeBytes,
    int? totalUploadedBytes,
    String? currentFileName,
    double? uploadSpeedBps,
    bool clearUploadingId = false,
    bool clearLastSyncAt = false,
    bool clearCurrentFileName = false,
  }) {
    return SyncState(
      isOnline: isOnline ?? this.isOnline,
      pendingCount: pendingCount ?? this.pendingCount,
      uploadingId: clearUploadingId ? null : (uploadingId ?? this.uploadingId),
      syncProgress: syncProgress ?? this.syncProgress,
      lastSyncAt: clearLastSyncAt ? null : (lastSyncAt ?? this.lastSyncAt),
      autoUploadWifiOnly: autoUploadWifiOnly ?? this.autoUploadWifiOnly,
      autoRemoveAfterUpload:
          autoRemoveAfterUpload ?? this.autoRemoveAfterUpload,
      totalQueueSizeBytes: totalQueueSizeBytes ?? this.totalQueueSizeBytes,
      totalUploadedBytes: totalUploadedBytes ?? this.totalUploadedBytes,
      currentFileName: clearCurrentFileName
          ? null
          : (currentFileName ?? this.currentFileName),
      uploadSpeedBps: uploadSpeedBps ?? this.uploadSpeedBps,
    );
  }
}

class SyncSettings {
  final bool autoUploadWifiOnly;
  final bool autoRemoveAfterUpload;

  const SyncSettings({
    required this.autoUploadWifiOnly,
    required this.autoRemoveAfterUpload,
  });
}
