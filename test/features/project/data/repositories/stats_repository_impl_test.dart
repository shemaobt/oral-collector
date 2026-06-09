import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/features/project/data/repositories/stats_repository_impl.dart';

class _MockClient extends Mock implements AuthenticatedClient {}

void main() {
  late _MockClient client;
  late StatsRepositoryImpl repo;

  setUp(() {
    client = _MockClient();
    repo = StatsRepositoryImpl(client: client);
  });

  void stubBody(Map<String, dynamic> body) {
    when(
      () => client.get(any()),
    ).thenAnswer((_) async => http.Response(jsonEncode(body), 200));
  }

  test('fetchGenreStats throws a catchable ParseException when a genre '
      'recording_count is not a num', () async {
    stubBody({
      'genres': [
        {'genre_id': 'g-1', 'duration_seconds': 1.0, 'recording_count': 'oops'},
      ],
      'subcategories': <dynamic>[],
    });

    await expectLater(
      repo.fetchGenreStats('p-1'),
      throwsA(
        isA<ParseException>().having(
          (e) => e.field,
          'field',
          'recording_count',
        ),
      ),
    );
  });

  test('fetchGenreStats throws a catchable ParseException when a subcategory '
      'recording_count is not a num', () async {
    stubBody({
      'genres': <dynamic>[],
      'subcategories': [
        {
          'genre_id': 'g-1',
          'subcategory_id': 's-1',
          'duration_seconds': 1.0,
          'recording_count': 'oops',
        },
      ],
    });

    await expectLater(
      repo.fetchGenreStats('p-1'),
      throwsA(
        isA<ParseException>().having(
          (e) => e.field,
          'field',
          'recording_count',
        ),
      ),
    );
  });

  test(
    'fetchGenreStats parses genre stats from a well-formed response',
    () async {
      stubBody({
        'genres': [
          {'genre_id': 'g-1', 'duration_seconds': 2.5, 'recording_count': 7},
        ],
        'subcategories': <dynamic>[],
      });

      final stats = await repo.fetchGenreStats('p-1');

      expect(stats['g-1']!.recordingCount, 7);
    },
  );
}
