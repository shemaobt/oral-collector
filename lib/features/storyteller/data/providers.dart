import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/network/authenticated_client.dart';
import '../domain/repositories/storyteller_repository.dart';
import 'repositories/local_storyteller_repository.dart';
import 'repositories/storyteller_api_repository_impl.dart';

final storytellerApiRepositoryProvider = Provider<StorytellerRepository>((ref) {
  return StorytellerApiRepositoryImpl(
    client: ref.watch(authenticatedClientProvider),
  );
});

final localStorytellerRepositoryProvider = Provider<LocalStorytellerRepository>(
  (ref) {
    return LocalStorytellerRepository(ref.watch(appDatabaseProvider));
  },
);
