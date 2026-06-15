import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  final Ref _ref;
  final WavHeaderRepair _wavRepair;
  final DirectoryResolver _directoryResolver;
  bool _disposed = false;

  Future<void> scanOnStartup() async {
    final repo = _ref.read(recordingSessionRepositoryProvider);
    try {
      final active = await repo.findActiveSessions();
      if (active.isNotEmpty) {
        debugPrint(
          'RecoveryCoordinator: scanOnStartup found ${active.length} active session(s)',
        );
      }
      for (final session in active) {
        await _repairInFlightSegments(session, repo);
        await repo.markCrashed(session.id);
      }
    } finally {
      await const RecordingActiveFlag().markInactive();
    }
    await _sweepCompletedWithOrphanSegments();
    await refresh();
  }

  /// Rescues legacy sessions marked `completed` before the markCompleted
  /// relocation: those rows can have orphan segment files on disk and no
  /// matching LocalRecording row, so the recovery banner never surfaces them
  /// unless we flip them back to `crashed`.
  Future<void> _sweepCompletedWithOrphanSegments() async {
    final sessionRepo = _ref.read(recordingSessionRepositoryProvider);
    final localRepo = _ref.read(localRecordingRepositoryProvider);

    final completed = await sessionRepo.findCompletedSessions();
    if (completed.isEmpty) return;

    Directory dir;
    try {
      dir = await _directoryResolver();
    } catch (_) {
      return;
    }

    final List<FileSystemEntity> entries;
    try {
      entries = await dir.list().toList();
    } catch (_) {
      return;
    }

    final localRecordings = await localRepo.getAllLocalRecordings();

    for (final session in completed) {
      final dot = '_${session.id}.';
      final under = '_${session.id}_';
      final saved = localRecordings.any(
        (lr) =>
            lr.localFilePath.contains(dot) || lr.localFilePath.contains(under),
      );
      if (saved) continue;

      final prefix = SegmentPaths.prefixFor(dir.path, session.id);
      final hasOrphans = entries.any((e) {
        if (e is! File) return false;
        return SegmentPaths.parseIndex(e.path, prefix) != null;
      });
      if (!hasOrphans) continue;

      debugPrint(
        'RecoveryCoordinator: sweep promoting orphan session ${session.id} '
        'from completed → crashed',
      );
      await _repairInFlightSegments(session, sessionRepo);
      await sessionRepo.markCrashed(session.id);
    }
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

class _OrphanedFile {
  const _OrphanedFile(this.file, this.index);
  final File file;
  final int index;
}
