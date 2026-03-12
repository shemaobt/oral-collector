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
      uploadingId: clearUploadingId ? null : (uploadingId ?? this.uploadingId),
      syncProgress: syncProgress ?? this.syncProgress,
      lastSyncAt: clearLastSyncAt ? null : (lastSyncAt ?? this.lastSyncAt),
      autoUploadWifiOnly: autoUploadWifiOnly ?? this.autoUploadWifiOnly,
      autoRemoveAfterUpload:
          autoRemoveAfterUpload ?? this.autoRemoveAfterUpload,
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
