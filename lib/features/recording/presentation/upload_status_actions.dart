import '../domain/entities/local_recording_entity.dart';

/// Whether the detail screen's status card offers a plain "Retry".
///
/// `uploading` is excluded: the upload is happening, and a retry would reset
/// its budget and queue a second attempt on top of the one in flight.
bool canRetryUpload(String uploadStatus, int retryCount) =>
    uploadStatus == 'failed' ||
    uploadStatus == 'failed_exhausted' ||
    (uploadStatus == 'local' && retryCount > 0);

/// Whether the recordings list offers "Clear failed" over [recordings].
///
/// Matches what `LocalRecordingRepository.deleteStaleRecordings` deletes, so
/// the button never appears over a set it would not touch.
bool hasClearableFailedUploads(Iterable<LocalRecordingEntity> recordings) =>
    recordings.any((r) => r.uploadStatus == 'failed');
