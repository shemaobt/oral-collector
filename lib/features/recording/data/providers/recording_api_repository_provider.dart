import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/recording_api_repository.dart';

final recordingApiRepositoryProvider = Provider<RecordingApiRepository>(
  (_) => RecordingApiRepository(),
);
