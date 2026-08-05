import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/entities/project_stats.dart';

/// The project's aggregate counters, for screens that only need to read them.
///
/// A [FutureProvider] rather than a notifier because nothing here is edited:
/// every writer of these numbers is on the server. Callers that cannot show a
/// number are expected to show none — the counters are best-effort and a screen
/// that works offline must not go blank because the aggregate did not answer.
final projectStatsProvider = FutureProvider.family<ProjectStats, String>(
  (ref, projectId) =>
      ref.read(projectRepositoryProvider).getProjectStats(projectId),
);
