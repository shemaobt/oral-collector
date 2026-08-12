import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/platform/recording_active_flag.dart';
import '../providers.dart';
import '../repositories/recording_session_repository.dart';
import 'segment_paths.dart';
import 'wav_header_repair.dart';

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

typedef DirectoryResolver = Future<Directory> Function();

class RecoveryCoordinator {
  RecoveryCoordinator(
    this._ref, {
    WavHeaderRepair? wavRepair,
    DirectoryResolver? directoryResolver,
  }) : _wavRepair = wavRepair ?? const WavHeaderRepair(),
       _directoryResolver =
           directoryResolver ?? getApplicationDocumentsDirectory {
    _ref.onDispose(() => _disposed = true);
  }

  static final _log = Logger('RecoveryCoordinator');

  final Ref _ref;
  final WavHeaderRepair _wavRepair;
  final DirectoryResolver _directoryResolver;
  bool _disposed = false;

  Future<void> scanOnStartup() async {
    final repo = _ref.read(recordingSessionRepositoryProvider);
    try {
      final active = await repo.findActiveSessions();
      if (active.isNotEmpty) {
        _log.info('scanOnStartup found ${active.length} active session(s)');
      }
      for (final session in active) {
        await _repairInFlightSegments(session, repo);
        await repo.markCrashed(session.id);
      }
    } finally {
      await const RecordingActiveFlag().markInactive();
    }
    await _sweepFinishedSessionsWithUnsavedAudio();
    await refresh();
  }

  /// Surfaces sessions that finished with audio the user never saved.
  ///
  /// The question asked is "did this session produce audio that nothing
  /// saved?", and both halves are answered from the database, so the answer no
  /// longer depends on whether the fire-and-forget source deletions inside
  /// `finalize()` have landed yet (ENG-420). Sessions whose anchor names a file
  /// that is already gone are left alone: offering a recovery that cannot
  /// succeed is worse than offering nothing.
  Future<void> _sweepFinishedSessionsWithUnsavedAudio() async {
    final sessionRepo = _ref.read(recordingSessionRepositoryProvider);
    final localRepo = _ref.read(localRecordingRepositoryProvider);

    final finished = await sessionRepo.findFinishedSessions();
    if (finished.isEmpty) return;

    Directory dir;
    try {
      dir = await _directoryResolver();
    } catch (_) {
      return;
    }

    final localRecordings = await localRepo.getAllLocalRecordings();

    // Only the pre-v14 fallback needs the directory listing, so a listing that
    // fails must not suppress the rows that are decidable from the row itself.
    List<FileSystemEntity>? entries;
    Future<List<FileSystemEntity>> listEntries() async {
      try {
        return entries ??= await dir.list().toList();
      } catch (_) {
        return entries ??= const <FileSystemEntity>[];
      }
    }

    for (final session in finished) {
      final dot = '_${session.id}.';
      final under = '_${session.id}_';
      final saved = localRecordings.any(
        (lr) =>
            lr.localFilePath.contains(dot) || lr.localFilePath.contains(under),
      );
      if (saved) continue;

      if (!await _hasUnsavedAudio(session, dir, listEntries)) continue;

      _log.info(
        'sweep promoting session ${session.id} from ${session.status} → '
        'crashed: finalized audio with no saved recording',
      );
      await _repairInFlightSegments(session, sessionRepo);
      await sessionRepo.markCrashed(session.id);
    }
  }

  /// An anchored session is judged by its anchor — the file has to actually be
  /// there, because discarding from the save form deletes the audio without
  /// touching the row. Rows without an anchor fall back to the old disk scan:
  /// they either predate schema v14, or they reached their status before
  /// finalization ran (`recoverSessionFromDisk` marks a row recovered up
  /// front). That fallback can go once no supported upgrade path can still be
  /// carrying pre-v14 sessions and no path can mark a session finished before
  /// it has audio.
  Future<bool> _hasUnsavedAudio(
    RecordingSession session,
    Directory dir,
    Future<List<FileSystemEntity>> Function() listEntries,
  ) async {
    final anchor = session.finalizedAudioPath;
    if (anchor != null) return _anchoredAudioExists(anchor, dir);

    final prefix = SegmentPaths.prefixFor(dir.path, session.id);
    return (await listEntries()).any((e) {
      if (e is! File) return false;
      return SegmentPaths.parseIndex(e.path, prefix) != null;
    });
  }

  /// Same reason [resolveRecordingPath] exists: the documents container moves
  /// on reinstall/restore, so an absolute path stored earlier stops resolving
  /// while the file itself is still there. Reading the anchor literally would
  /// declare every such session audio-less and drop it.
  Future<bool> _anchoredAudioExists(String anchor, Directory dir) async {
    if (await File(anchor).exists()) return true;
    return File('${dir.path}/${p.basename(anchor)}').exists();
  }

  Future<void> _repairInFlightSegments(
    RecordingSession session,
    RecordingSessionRepository repo,
  ) async {
    Directory dir;
    try {
      dir = await _directoryResolver();
    } catch (_) {
      return;
    }

    final prefix = SegmentPaths.prefixFor(dir.path, session.id);
    final List<FileSystemEntity> entries;
    try {
      entries = await dir.list().toList();
    } catch (_) {
      return;
    }

    final candidates = <_OrphanedFile>[];
    for (final entry in entries) {
      if (entry is! File) continue;
      final index = SegmentPaths.parseIndex(entry.path, prefix);
      if (index == null) continue;
      if (index <= session.lastSegmentIndex) continue;
      candidates.add(_OrphanedFile(entry, index));
    }
    candidates.sort((a, b) => a.index.compareTo(b.index));

    if (candidates.isEmpty) return;

    for (final candidate in candidates) {
      final result = await _wavRepair.repair(candidate.file.path);
      if (result != null && result.duration > Duration.zero) {
        await repo.appendSegment(
          session.id,
          candidate.file.path,
          result.duration.inMilliseconds / 1000.0,
        );
      } else {
        try {
          await candidate.file.delete();
        } catch (_) {}
      }
    }
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
        // ran). Repair + attach before declaring the session lost.
        await _repairInFlightSegments(session, repo);
        final reloaded = await repo.getById(session.id);
        if (reloaded != null) {
          session = reloaded;
          segments = repo.decodeSegmentPaths(session);
        }
      }

      if (segments.isEmpty) {
        // Same invariant as the save path: a row that still points at
        // finalized audio never goes to a status no sweep looks at, even
        // though it has no segments to offer a recovery from (ENG-420).
        if (session.finalizedAudioPath == null) {
          await repo.markDiscarded(session.id);
        }
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

class _OrphanedFile {
  const _OrphanedFile(this.file, this.index);
  final File file;
  final int index;
}
