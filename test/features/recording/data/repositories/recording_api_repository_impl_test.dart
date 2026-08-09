import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/core/observability/error_reporter.dart';
import 'package:oral_collector/features/recording/data/repositories/recording_api_repository_impl.dart';
import 'package:oral_collector/features/recording/domain/entities/split_segment_request.dart';
import 'package:oral_collector/features/recording/domain/entities/update_recording_request.dart';

class _MockClient extends Mock implements AuthenticatedClient {}

void main() {
  late _MockClient client;
  late RecordingApiRepositoryImpl repo;

  setUp(() {
    client = _MockClient();
    repo = RecordingApiRepositoryImpl(
      client: client,
      reporter: const NoopErrorReporter(),
    );
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

  group('updateRecording', () {
    void stubPatch({int status = 200}) {
      when(
        () => client.patch(any(), body: any(named: 'body')),
      ).thenAnswer((_) async => http.Response('', status));
    }

    test('PATCHes the recording path with the request payload', () async {
      stubPatch();

      await repo.updateRecording(
        's-1',
        const UpdateRecordingRequest(
          title: 'New title',
          genreId: 'g-1',
          clearSecondary: true,
          durationSeconds: 3.5,
          fileSizeBytes: 99,
        ),
      );

      final captured = verify(
        () => client.patch(captureAny(), body: captureAny(named: 'body')),
      ).captured;
      expect(captured[0], '/api/oc/recordings/s-1');
      expect(captured[1], {
        'title': 'New title',
        'genre_id': 'g-1',
        'secondary_genre_id': null,
        'secondary_subcategory_id': null,
        'secondary_register_id': null,
        'duration_seconds': 3.5,
        'file_size_bytes': 99,
      });
    });

    test('reports success on 200', () async {
      stubPatch();

      final outcome = await repo.updateRecording(
        's-1',
        const UpdateRecordingRequest(title: 't'),
      );
      expect(outcome.success, isTrue);
    });

    test('reports failure on a non-200, non-error status', () async {
      stubPatch(status: 500);

      final outcome = await repo.updateRecording(
        's-1',
        const UpdateRecordingRequest(title: 't'),
      );
      expect(outcome.success, isFalse);
    });

    test('throws ForbiddenException on 403', () async {
      stubPatch(status: 403);

      await expectLater(
        repo.updateRecording('s-1', const UpdateRecordingRequest(title: 't')),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('throws ConflictException on 409', () async {
      // The backend deduplicates on (project_id, title): a rename onto a taken
      // title is rejected with 409. Returning false here would be indistinguish-
      // able from any other failure and callers would save locally anyway.
      stubPatch(status: 409);

      await expectLater(
        repo.updateRecording('s-1', const UpdateRecordingRequest(title: 't')),
        throwsA(isA<ConflictException>()),
      );
    });
  });
}
