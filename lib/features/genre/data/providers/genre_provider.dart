import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/genre.dart';
import '../repositories/genre_repository.dart';

// --- State ---

class GenreState {
  final List<Genre> genres;
  final bool isLoading;
  final DateTime? lastFetched;

  const GenreState({
    this.genres = const [],
    this.isLoading = false,
    this.lastFetched,
  });

  GenreState copyWith({
    List<Genre>? genres,
    bool? isLoading,
    DateTime? lastFetched,
    bool clearLastFetched = false,
  }) {
    return GenreState(
      genres: genres ?? this.genres,
      isLoading: isLoading ?? this.isLoading,
      lastFetched:
          clearLastFetched ? null : (lastFetched ?? this.lastFetched),
    );
  }
}

// --- Providers ---

final genreRepositoryProvider = Provider<GenreRepository>(
  (_) => GenreRepository(),
);

final genreNotifierProvider =
    NotifierProvider<GenreNotifier, GenreState>(GenreNotifier.new);

// --- Notifier ---

class GenreNotifier extends Notifier<GenreState> {
  GenreRepository get _repo => ref.read(genreRepositoryProvider);

  @override
  GenreState build() {
    return const GenreState();
  }

  /// Fetch all genres with subcategories. Uses in-memory cache if available.
  Future<void> fetchGenres() async {
    // Skip if already cached
    if (state.lastFetched != null && state.genres.isNotEmpty) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final genres = await _repo.listGenres();
      state = GenreState(
        genres: genres,
        isLoading: false,
        lastFetched: DateTime.now(),
      );
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false);
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Get genre name by ID, or null if not found.
  String? getGenreName(String id) {
    final genre = state.genres.where((g) => g.id == id).firstOrNull;
    return genre?.name;
  }

  /// Get subcategory name by ID, searching across all genres.
  String? getSubcategoryName(String id) {
    for (final genre in state.genres) {
      final sub = genre.subcategories.where((s) => s.id == id).firstOrNull;
      if (sub != null) return sub.name;
    }
    return null;
  }

  /// Invalidate cache and force refetch on next fetchGenres() call.
  void invalidate() {
    state = state.copyWith(
      clearLastFetched: true,
      genres: const [],
    );
  }
}
