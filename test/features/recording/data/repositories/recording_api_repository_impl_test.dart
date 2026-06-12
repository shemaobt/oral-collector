import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/features/recording/data/repositories/recording_api_repository_impl.dart';
import 'package:oral_collector/features/recording/domain/entities/split_segment_request.dart';

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

  group('splitRecording', () {
    void stubSplit(Object body, {int status = 200}) {
      when(() => client.post(any(), body: any(named: 'body'))).thenAnswer(
        (_) async =>
            http.Response(body is String ? body : jsonEncode(body), status),
      );
    }

    const segments = [
      SplitSegmentRequest(startSeconds: 0, endSeconds: 1, genreId: 'g-1'),
    ];

    test('returns the recording ids on success', () async {
      stubSplit({
        'recording_ids': ['r-1', 'r-2'],
      });

      final ids = await repo.splitRecording(
        serverId: 's-1',
        segments: segments,
      );

      expect(ids, ['r-1', 'r-2']);
    });

    test('returns empty when recording_ids is absent', () async {
      stubSplit({'ok': true});

      expect(
        await repo.splitRecording(serverId: 's-1', segments: segments),
        isEmpty,
      );
    });

    test(
      'throws a catchable ParseException when an id is not a String',
      () async {
        stubSplit({
          'recording_ids': ['r-1', 123],
        });

        await expectLater(
          repo.splitRecording(serverId: 's-1', segments: segments),
          throwsA(
            isA<ParseException>().having(
              (e) => e.field,
              'field',
              'recording_ids',
            ),
          ),
        );
      },
    );

    test('throws UnauthorizedException on 401', () async {
      stubSplit('', status: 401);

      await expectLater(
        repo.splitRecording(serverId: 's-1', segments: segments),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });
}
