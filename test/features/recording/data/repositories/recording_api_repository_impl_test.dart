import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/features/recording/data/repositories/recording_api_repository_impl.dart';

class _MockClient extends Mock implements AuthenticatedClient {}

void main() {
  late _MockClient client;
  late RecordingApiRepositoryImpl repo;

  setUp(() {
    client = _MockClient();
    repo = RecordingApiRepositoryImpl(client: client);
  });

  void stubBody(Map<String, dynamic> body) {
    when(
      () => client.post(any()),
    ).thenAnswer((_) async => http.Response(jsonEncode(body), 200));
  }

  group('clearStaleRecordings', () {
    test(
      'throws a catchable ParseException when "deleted" is not a num',
      () async {
        stubBody({'deleted': 'oops'});

        await expectLater(
          repo.clearStaleRecordings('p-1'),
          throwsA(
            isA<ParseException>().having((e) => e.field, 'field', 'deleted'),
          ),
        );
      },
    );

    test('returns 0 when "deleted" is absent', () async {
      stubBody({});

      expect(await repo.clearStaleRecordings('p-1'), 0);
    });

    test('returns the deleted count on success', () async {
      stubBody({'deleted': 5});

      expect(await repo.clearStaleRecordings('p-1'), 5);
    });
  });
}
