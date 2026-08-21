import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/recording_config.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/observability/error_reporter.dart';
import '../../../../core/platform/recording_active_flag.dart';
import '../providers.dart';
import 'recovery_disk.dart';
import 'session_audio.dart';

class InterruptedSession {
  const InterruptedSession({
    required this.sessionId,
    required this.genreId,
    required this.subcategoryId,
    required this.totalDuration,
    required this.startedAt,
    required this.segmentCount,
  });

  final String sessionId;
  final String genreId;
  final String? subcategoryId;
  final Duration totalDuration;
  final DateTime startedAt;
  final int segmentCount;
}

final interruptedSessionsProvider = StateProvider<List<InterruptedSession>>(
  (_) => const [],
);

class RecoveryCoordinator {
  RecoveryCoordinator(this._ref, {RecoveryDisk? disk})
    : _disk = disk ?? RecoveryDisk() {
    _ref.onDispose(() => _disposed = true);
  }

  static final _log = Logger('RecoveryCoordinator');

  final Ref _ref;

  /// Tudo o que precisa de `dart:io` está atrás disto, e no navegador a
  /// implementação responde "não há nenhum" (ENG-519, fatia 2).
  final RecoveryDisk _disk;
  bool _disposed = false;

  Future<void> scanOnStartup() async {
    final repo = _ref.read(recordingSessionRepositoryProvider);
    try {
      final active = await repo.findActiveSessions();
      if (active.isNotEmpty) {
        _log.info('scanOnStartup found ${active.length} active session(s)');
      }
      for (final session in active) {
        await _disk.repairInFlightSegments(session, repo);
        await repo.markCrashed(session.id);
      }
    } finally {
      await const RecordingActiveFlag().markInactive();
    }
    await _sweepFinishedSessionsWithUnsavedAudio();
    // Reported and swallowed rather than allowed to bubble: this is a one-off
    // repair of old rows, and letting it fail the startup scan would cost the
    // refresh below — which is what puts today's unsaved recordings in front
    // of the person.
    try {
      await _recoverDiscardedSessionsHoldingAudio();
    } catch (e, st) {
      _ref.read(errorReporterProvider).reportError(e, st);
    }
    await refresh();
  }

  /// Gives back the audio of sessions that reached `discarded` while their
  /// files were still on the disk (ENG-522).
  ///
  /// ENG-521 closed the two paths that could write that status over live
  /// audio, but every row they already swallowed is still in the database with
  /// its path, its segments and its metadata — `discarded` appears in no sweep
  /// query, so the recording it names is simply out of reach. Promoting the
  /// row back to `crashed` is all it takes for the unsaved list to offer it
  /// again, metadata included.
  ///
  /// **It runs once per device, and that is the whole safety story.** A
  /// deliberate discard whose file outlived it is indistinguishable, from the
  /// database, from one the defect swallowed; recovering on every launch would
  /// therefore hand back whatever the person discards afterwards, forever,
  /// leaving them unable to delete anything. Of the two possible mistakes,
  /// giving back something they meant to delete is the recoverable one — they
  /// discard it again, and since ENG-521 the discard works.
  ///
  /// The mark is written last, so a run that dies half-way retries on the next
  /// launch; the rows it already promoted are no longer `discarded`, so they
  /// are not promoted twice.
  Future<void> _recoverDiscardedSessionsHoldingAudio() async {
    final prefs = await SharedPreferences.getInstance();
    final key = RecordingConfig.discardedAudioRecoveryDoneKey;
    if (prefs.getBool(key) ?? false) return;

    final repo = _ref.read(recordingSessionRepositoryProvider);
    for (final session in await repo.findDiscardedSessions()) {
      // Both legs of the predicate count: the finalized recording the row is
      // anchored to, and the source segments a session that never got to
      // finalize was left with. The second is the shape the resumed-recording
      // leak produced, so dropping it would miss the commoner half.
      final segments = repo.decodeSegmentPaths(session);
      if (!await sessionHoldsReachableAudio(session, segments)) continue;
      _log.info(
        'recovering discarded session ${session.id}: its audio is still here',
      );
      await repo.markCrashed(session.id);
    }

    await prefs.setBool(key, true);
  }

  /// Surfaces sessions that finished with audio the user never saved.
  ///
  /// The question asked is "did this session produce audio that nothing
  /// saved?", and both halves are answered from the database, so the answer no
  /// longer depends on whether the fire-and-forget source deletions inside
  /// `finalize()` have landed yet (ENG-420). Sessions whose anchor names a file
  /// that is already gone are left alone: offering a recovery that cannot
  /// succeed is worse than offering nothing.
  ///
  /// It runs on both platforms since ENG-519 (fatia 2). It had to: on web a
  /// capture that reached stop leaves exactly this shape — a finished session
  /// anchored to storage with no saved recording — and nothing else would ever
  /// promote it. Only the pre-v14 residue below is device-only.
  Future<void> _sweepFinishedSessionsWithUnsavedAudio() async {
    final sessionRepo = _ref.read(recordingSessionRepositoryProvider);
    final localRepo = _ref.read(localRecordingRepositoryProvider);

    final finished = await sessionRepo.findFinishedSessions();
    if (finished.isEmpty) return;

    final localRecordings = await localRepo.getAllLocalRecordings();

    for (final session in finished) {
      final dot = '_${session.id}.';
      final under = '_${session.id}_';
      final saved = localRecordings.any(
        (lr) =>
            lr.localFilePath.contains(dot) || lr.localFilePath.contains(under),
      );
      if (saved) continue;

      if (!await _hasUnsavedAudio(session)) continue;

      _log.info(
        'sweep promoting session ${session.id} from ${session.status} → '
        'crashed: finalized audio with no saved recording',
      );
      await _disk.repairInFlightSegments(session, sessionRepo);
      await sessionRepo.markCrashed(session.id);
    }
  }

  /// An anchored session is judged by its anchor, through the same predicate
  /// every other caller uses — which resolves a device path and asks the
  /// browser's storage for a key, so one criterion covers both platforms
  /// (ENG-519, fatia 2). It has to be the file and not the column, because
  /// discarding from the save form deletes the audio without touching the row.
  ///
  /// Rows without an anchor fall back to the disk scan: they either predate
  /// schema v14, or they reached their status before finalization ran
  /// (`recoverSessionFromDisk` marks a row recovered up front). That fallback
  /// is device-only and answers false on web, which is the truth there — a
  /// browser session with no anchor never had audio anywhere. It can go once
  /// no supported upgrade path can still be carrying pre-v14 sessions and no
  /// path can mark a session finished before it has audio.
  Future<bool> _hasUnsavedAudio(RecordingSession session) async {
    final anchor = session.finalizedAudioPath;
    if (anchor != null) return durableAudioExists(anchor);
    return _disk.hasOrphanSegmentFiles(session.id);
  }

  Future<void> refresh() async {
    final repo = _ref.read(recordingSessionRepositoryProvider);
    // Capture the notifier before the awaits; the post-await write is skipped
    // via _disposed if the provider is torn down mid-refresh (ENG-140 F22).
    final interrupted = _ref.read(interruptedSessionsProvider.notifier);
    final crashed = await repo.findCrashedSessions();

    final result = <InterruptedSession>[];
    for (final candidate in crashed) {
      var session = candidate;
      var segments = repo.decodeSegmentPaths(session);

      if (segments.isEmpty) {
        // Filesystem may hold orphan segments that never made it into the DB
        // (e.g. _stopNative caught a finish() exception before appendSegment
        // ran). Repair + attach before declaring the session lost. On web
        // there is nothing to scan and this answers immediately.
        await _disk.repairInFlightSegments(session, repo);
        final reloaded = await repo.getById(session.id);
        if (reloaded != null) {
          session = reloaded;
          segments = repo.decodeSegmentPaths(session);
        }
      }

      // Segments *or* an anchor: either one is audio the person can get back,
      // and the save path already prefers the anchor, only falling back to
      // re-deriving from the sources (ENG-420). Requiring segments is what
      // dropped a browser recording — its capture is a single blob, so it has
      // an anchor and no segments, ever — and it dropped the device sessions
      // of that same shape too, the ones whose sources the fire-and-forget
      // deletions already took (ENG-519, fatia 2).
      if (segments.isEmpty && session.finalizedAudioPath == null) {
        // Neither one means a session that never produced audio anywhere: the
        // tab closed mid-capture, or a start that failed. There is nothing to
        // offer, and a row left alive would sit outside every sweep's reach
        // forever, so it is closed here.
        await repo.markDiscarded(session.id);
        continue;
      }
      result.add(
        InterruptedSession(
          sessionId: session.id,
          genreId: session.genreId,
          subcategoryId: session.subcategoryId,
          totalDuration: Duration(
            milliseconds: (session.totalDurationSeconds * 1000).round(),
          ),
          startedAt: session.startedAt,
          segmentCount: segments.length,
        ),
      );
    }

    if (_disposed) return;
    interrupted.state = result;
  }
}

final recoveryCoordinatorProvider = Provider<RecoveryCoordinator>(
  (ref) => RecoveryCoordinator(ref),
);
