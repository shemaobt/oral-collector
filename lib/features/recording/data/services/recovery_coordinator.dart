import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/app_database.dart';
import '../providers.dart';
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

final interruptedSessionsProvider =
    StateProvider<List<InterruptedSession>>((_) => const []);

class RecoveryCoordinator {
  RecoveryCoordinator(this._ref, {WavHeaderRepair? wavRepair})
    : _wavRepair = wavRepair ?? const WavHeaderRepair();

  final Ref _ref;
  final WavHeaderRepair _wavRepair;

  Future<void> scanOnStartup() async {
    final repo = _ref.read(recordingSessionRepositoryProvider);
    final active = await repo.findActiveSessions();
    if (active.isNotEmpty) {
      debugPrint(
        'RecoveryCoordinator: scanOnStartup found ${active.length} active session(s)',
      );
    }
    for (final session in active) {
      await _repairInFlightSegments(session);
      await repo.markCrashed(session.id);
    }
    await refresh();
  }

  Future<void> _repairInFlightSegments(RecordingSession session) async {
    Directory dir;
    try {
      dir = await getApplicationDocumentsDirectory();
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

    final repo = _ref.read(recordingSessionRepositoryProvider);
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
    final crashed = await repo.findCrashedSessions();

    final result = <InterruptedSession>[];
    for (final session in crashed) {
      final segments = repo.decodeSegmentPaths(session);
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

    _ref.read(interruptedSessionsProvider.notifier).state = result;
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
