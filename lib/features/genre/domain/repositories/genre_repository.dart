import '../entities/genre.dart';

abstract class GenreRepository {
  Future<List<Genre>> listGenres();
}
