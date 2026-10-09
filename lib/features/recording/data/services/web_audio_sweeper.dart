import 'package:logging/logging.dart';

final _log = Logger('WebAudioSweeper');

/// How old an abandoned browser recording has to be before it is collected.
/// The same window `RecordingTrash.pruneOldTrash` gives a trashed file on
/// device, so the app is consistent with itself about how long it holds on to
/// audio nothing points at.
///
/// It is also what keeps a second tab safe without any cross-tab coordination:
/// a recording in progress, or one sitting on the confirmation form, is
/// minutes old and never in range.
const Duration webOrphanAudioMaxAge = Duration(hours: 24);

/// A contract shared with the recorder: `_startWeb` in
/// `recording_session_notifier.dart` builds a recording's storage key as this
/// prefix followed by `DateTime.now().millisecondsSinceEpoch`, and the
/// container extension is appended when the bytes are written at stop. That
/// name is the only record of when the recording started — the sweeper reads
/// the age straight out of it. Nothing forces the two ends to agree except the
/// test 'the sweeper collects the key the recorder actually produces', which
/// drives the real capture path and sweeps whatever key it chose.
const String _recordingKeyPrefix = 'web_record_';

/// Collects recorded bytes the browser is still holding for recordings that
/// were abandoned before they reached the server (ENG-426).
///
/// On web the audio goes to storage when capture stops but the row that points
/// at it is only written after a successful upload, so a reload on the
/// confirmation form, a closed tab, or a failed upload leaves bytes nothing
/// will ever ask for again. The storage is reached through [listKeys] and
/// [deleteKey] so this can run against the real store in a test without a
/// browser; [keysInUse] and [now] are there for the same reason.
///
/// [keysInUse] names the audio an interrupted upload can still resume from
/// (ENG-427). Until that upload's row pointed at its bytes the promise of
/// never collecting what a pending upload needs was vacuous — nothing needed
/// them. It is answered once per sweep and matched key for key: sparing a
/// whole store because one upload is pending would leave the sweep on and
/// collecting nothing.
Future<void> sweepOrphanWebAudio({
  required Future<List<String>> Function() listKeys,
  required Future<void> Function(String key) deleteKey,
  required Future<Set<String>> Function() keysInUse,
  DateTime? now,
}) async {
  final cutoff = (now ?? DateTime.now()).subtract(webOrphanAudioMaxAge);
  try {
    final inUse = await keysInUse();
    for (final key in await listKeys()) {
      if (inUse.contains(key)) continue;
      final startedAt = _recordingStartedAt(key);
      // A key whose start cannot be read is left alone rather than collected
      // on suspicion: deleting what is not understood is how audio gets lost.
      // A start in the future — a clock that moved back — is not before the
      // cutoff either, so it stays too.
      if (startedAt == null || !startedAt.isBefore(cutoff)) continue;
      await deleteKey(key);
    }
  } catch (error, stack) {
    // The browser's storage is a system boundary and can refuse either call
    // (quota, a database blocked by another tab, private browsing), and so can
    // the database [keysInUse] reads — a sweep that cannot tell what is in use
    // deletes nothing rather than guessing.
    // Housekeeping is never a reason for a blank first screen, so the sweep
    // gives up here and startup carries on.
    _log.warning('gave up sweeping abandoned browser audio', error, stack);
  }
}

DateTime? _recordingStartedAt(String key) {
  if (!key.startsWith(_recordingKeyPrefix)) return null;
  final rest = key.substring(_recordingKeyPrefix.length);
  final extension = rest.indexOf('.');
  final startedAt = int.tryParse(
    extension < 0 ? rest : rest.substring(0, extension),
  );
  return startedAt == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(startedAt);
}
