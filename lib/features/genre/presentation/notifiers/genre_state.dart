import '../../domain/entities/genre.dart';

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
      lastFetched: clearLastFetched ? null : (lastFetched ?? this.lastFetched),
    );
  }
}
