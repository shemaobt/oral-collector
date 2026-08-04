import '../../../../shared/utils/recording_description.dart';
import 'classification.dart';
import 'local_recording_entity.dart';

/// A pendency the app knows how to walk the user through (ENG-374).
///
/// Deliberately narrower than [ReviewFlag]: a flag is whatever the server
/// chose to send, while a kind is something this build can open an editor for.
enum PendencyKind { classification, description, storyteller }

const Map<String, PendencyKind> _knownCodes = {
  'missing_classification': PendencyKind.classification,
  'insufficient_description': PendencyKind.description,
  'missing_storyteller': PendencyKind.storyteller,
};

/// What [recording] still owes, in a fixed order.
///
/// **The fields decide, for every kind this build knows how to check.** That is
/// deliberately not "the server owns review state, the client displays it",
/// and the reason is concrete rather than philosophical:
///
/// * A recording made on this device and uploaded keeps its local row. The
///   upload writes `serverId` and nothing else, so its `reviewFlags` stay empty
///   even though the server has an opinion. Trusting the flags there would make
///   the pill vanish the moment an upload succeeds, on a recording that is
///   still unclassified — losing the very prompt this feature exists to give.
/// * Nothing clears a flag on the local row when the user fixes the field it
///   named. Trusting the flags would leave a step open after the user completed
///   it, and send them back into the same editor from the sheet's own button.
///
/// The fields have neither problem: they are what the user just edited, and
/// they are right offline. The server's flags still ride along on the entity
/// and are the right source the day the server reports something this build
/// cannot compute — see [_unknownCodes]. Revisit this the moment that happens,
/// or once the local row keeps the server's flags current.
List<PendencyKind> recordingPendencies(LocalRecordingEntity recording) =>
    _fromFields(recording);

/// Codes the server sent that this build has no way to check or act on.
///
/// Dropped from the guided flow on purpose: a step with no editor behind it
/// strands the user, and the raw code is wire vocabulary in front of a field
/// worker. Exposed so callers can report them rather than lose them silently —
/// a code appearing here means the server knows something this build does not.
List<String> unknownReviewCodes(LocalRecordingEntity recording) => [
  for (final flag in recording.reviewFlags)
    if (!_knownCodes.containsKey(flag.code)) flag.code,
];

List<PendencyKind> _fromFields(LocalRecordingEntity recording) => [
  if (recordingIsUnclassified(
    genreId: recording.genreId,
    registerId: recording.registerId,
  ))
    PendencyKind.classification,
  if (!isDescriptionSufficient(recording.description)) PendencyKind.description,
  if (blankToNull(recording.storytellerId) == null) PendencyKind.storyteller,
];

/// The kind a server flag code names, or null when this build cannot act on it.
///
/// Exposed because the project screen receives bare codes from the stats
/// aggregate — it has no recording to hand to [recordingPendencies] — and needs
/// to reach the same labels the guided flow uses. Keeping the map itself
/// private means both surfaces still resolve a code exactly one way.
PendencyKind? pendencyKindForCode(String code) => _knownCodes[code];
