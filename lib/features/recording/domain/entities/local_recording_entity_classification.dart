import 'classification.dart';
import 'local_recording_entity.dart';
import 'review_pendency.dart';

/// Classification view of [LocalRecordingEntity].
///
/// `isUnclassified` reads through [recordingPendencies] rather than deriving
/// its own answer, so the breadcrumb, the action menu and the guided flow can
/// never disagree about whether a recording is classified. That also means the
/// server settles it for any recording it knows about (ENG-374); the local
/// predicates still answer for a recording that has never been uploaded, which
/// is the only case the server has no opinion on.
extension LocalRecordingEntityClassification on LocalRecordingEntity {
  bool get isUnclassified =>
      recordingPendencies(this).contains(PendencyKind.classification);

  bool get hasSecondary => recordingHasSecondary(
    secondaryGenreId: secondaryGenreId,
    secondaryRegisterId: secondaryRegisterId,
  );
}
