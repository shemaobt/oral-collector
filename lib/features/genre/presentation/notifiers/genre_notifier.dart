import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/observability/error_reporter.dart';
import '../../data/genre_cache.dart';
import '../../data/providers.dart';
import '../../domain/repositories/genre_repository.dart';
import 'genre_state.dart';

final genreNotifierProvider = NotifierProvider<GenreNotifier, GenreState>(
  GenreNotifier.new,
);

class GenreNotifier extends Notifier<GenreState> {
  GenreRepository get _repo => ref.read(genreRepositoryProvider);
  GenreCache get _cache => ref.read(genreCacheProvider);

  @override
  GenreState build() {
    _hydrateFromCache();
    return const GenreState();
  }

  Future<void> _hydrateFromCache() async {
    final cached = await _cache.read();
    if (cached == null) return;
    // A completed fetch is authoritative: never let a late hydration clobber it.
    if (state.lastFetched != null) return;
    state = state.copyWith(genres: cached);
  }

  Future<void> fetchGenres() async {
    if (state.lastFetched != null && state.genres.isNotEmpty) return;
    state = state.copyWith(isLoading: true);
    try {
      final genres = await _repo.listGenres();
      await _cache.write(genres);
      state = GenreState(
        genres: genres,
        isLoading: false,
        lastFetched: DateTime.now(),
      );
    } on UnauthorizedException {
      state = state.copyWith(isLoading: false);
      // Fire-and-forget: handleUnauthorized pode propagar uma falha transitória
      // de refresh (ENG-141); aqui ela é ignorada (sessão preservada). Só
      // Exceptions, não Errors, para não mascarar bugs.
      ref
          .read(authNotifierProvider.notifier)
          .handleUnauthorized()
          .catchError((_) => false, test: (e) => e is Exception);
    } on Exception catch (e, st) {
      state = state.copyWith(isLoading: false);
      ref.read(errorReporterProvider).reportError(e, st);
      rethrow;
    }
  }

  String? getGenreName(String id) {
    return state.genres.where((g) => g.id == id).firstOrNull?.name;
  }

  String? getSubcategoryName(String id) {
    for (final genre in state.genres) {
      final sub = genre.subcategories.where((s) => s.id == id).firstOrNull;
      if (sub != null) return sub.name;
    }
    return null;
  }

  void invalidate() {
    state = state.copyWith(clearLastFetched: true, genres: const []);
  }
}
