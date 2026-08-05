import '../../../../core/errors/api_exception.dart';
import '../../domain/entities/update_recording_request.dart';
import '../../domain/repositories/recording_api_repository.dart';
import '../repositories/local_recording_repository.dart';

enum SaveDescriptionResult { saved, savedLocallyOnly }

/// Writes a corrected description to the server first, then to the local row
/// (ENG-380).
///
/// It used to go straight to the local row on native, and an uploaded recording
/// never returns to the upload queue — so the correction stayed on one device,
/// invisible to every other and lost on reinstall. It also left the server's
/// `insufficient_description` flag standing, which is what kept the guided
/// flow's "Describe" step from ever closing.
///
/// Mirrors [saveRecordingTitle], including the order: the server is asked
/// first, so a refusal never leaves the local row claiming a change the server
/// rejected. A description cannot collide the way a title can, so there is no
/// conflict arm.
Future<SaveDescriptionResult> saveRecordingDescription({
  required String recordingId,
  required String? serverId,
  required String description,
  required bool isWeb,
  required bool isOnline,
  required RecordingApiRepository apiRepo,
  required LocalRecordingRepository? localRepo,
}) async {
  assert(
    isWeb || localRepo != null,
    'localRepo is required when isWeb is false',
  );

  final hasServerCopy = serverId != null && serverId.isNotEmpty;

  if (isWeb) {
    await apiRepo.updateRecording(
      hasServerCopy ? serverId : recordingId,
      UpdateRecordingRequest(description: description),
    );
    return SaveDescriptionResult.saved;
  }

  // Nothing to correct on the server yet: the description rides along with the
  // upload, so a local write is the whole job.
  if (!isOnline || !hasServerCopy) {
    await localRepo!.updateDescription(recordingId, description);
    return hasServerCopy
        ? SaveDescriptionResult.savedLocallyOnly
        : SaveDescriptionResult.saved;
  }

  try {
    final outcome = await apiRepo.updateRecording(
      serverId,
      UpdateRecordingRequest(description: description),
    );
    await localRepo!.updateDescription(recordingId, description);
    // The server recomputes what the recording still owes on every write; this
    // is the step that lets the Describe step close (ENG-379).
    final flags = outcome.reviewFlags;
    if (flags != null) {
      await localRepo.updateReviewFlags(recordingId, flags);
    }
    return SaveDescriptionResult.saved;
  } on ForbiddenException {
    // Writing locally would leave the row asserting a change the server
    // refused.
    rethrow;
  } catch (_) {
    await localRepo!.updateDescription(recordingId, description);
    return SaveDescriptionResult.savedLocallyOnly;
  }
}
