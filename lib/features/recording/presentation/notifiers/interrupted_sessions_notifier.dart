import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/observability/error_reporter.dart';
import '../../../../core/platform/file_ops.dart' as file_ops;
import '../../data/providers.dart';
import '../../data/services/audio_path_resolver.dart';
import '../../data/services/recording_finalization_service.dart';
import '../../data/services/recovery_coordinator.dart';
import '../../data/services/segment_paths.dart';
import '../../data/services/session_audio.dart';
import 'recording_session_notifier.dart';
import 'recording_session_state.dart';

final interruptedSessionsNotifierProvider =
    NotifierProvider<InterruptedSessionsNotifier, void>(
      InterruptedSessionsNotifier.new,
    );

/// A recovered recording that was finalized and is awaiting the user's
/// confirmation (metadata) on the confirmation screen. The session stays
/// `crashed` until [InterruptedSessionsNotifier.confirmRecovery] runs, so a
/// cancelled confirmation re-surfaces in the recovery banner instead of losing
/// the recording. Held in a provider (not go_router `extra`) because the
/// finalized file path must survive redirects/rebuilds.
class PendingRecovery {
  const PendingRecovery({
    required this.result,
    required this.sessionId,
    required this.genreId,
    required this.subcategoryId,
  });

  final RecordingResult result;
  final String sessionId;
  final String genreId;
  final String? subcategoryId;
}

final pendingRecoveryProvider = StateProvider<PendingRecovery?>((_) => null);

class InterruptedSessionsNotifier extends Notifier<void> {
  static final _log = Logger('InterruptedSessionsNotifier');

  @override
  void build() {}

  Future<void> discard(String sessionId) async {
    final sessionRepo = ref.read(recordingSessionRepositoryProvider);
    final session = await sessionRepo.getById(sessionId);
    if (session != null) {
      final paths = sessionRepo.decodeSegmentPaths(session);
      for (final p in paths) {
        await _deleteFileSafe(p);
      }
      // Since ENG-420 slice 2 a session can reach the banner on the strength
      // of its finalized audio alone, so discarding one has to take that file
      // too — the segments it was built from may already be gone.
      final finalized = session.finalizedAudioPath;
      if (finalized != null) await _deleteFileSafe(finalized);
      await _cleanupOrphanedSegments(session.id, -1);
      // The terminal status says the recording is gone, so it is written only
      // once the audio actually is. A delete that refused used to be swallowed
      // and the row marked anyway, which left the file on disk with nothing
      // able to reach it; now the session stays in the list and the person can
      // ask again (ENG-521).
      if (!await sessionHoldsReachableAudio(session, paths)) {
        await sessionRepo.markDiscarded(session.id);
      }
    }
    await ref.read(recoveryCoordinatorProvider).refresh();
  }

  /// Parks a finished recording the person walked away from without saving,
  /// so it waits for them in the unsaved-recordings list instead of being
  /// deleted (ENG-518).
  ///
  /// **The status written here is `crashed`, and that is deliberate.** The name
  /// says failure; the state does not. Every sweep and every query already
  /// reads it as "there is anchored audio nobody saved" — which is exactly what
  /// a deliberate exit produces, and exactly what the startup sweep would
  /// promote this same row to on the next launch anyway. A status of its own
  /// would mean teaching `findCrashedSessions`, the sweep and the banner about
  /// it for no gain beyond a better name.
  ///
  /// The row keeps its anchor, so the invariant from ENG-420 holds: a session
  /// still pointing at durable audio never reaches a state no sweep looks at.
  /// The refresh is not decoration — without it the list only picks the
  /// recording up on the next launch, and from the person's side that is
  /// indistinguishable from having lost it.
  Future<void> keepForLater(String sessionId) async {
    await ref.read(recordingSessionRepositoryProvider).markCrashed(sessionId);
    await ref.read(recoveryCoordinatorProvider).refresh();
  }

  Future<RecordingResult?> save(String sessionId) async {
    if (kIsWeb) return null;

    final sessionRepo = ref.read(recordingSessionRepositoryProvider);
    final session = await sessionRepo.getById(sessionId);
    if (session == null) return null;

    final finished = await _finishedAudio(session);
    if (finished != null) return finished;

    final paths = sessionRepo.decodeSegmentPaths(session);
    final validPaths = <String>[];
    for (final p in paths) {
      if (await file_ops.fileExists(p)) {
        validPaths.add(p);
      }
    }
    if (validPaths.isEmpty) {
      // A session still holding finalized audio must not reach `discarded`:
      // no sweep queries that status, so the row — and the recording it points
      // at — would be unreachable from then on. Re-deriving is impossible
      // without segments, but the offer has to survive (ENG-420).
      if (session.finalizedAudioPath == null) {
        await sessionRepo.markDiscarded(session.id);
      }
      await ref.read(recoveryCoordinatorProvider).refresh();
      return null;
    }

    FinalizationOutcome? outcome;
    try {
      outcome = await ref
          .read(recordingFinalizationServiceProvider)
          .finalize(
            sessionId: session.id,
            segmentPaths: validPaths,
            totalDuration: Duration(
              milliseconds: (session.totalDurationSeconds * 1000).round(),
            ),
            deleteSources: false,
          );
    } catch (e, st) {
      _log.severe('finalize failed for ${session.id}', e, st);
    }

    if (outcome == null) {
      await ref.read(recoveryCoordinatorProvider).refresh();
      return null;
    }

    // markRecovered + segment cleanup are deferred to confirmRecovery(), which
    // runs only after the user confirms the save on the confirmation screen.
    // Until then the session stays `crashed` with its segments intact, so a
    // cancelled/abandoned confirmation re-surfaces in the recovery banner
    // instead of silently losing the recording.
    return outcome.result;
  }

  /// The audio this session already finished, when the row points at a file
  /// that is still on disk (ENG-420).
  ///
  /// Preferred over re-deriving because reconcatenating the sources costs
  /// minutes and lands on the same bytes — and in the sessions the startup
  /// sweep surfaces the sources are gone, so re-deriving cannot run at all.
  /// The anchor is only a pointer: discarding from the save form deletes the
  /// audio without touching the row, so a null here sends the caller back to
  /// the sources rather than failing. Resolved by basename in the current
  /// documents directory, because the iOS container moves on reinstall.
  Future<RecordingResult?> _finishedAudio(RecordingSession session) async {
    final anchor = session.finalizedAudioPath;
    if (anchor == null) return null;
    final resolved = await resolveRecordingPath(anchor);
    if (resolved == null) return null;
    return RecordingResult(
      filePath: resolved,
      durationSeconds:
          session.finalizedDurationSeconds ?? session.totalDurationSeconds,
      sessionId: session.id,
      // A degraded finalization anchors a .wav; the format rides along to the
      // upload's MIME type, so taking the m4a default would mislabel the file.
      format: resolved.toLowerCase().endsWith('.wav') ? 'wav' : 'm4a',
    );
  }

  /// Materializes the recovery decision after the user confirms the save on the
  /// confirmation screen: marks the session recovered and deletes its segment
  /// files, keeping [keepPath] (the finalized recording — which may itself be
  /// one of the segments in the single-segment/degraded cases).
  Future<void> confirmRecovery(
    String sessionId, {
    required String keepPath,
    required double durationSeconds,
  }) async {
    final sessionRepo = ref.read(recordingSessionRepositoryProvider);
    final session = await sessionRepo.getById(sessionId);
    if (session != null) {
      for (final p in sessionRepo.decodeSegmentPaths(session)) {
        if (p != keepPath) await _deleteFileSafe(p);
      }
    }
    // [keepPath] is the finalized recording, so the row can point at it
    // (ENG-420) instead of leaving a recovered session that finished with
    // audio look identical to one that never finalized.
    await sessionRepo.recoverWithFinalizedAudio(
      sessionId,
      filePath: keepPath,
      durationSeconds: durationSeconds,
    );
    await ref.read(recoveryCoordinatorProvider).refresh();
  }

  Future<void> _cleanupOrphanedSegments(
    String sessionId,
    int lastFinalizedIndex,
  ) async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final prefix = SegmentPaths.prefixFor(dir.path, sessionId);
      final entries = await dir.list().toList();
      for (final entry in entries) {
        if (entry is! File) continue;
        final index = SegmentPaths.parseIndex(entry.path, prefix);
        if (index == null) continue;
        if (index > lastFinalizedIndex) {
          try {
            await entry.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Best-effort delete: a discard must not blow up in the person's face. The
  /// failure is not silent any more, though — it is reported, and the caller
  /// decides what it means by asking whether the audio is still there.
  Future<void> _deleteFileSafe(String path) async {
    try {
      await ref.read(deleteFileProvider)(path);
    } catch (e, st) {
      ref.read(errorReporterProvider).reportError(e, st);
    }
  }
}
