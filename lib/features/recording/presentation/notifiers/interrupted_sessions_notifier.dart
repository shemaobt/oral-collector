import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/platform/file_ops.dart' as file_ops;
import '../../data/providers.dart';
import '../../data/services/recording_finalization_service.dart';
import '../../data/services/recovery_coordinator.dart';
import '../../data/services/segment_paths.dart';
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
      await sessionRepo.markDiscarded(session.id);
    }
    await ref.read(recoveryCoordinatorProvider).refresh();
  }

  Future<RecordingResult?> save(String sessionId) async {
    if (kIsWeb) return null;

    final sessionRepo = ref.read(recordingSessionRepositoryProvider);
    final session = await sessionRepo.getById(sessionId);
    if (session == null) return null;

    final paths = sessionRepo.decodeSegmentPaths(session);
    final validPaths = <String>[];
    for (final p in paths) {
      if (await file_ops.fileExists(p)) {
        validPaths.add(p);
      }
    }
    if (validPaths.isEmpty) {
      await sessionRepo.markDiscarded(session.id);
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

  Future<void> _deleteFileSafe(String path) async {
    try {
      await file_ops.deleteFile(path);
    } catch (_) {}
  }
}
