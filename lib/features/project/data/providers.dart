import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/authenticated_client.dart';
import '../domain/repositories/project_repository.dart';
import '../domain/repositories/stats_repository.dart';
import 'repositories/project_repository_impl.dart';
import 'repositories/stats_repository_impl.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepositoryImpl(client: ref.watch(authenticatedClientProvider));
});

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepositoryImpl(client: ref.watch(authenticatedClientProvider));
});
