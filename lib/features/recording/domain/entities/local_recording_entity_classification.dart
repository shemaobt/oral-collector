import 'classification.dart';
import 'local_recording_entity.dart';

/// Classification view of [LocalRecordingEntity], mirroring the row-level
/// `RecordingClassification` extension. Both delegate to the same pure
/// predicates so the entity and the Drift row classify identically.
extension LocalRecordingEntityClassification on LocalRecordingEntity {
  bool get isUnclassified =>
      recordingIsUnclassified(genreId: genreId, registerId: registerId);

  bool get hasSecondary => recordingHasSecondary(
    secondaryGenreId: secondaryGenreId,
    secondaryRegisterId: secondaryRegisterId,
  );
}
