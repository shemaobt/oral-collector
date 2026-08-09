import 'entities/local_recording_entity.dart';

/// The failure statuses a bare retry can still move.
///
/// `failed` is queued already, so a retry only skips the backoff wait and
/// returns the budget; `failed_exhausted` left the queue and is never tried
/// again without one. The other three failures would be refused the same way
/// on the next attempt — a duplicate title, a description under the minimum,
/// or no audio file at all — and each has its own banner leading to its own
/// fix, so offering a retry over them only wastes the user's tap.
bool isRetryableFailure(String uploadStatus) =>
    uploadStatus == 'failed' || uploadStatus == 'failed_exhausted';

/// Whether the detail screen's status card offers a plain "Retry".
///
/// `uploading` is excluded: the upload is happening, and a retry would reset
/// its budget and queue a second attempt on top of the one in flight.
bool canRetryUpload(String uploadStatus, int retryCount) =>
    isRetryableFailure(uploadStatus) ||
    (uploadStatus == 'local' && retryCount > 0);

/// Whether the recordings list offers its bulk retry over [recordings].
///
/// Matches what `LocalRecordingRepository.requeueFailedUploads` requeues, so
/// the button never appears over a set it would not touch.
bool hasRetryableFailedUploads(Iterable<LocalRecordingEntity> recordings) =>
    recordings.any((r) => isRetryableFailure(r.uploadStatus));
