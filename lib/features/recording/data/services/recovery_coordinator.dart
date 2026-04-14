import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../providers.dart';

class RecoveryPrompt {
  const RecoveryPrompt({
    required this.sessionId,
    required this.minutes,
    required this.startedAt,
  });

  final String sessionId;
  final int minutes;
  final DateTime startedAt;
}

final pendingRecoveryProvider = StateProvider<RecoveryPrompt?>((_) => null);

class RecoveryCoordinator {
  RecoveryCoordinator(this._ref);

  final Ref _ref;

  Future<void> scanOnStartup() async {
    final repo = _ref.read(recordingSessionRepositoryProvider);
    final active = await repo.findActiveSessions();
    if (active.isEmpty) return;

    for (final session in active) {
      await repo.markCrashed(session.id);
    }

    final newest = active.reduce(
      (a, b) => a.startedAt.isAfter(b.startedAt) ? a : b,
    );

    if (_countSegments(newest) == 0) {
      return;
    }

    _ref.read(pendingRecoveryProvider.notifier).state = RecoveryPrompt(
      sessionId: newest.id,
      minutes: (newest.totalDurationSeconds / 60).floor(),
      startedAt: newest.startedAt,
    );
  }

  int _countSegments(RecordingSession session) {
    final repo = _ref.read(recordingSessionRepositoryProvider);
    return repo.decodeSegmentPaths(session).length;
  }
}

final recoveryCoordinatorProvider = Provider<RecoveryCoordinator>(
  (ref) => RecoveryCoordinator(ref),
);
