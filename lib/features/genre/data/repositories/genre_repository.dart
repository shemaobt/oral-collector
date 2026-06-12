import '../../../../core/network/authenticated_client.dart';
import '../../../../core/network/response_decoder.dart';
import '../../../../core/serialization/parse_list.dart';
import '../../domain/entities/genre.dart';
import '../../domain/repositories/genre_repository.dart';

class GenreRepositoryImpl implements GenreRepository {
  final AuthenticatedClient _client;

  GenreRepositoryImpl({required AuthenticatedClient client}) : _client = client;

  @override
  Future<List<Genre>> listGenres() async {
    final response = await _client.get('/api/oc/genres');
    return parseList(
      decodeList(response),
      Genre.fromJson,
      context: 'listGenres',
    );
  }
}
