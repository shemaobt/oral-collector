import 'dart:convert';

/// One metadata field this device edited while the server could not be reached
/// (ENG-403).
///
/// The outbox names fields, never values. The local row already holds the
/// desired state — every mutation writes it there — so the drain reads the
/// value back off the row at send time. Two offline edits to the same field
/// therefore collapse into one write instead of replaying out of order, and a
/// field this device never touched is never sent, which keeps a last-write-wins
/// PATCH from overwriting another device's edit with a stale local copy.
///
/// [secondary] covers the three secondary-classification columns as one unit:
/// they are always written together and the wire contract clears them together
/// (`UpdateRecordingRequest.clearSecondary`).
enum PendingMetadataField {
  title('title'),
  description('description'),
  genre('genre'),
  subcategory('subcategory'),
  register('register'),
  secondary('secondary'),
  cleaningStatus('cleaning_status');

  const PendingMetadataField(this.wireName);

  /// The token stored in the Drift column. Fixed independently of the Dart
  /// name so renaming the member cannot silently orphan every stored row.
  final String wireName;
}

/// Where a recording stands with the metadata outbox, as stored in
/// `LocalRecordings.metadataSyncStatus`.
///
/// The vocabulary deliberately borrows the upload queue's: [failedConflict] is
/// the same name clash with the same exit (rename), and [failedExhausted] means
/// the same spent budget. [failedForbidden] has no upload counterpart because
/// the upload path collapses every non-retryable refusal into `failed_exhausted`
/// — here it must stay apart, since offering a retry for a permission refusal
/// would offer a way out that leads nowhere.
abstract final class MetadataSyncStatus {
  static const synced = 'synced';
  static const pending = 'pending';
  static const failedForbidden = 'failed_forbidden';
  static const failedConflict = 'failed_conflict';
  static const failedExhausted = 'failed_exhausted';
}

/// Serializes [fields] for the Drift column, ordered by declaration so two rows
/// owing the same fields hold byte-identical text — the recording watch stream
/// dedups on value equality and would otherwise rebuild on a reordering.
String encodePendingMetadataFields(Set<PendingMetadataField> fields) {
  final ordered = fields.toList()..sort((a, b) => a.index.compareTo(b.index));
  return jsonEncode(ordered.map((f) => f.wireName).toList());
}

/// Reads the set back off a Drift row.
///
/// Mirrors [decodeReviewFlags]'s tolerance for the same reason: a token from a
/// newer build, or text that is not a JSON list at all, must cost at most the
/// un-pushed edit — not every read of the recording. An unknown token is
/// dropped so the fields this build *can* send still go.
Set<PendingMetadataField> decodePendingMetadataFields(String json) {
  if (json.isEmpty) return const {};
  final Object? raw;
  try {
    raw = jsonDecode(json);
  } on FormatException {
    return const {};
  }
  if (raw is! List) return const {};
  final byWireName = {
    for (final field in PendingMetadataField.values) field.wireName: field,
  };
  return {
    for (final token in raw)
      if (token is String && byWireName.containsKey(token)) byWireName[token]!,
  };
}
