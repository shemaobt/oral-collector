abstract class SyncEngine {
  bool get isProcessing;
  Future<void> processQueue({bool deleteAfterUpload = false});
}
