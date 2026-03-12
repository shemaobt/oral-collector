import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/authenticated_client.dart';
import '../../recording/data/providers.dart';
import '../domain/repositories/connectivity_service.dart';
import '../domain/repositories/sync_engine.dart';
import 'repositories/connectivity_service.dart';
import 'repositories/sync_engine.dart';
import 'services/background_sync_service.dart';

final connectivityServiceProvider = Provider<ConnectivityService>(
  (_) => ConnectivityServiceImpl(),
);

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final recordingRepo = ref.watch(localRecordingRepositoryProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final client = ref.watch(authenticatedClientProvider);
  return SyncEngineImpl(
    recordingRepo: recordingRepo,
    connectivity: connectivity,
    client: client,
  );
});

final backgroundSyncServiceProvider = Provider<BackgroundSyncService>(
  (_) => BackgroundSyncService(),
);
