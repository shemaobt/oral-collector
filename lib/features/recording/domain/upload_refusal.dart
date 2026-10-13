enum UploadRefusalReason {
  objectMissing('UPLOAD_OBJECT_MISSING', 'failed_refused_object_missing'),
  sizeMismatch('UPLOAD_SIZE_MISMATCH', 'failed_refused_size_mismatch'),
  checksumMismatch(
    'UPLOAD_CHECKSUM_MISMATCH',
    'failed_refused_checksum_mismatch',
  );

  const UploadRefusalReason(this.code, this.status);

  final String code;
  final String status;
}

const refusedWithoutReasonStatus = 'failed_refused';

final refusalStatuses = [
  refusedWithoutReasonStatus,
  for (final reason in UploadRefusalReason.values) reason.status,
];

String refusalStatusFor(String? code) {
  for (final reason in UploadRefusalReason.values) {
    if (reason.code == code) return reason.status;
  }
  return refusedWithoutReasonStatus;
}

UploadRefusalReason? refusalReasonOf(String uploadStatus) {
  for (final reason in UploadRefusalReason.values) {
    if (reason.status == uploadStatus) return reason;
  }
  return null;
}

bool isRefusalStatus(String uploadStatus) =>
    refusalStatuses.contains(uploadStatus);
