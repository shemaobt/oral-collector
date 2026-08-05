import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/authenticated_client.dart';
import '../../../core/observability/error_reporter.dart';
import '../domain/repositories/genre_repository.dart';
import 'genre_cache.dart';
import 'repositories/genre_repository.dart';

final genreRepositoryProvider = Provider<GenreRepository>((ref) {
  return GenreRepositoryImpl(
    client: ref.watch(authenticatedClientProvider),
    reporter: ref.watch(errorReporterProvider),
  );
});

final genreCacheProvider = Provider<GenreCache>((ref) {
  return SharedPreferencesGenreCache();
});
