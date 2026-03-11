import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/network/authenticated_client.dart';
import '../domain/repositories/recording_api_repository.dart';
import 'repositories/local_recording_repository.dart';
import 'repositories/recording_api_repository_impl.dart';

final recordingApiRepositoryProvider = Provider<RecordingApiRepository>((ref) {
  return RecordingApiRepositoryImpl(
    client: ref.watch(authenticatedClientProvider),
  );
});

final localRecordingRepositoryProvider = Provider<LocalRecordingRepository>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return LocalRecordingRepository(db);
});
