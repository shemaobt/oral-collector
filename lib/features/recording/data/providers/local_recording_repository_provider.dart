import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../repositories/local_recording_repository.dart';

final localRecordingRepositoryProvider =
    Provider<LocalRecordingRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalRecordingRepository(db);
});
