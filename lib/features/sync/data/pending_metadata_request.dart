import '../../../core/database/app_database.dart';
import '../../recording/domain/entities/pending_metadata_field.dart';
import '../../recording/domain/entities/update_recording_request.dart';

/// Rebuilds the PATCH body for what [row] still owes the server (ENG-403).
///
/// The values come off the row, not off a stored payload: the row *is* the
/// desired state, so a field edited twice offline goes up once, at its latest
/// value, with no ordering to preserve.
///
/// Only [fields] are sent. The endpoint is last-write-wins with no ETag or
/// version (ENG-124 is backlog), so the size of the body is the size of the
/// window in which this device can clobber another's edit — a field nobody
/// touched here must not ride along.
///
/// Each field is reproduced exactly as the mutation that owed it would have
/// sent it, including the two places `UpdateRecordingRequest` cannot express a
/// single explicit null (a null `subcategoryId` is omitted, not cleared). That
/// limitation is the online path's too; matching it keeps the drained write and
/// the direct write from disagreeing.
UpdateRecordingRequest buildPendingMetadataRequest(
  LocalRecording row,
  Set<PendingMetadataField> fields,
) {
  final owesSecondary = fields.contains(PendingMetadataField.secondary);
  // An empty secondary classification is the one thing the wire contract can
  // only say with the explicit-null form.
  final secondaryIsSet =
      row.secondaryGenreId != null ||
      row.secondarySubcategoryId != null ||
      row.secondaryRegisterId != null;

  T? owed<T>(PendingMetadataField field, T? value) =>
      fields.contains(field) ? value : null;

  return UpdateRecordingRequest(
    title: owed(PendingMetadataField.title, row.title),
    description: owed(PendingMetadataField.description, row.description),
    genreId: owed(PendingMetadataField.genre, row.genreId),
    subcategoryId: owed(PendingMetadataField.subcategory, row.subcategoryId),
    registerId: owed(PendingMetadataField.register, row.registerId),
    secondaryGenreId: owesSecondary ? row.secondaryGenreId : null,
    secondarySubcategoryId: owesSecondary ? row.secondarySubcategoryId : null,
    secondaryRegisterId: owesSecondary ? row.secondaryRegisterId : null,
    clearSecondary: owesSecondary && !secondaryIsSet,
    cleaningStatus: owed(
      PendingMetadataField.cleaningStatus,
      row.cleaningStatus,
    ),
  );
}
