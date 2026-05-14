import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/platform/file_ops.dart' as file_ops;
import '../../data/providers.dart';
import '../../data/services/recovery_coordinator.dart';
import '../../data/services/segment_paths.dart';
import 'recording_session_notifier.dart';
import 'recording_session_state.dart';

final interruptedSessionsNotifierProvider =
    NotifierProvider<InterruptedSessionsNotifier, void>(
      InterruptedSessionsNotifier.new,
    );

class InterruptedSessionsNotifier extends Notifier<void> {
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

    final result = await ref.read(recordingFinalizationServiceProvider).finalize(
      sessionId: session.id,
      segmentPaths: validPaths,
      totalDuration: Duration(
        milliseconds: (session.totalDurationSeconds * 1000).round(),
      ),
    );
    await _cleanupOrphanedSegments(session.id, -1);
    await sessionRepo.markRecovered(session.id);
    await ref.read(recoveryCoordinatorProvider).refresh();
    return result;
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
