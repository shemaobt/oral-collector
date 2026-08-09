abstract class SyncEngine {
  bool get isProcessing;
  Future<void> processQueue({
    bool deleteAfterUpload = false,
    bool wifiOnly = false,
    int maxConcurrency = 1,
    void Function(String recordingId, int bytesSent, int totalBytes)?
    onProgress,
  });

  /// Drains the metadata outbox alone (ENG-403).
  ///
  /// [processQueue] already does this as its first queue; this exists for the
  /// one caller that must skip the rest — `SyncNotifier._runQueue`, which
  /// returns before reaching the engine when the Wi-Fi-only preference holds
  /// the uploads back. That preference is about mobile data spent on audio, and
  /// an edit is a few hundred bytes, so it goes up on any connection.
  Future<void> processPendingMetadata();

  Future<void> uploadSingle(
    String recordingId, {
    bool deleteAfterUpload = false,
    void Function(String recordingId, int bytesSent, int totalBytes)?
    onProgress,
  });
}
