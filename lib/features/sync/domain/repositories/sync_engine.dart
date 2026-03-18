abstract class SyncEngine {
  bool get isProcessing;
  Future<void> processQueue({
    bool deleteAfterUpload = false,
    void Function(int bytesSent, int totalBytes)? onProgress,
  });
}
