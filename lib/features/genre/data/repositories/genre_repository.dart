import '../../../../core/network/authenticated_client.dart';
import '../../../../core/network/response_decoder.dart';
import '../../../../core/observability/error_reporter.dart';
import '../../../../core/serialization/parse_list.dart';
import '../../domain/entities/genre.dart';
import '../../domain/repositories/genre_repository.dart';

class GenreRepositoryImpl implements GenreRepository {
  final AuthenticatedClient _client;
  final ErrorReporter _reporter;

  GenreRepositoryImpl({
    required AuthenticatedClient client,
    required ErrorReporter reporter,
  }) : _client = client,
       _reporter = reporter;

  @override
  Future<List<Genre>> listGenres() async {
    final response = await _client.get('/api/oc/genres');
    return parseList(
      decodeList(response),
      Genre.fromJson,
      context: 'listGenres',
      onSkip: _reporter.parseSkipSink(context: 'listGenres'),
    );
  }
}
