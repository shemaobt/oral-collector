import '../entities/server_recording.dart';

abstract class RecordingApiRepository {
  Future<ServerRecording> getRecording(String serverId);
  Future<List<ServerRecording>> listRecordings(String projectId);
  Future<bool> deleteRecording(String serverId);
  Future<bool> updateRecording(
    String serverId, {
    String? genreId,
    String? subcategoryId,
    String? cleaningStatus,
  });
}
