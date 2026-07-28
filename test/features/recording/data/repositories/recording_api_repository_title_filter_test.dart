import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/core/observability/error_reporter.dart';
import 'package:oral_collector/features/recording/data/repositories/recording_api_repository_impl.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late Uri requested;
  late RecordingApiRepositoryImpl repo;

  setUp(() {
    final storage = _MockSecureStorage();
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => 'test-token');
    final httpClient = MockClient((request) async {
      requested = request.url;
      return http.Response('[]', 200);
    });
    repo = RecordingApiRepositoryImpl(
      client: AuthenticatedClient(client: httpClient, storage: storage),
      reporter: const NoopErrorReporter(),
    );
  });

  test('omits the title parameter when no title is given', () async {
    await repo.listRecordings('p-1');

    expect(requested.queryParameters.containsKey('title'), isFalse);
  });

  test('sends the title as a query parameter', () async {
    await repo.listRecordings('p-1', title: 'My Recording');

    expect(requested.queryParameters['title'], 'My Recording');
  });

  test('percent-encodes a title containing query metacharacters', () async {
    await repo.listRecordings('p-1', title: 'a&b=c d?e');

    // Round-trip through the parsed query: an unencoded '&' or '=' would split
    // into extra parameters instead of surviving as one title.
    expect(requested.queryParameters['title'], 'a&b=c d?e');
    expect(requested.queryParameters.keys, isNot(contains('b')));
  });

  test('percent-encodes other filter values too', () async {
    await repo.listRecordings('p-1', userId: 'u&1', storytellerId: 's=2');

    expect(requested.queryParameters['user_id'], 'u&1');
    expect(requested.queryParameters['storyteller_id'], 's=2');
  });
}
