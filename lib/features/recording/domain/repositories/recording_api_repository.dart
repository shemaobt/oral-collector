import '../entities/server_recording.dart';
import '../entities/split_segment_request.dart';
import '../entities/update_recording_request.dart';

abstract class RecordingApiRepository {
  Future<ServerRecording> getRecording(String serverId);
  Future<List<ServerRecording>> listRecordings(
    String projectId, {
    int offset = 0,
    int limit = 50,
    String? userId,
    String? storytellerId,
    String? uploadStatus,
  });
  Future<bool> deleteRecording(String serverId);
  Future<bool> updateRecording(String serverId, UpdateRecordingRequest request);

  Future<List<String>> splitRecording({
    required String serverId,
    required List<SplitSegmentRequest> segments,
  });

  Future<int> clearStaleRecordings(String projectId);
}
