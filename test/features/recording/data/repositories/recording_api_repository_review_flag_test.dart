/// The pendency filter has to survive the trip to the query string (ENG-381).
///
/// Every layer above this one can be green while the parameter never reaches
/// the server under the name it expects: `review_flag` takes one code out of a
/// closed set and answers 422 to anything else, so a typo in the key or the
/// value is a production failure with the whole suite passing.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/core/observability/error_reporter.dart';
import 'package:oral_collector/features/recording/data/repositories/recording_api_repository_impl.dart';
import 'package:oral_collector/features/recording/domain/entities/review_pendency.dart';

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

  test('omits the review flag parameter when no pendency is chosen', () async {
    await repo.listRecordings('p-1');

    expect(requested.queryParameters.containsKey('review_flag'), isFalse);
  });

  test('sends an empty review flag as no filter at all', () async {
    // An empty string is not a member of the server's closed set, so passing
    // it through would turn "no filter" into a 422.
    await repo.listRecordings('p-1', reviewFlag: '');

    expect(requested.queryParameters.containsKey('review_flag'), isFalse);
  });

  test('sends every pendency the app can filter by under the name the server '
      'knows', () async {
    // Driven off the enum rather than three literals: a kind added without a
    // wire code would fail here instead of at the first 422 in the field.
    for (final kind in PendencyKind.values) {
      await repo.listRecordings('p-1', reviewFlag: reviewFlagCodeFor(kind));

      expect(requested.queryParameters['review_flag'], reviewFlagCodeFor(kind));
    }
  });

  test('keeps the review flag alongside the other filters', () async {
    await repo.listRecordings(
      'p-1',
      reviewFlag: 'missing_storyteller',
      userId: 'u-1',
      title: 'My Recording',
    );

    expect(requested.queryParameters['review_flag'], 'missing_storyteller');
    expect(requested.queryParameters['user_id'], 'u-1');
    expect(requested.queryParameters['title'], 'My Recording');
  });
}
