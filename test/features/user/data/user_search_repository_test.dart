import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/core/observability/error_reporter.dart';
import 'package:oral_collector/features/user/data/user_search_repository.dart';

class _MockClient extends Mock implements AuthenticatedClient {}

void main() {
  late _MockClient client;
  late UserSearchRepository repo;

  setUp(() {
    client = _MockClient();
    repo = UserSearchRepository(
      client: client,
      reporter: const NoopErrorReporter(),
    );
  });

  void stubGet(String body, [int status = 200]) {
    when(
      () => client.get(any()),
    ).thenAnswer((_) async => http.Response(body, status));
  }

  test('returns the users parsed from a 200 array', () async {
    stubGet(
      '[{"id":"u1","email":"a@x.com","display_name":"Alice","avatar_url":null},'
      '{"id":"u2","email":"b@x.com","display_name":null,"avatar_url":"http://img/2"}]',
    );

    final results = await repo.search('al');

    expect(results.map((u) => u.id), ['u1', 'u2']);
    expect(results.first.email, 'a@x.com');
    expect(results.first.displayName, 'Alice');
    expect(results[1].avatarUrl, 'http://img/2');
  });

  test('skips a malformed element and keeps the good ones', () async {
    stubGet(
      '[{"id":"u1","email":"a@x.com","display_name":"Alice","avatar_url":null},'
      '{"id":42,"email":"bad@x.com"}]',
    );

    final results = await repo.search('al');

    expect(results.map((u) => u.id), ['u1']);
  });

  test('hits the search endpoint with the query URL-encoded', () async {
    stubGet('[]');

    await repo.search('a&b');

    verify(() => client.get('/api/users/search?q=a%26b')).called(1);
  });

  test('throws a catchable AppException on a non-2xx response', () async {
    stubGet('', 500);

    await expectLater(repo.search('al'), throwsA(isA<AppException>()));
  });
}
