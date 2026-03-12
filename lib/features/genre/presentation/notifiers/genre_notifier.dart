import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/errors/api_exception.dart';
import '../../data/providers.dart';
import '../../domain/repositories/genre_repository.dart';
import 'genre_state.dart';

final genreNotifierProvider = NotifierProvider<GenreNotifier, GenreState>(
  GenreNotifier.new,
);

class GenreNotifier extends Notifier<GenreState> {
  GenreRepository get _repo => ref.read(genreRepositoryProvider);

  @override
  GenreState build() => const GenreState();

  Future<void> fetchGenres() async {
    if (state.lastFetched != null && state.genres.isNotEmpty) return;
    state = state.copyWith(isLoading: true);
    try {
      final genres = await _repo.listGenres();
      state = GenreState(
        genres: genres,
        isLoading: false,
        lastFetched: DateTime.now(),
      );
    } on UnauthorizedException {
      state = state.copyWith(isLoading: false);
      ref.read(authNotifierProvider.notifier).handleUnauthorized();
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false);
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
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
