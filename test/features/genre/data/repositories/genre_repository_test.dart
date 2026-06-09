import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/features/genre/data/repositories/genre_repository.dart';

class _MockClient extends Mock implements AuthenticatedClient {}

void main() {
  late _MockClient client;
  late GenreRepositoryImpl repo;

  setUp(() {
    client = _MockClient();
    repo = GenreRepositoryImpl(client: client);
  });

  test('listGenres pula um genre malformado e retorna os válidos', () async {
    when(() => client.get('/api/oc/genres')).thenAnswer(
      (_) async => http.Response(
        '[{"id":"g-1","name":"Folktale"},{"name":"sem id"}]',
        200,
      ),
    );

    final result = await repo.listGenres();

    expect(result.map((g) => g.id).toList(), <String>['g-1']);
  });
}
