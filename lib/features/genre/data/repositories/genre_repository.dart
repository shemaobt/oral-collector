import 'dart:convert';

import '../../../../core/network/authenticated_client.dart';
import '../../../../core/network/api_error_handler.dart';
import '../../domain/entities/genre.dart';
import '../../domain/repositories/genre_repository.dart';

class GenreRepositoryImpl implements GenreRepository {
  final AuthenticatedClient _client;

  GenreRepositoryImpl({required AuthenticatedClient client}) : _client = client;

  @override
  Future<List<Genre>> listGenres() async {
    final response = await _client.get('/api/oc/genres');
    guardResponse(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to list genres: ${response.body}');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => Genre.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
