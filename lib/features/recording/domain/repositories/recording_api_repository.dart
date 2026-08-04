import '../entities/review_flag.dart';
import '../entities/server_recording.dart';
import '../entities/split_segment_request.dart';
import '../entities/update_recording_request.dart';

/// What a recording write answers with: whether the server accepted it, and
/// what it says the recording still owes now that it has (ENG-379).
///
/// The flags are carried alongside the outcome rather than left in the discarded
/// response body because the server recomputes them on every write and the local
/// row is what the pendency rule reads. [reviewFlags] is null when the response
/// said nothing about them — a refusal, or a server that predates ENG-373 —
/// which means "leave what is stored". An empty list is a real answer and clears
/// the row.
typedef UpdateRecordingOutcome = ({
  bool success,
  List<ReviewFlag>? reviewFlags,
});

abstract class RecordingApiRepository {
  Future<ServerRecording> getRecording(String serverId);
  Future<List<ServerRecording>> listRecordings(
    String projectId, {
    int offset = 0,
    int limit = 50,
    String? userId,
    String? storytellerId,
    String? uploadStatus,
    String? title,
  });
  Future<bool> deleteRecording(String serverId);
  Future<UpdateRecordingOutcome> updateRecording(
    String serverId,
    UpdateRecordingRequest request,
  );

  Future<List<String>> splitRecording({
    required String serverId,
    required List<SplitSegmentRequest> segments,
  });

  Future<int> clearStaleRecordings(String projectId);
}
