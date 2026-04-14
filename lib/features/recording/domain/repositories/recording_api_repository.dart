import '../entities/server_recording.dart';

abstract class RecordingApiRepository {
  Future<ServerRecording> getRecording(String serverId);
  Future<List<ServerRecording>> listRecordings(
    String projectId, {
    int offset = 0,
    int limit = 50,
  });
  Future<bool> deleteRecording(String serverId);
  Future<bool> updateRecording(
    String serverId, {
    String? title,
    String? description,
    String? genreId,
    String? subcategoryId,
    String? registerId,
    String? cleaningStatus,
  });

  Future<List<String>> splitRecording({
    required String serverId,
    required List<Map<String, double>> segments,
  });

  Future<int> clearStaleRecordings(String projectId);
}
