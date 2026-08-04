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
/// **The server decides for any recording it knows about** (ENG-379). It
/// recomputes on every write and returns the result, and it may apply a rule
/// this build predates — following the local columns there would mean
/// overruling the only party that can know.
///
/// A recording that has never been uploaded has no server answer, so its own
/// fields answer for it. Without that, a recording captured minutes ago would
/// read as complete while the person who made it is still standing there,
/// which is the moment this feature exists for.
///
/// This is only safe because the local row is kept current: the upload and
/// every edit store the flags the server sent back. ENG-374 shipped without
/// that, so the flags were empty on a recording this device had just uploaded
/// and stale after an edit — which is why it derived locally instead. Read
/// those two write paths before trusting this again.
///
/// Offline needs no special case: editing is online-first, so a failed call
/// leaves the row untouched and the stored flags cannot go stale.
List<PendencyKind> recordingPendencies(LocalRecordingEntity recording) {
  final serverId = recording.serverId;
  if (serverId == null || serverId.isEmpty) return _fromFields(recording);
  return _fromFlags(recording);
}

List<PendencyKind> _fromFlags(LocalRecordingEntity recording) {
  final kinds = <PendencyKind>{};
  for (final flag in recording.reviewFlags) {
    final kind = _knownCodes[flag.code];
    if (kind != null) kinds.add(kind);
  }
  // Reading order, not wire order: the sheet numbers these steps.
  return PendencyKind.values.where(kinds.contains).toList();
}

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

final Map<PendencyKind, String> _codeForKind = {
  for (final entry in _knownCodes.entries) entry.value: entry.key,
};

/// The wire code for [kind], for callers that send a filter to the server.
///
/// Inverted from the same table rather than written out again, so the two
/// directions cannot disagree. Total by construction: the enum exists to mirror
/// the server's closed set, so a code the server would reject with a 422 is
/// unreachable from here.
String reviewFlagCodeFor(PendencyKind kind) => _codeForKind[kind]!;
