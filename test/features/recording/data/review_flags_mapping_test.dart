/// The server owns review state and the client displays it (ENG-374). These
/// tests follow `review_flags` across every hop it makes — API json, Drift row,
/// UI entity, and the copyWith the list notifier applies after a rename —
/// because a field carried by some hops and dropped by one arrives from the API
/// and vanishes before the screen.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/data/server_to_recording_entity.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/domain/entities/review_flag.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';

void main() {
  Map<String, dynamic> serverJson({Object? reviewFlags = _absent}) => {
    'id': 'r-1',
    'project_id': 'p-1',
    'genre_id': 'unclassified',
    'register_id': null,
    'storyteller_id': null,
    'title': 'Uma gravação',
    'description': 'curta',
    'duration_seconds': 12.5,
    'file_size_bytes': 2048,
    'format': 'm4a',
    'upload_status': 'uploaded',
    'cleaning_status': 'none',
    'recorded_at': '2026-01-02T03:04:05Z',
    if (!identical(reviewFlags, _absent)) 'review_flags': reviewFlags,
  };

  LocalRecordingEntity entityFrom(Map<String, dynamic> json) =>
      serverRecordingToEntity(ServerRecording.fromJson(json));

  test('review flags survive the trip from API json to the UI entity', () {
    final entity = entityFrom(
      serverJson(
        reviewFlags: [
          {'code': 'missing_classification', 'origin': 'system'},
          {'code': 'insufficient_description', 'origin': 'curator'},
        ],
      ),
    );

    expect(entity.reviewFlags, const [
      ReviewFlag(code: 'missing_classification', origin: 'system'),
      ReviewFlag(code: 'insufficient_description', origin: 'curator'),
    ]);
  });

  test('a server that does not send the field yet reads as no flags', () {
    expect(entityFrom(serverJson()).reviewFlags, isEmpty);
  });

  test('a server that sends the field as null reads as no flags', () {
    expect(entityFrom(serverJson(reviewFlags: null)).reviewFlags, isEmpty);
  });

  test('a flag code this version never heard of is still delivered', () {
    final entity = entityFrom(
      serverJson(
        reviewFlags: [
          {'code': 'awaiting_transcription', 'origin': 'system'},
        ],
      ),
    );

    expect(entity.reviewFlags.single.code, 'awaiting_transcription');
  });

  test(
    'one malformed flag is dropped without taking the good ones with it',
    () {
      final entity = entityFrom(
        serverJson(
          reviewFlags: [
            {'code': 'missing_classification', 'origin': 'system'},
            {'origin': 'system'},
            {'code': 'missing_storyteller', 'origin': 'system'},
          ],
        ),
      );

      expect(entity.reviewFlags.map((f) => f.code), [
        'missing_classification',
        'missing_storyteller',
      ]);
    },
  );

  test('renaming a recording does not drop what it still owes', () {
    final entity = entityFrom(
      serverJson(
        reviewFlags: [
          {'code': 'missing_storyteller', 'origin': 'system'},
        ],
      ),
    );

    final renamed = entity.copyWith(title: 'Outro título');

    expect(renamed.reviewFlags, entity.reviewFlags);
  });

  test('entities agree when their flags match by value, not by identity', () {
    final json = serverJson(
      reviewFlags: [
        {'code': 'insufficient_description', 'origin': 'system'},
      ],
    );

    expect(entityFrom(json), entityFrom(json));
    expect(entityFrom(json).hashCode, entityFrom(json).hashCode);
  });

  test('entities differ when the server changes which flags are open', () {
    final withFlag = entityFrom(
      serverJson(
        reviewFlags: [
          {'code': 'insufficient_description', 'origin': 'system'},
        ],
      ),
    );
    final cleared = entityFrom(serverJson(reviewFlags: const []));

    expect(withFlag, isNot(cleared));
  });
}

const Object _absent = Object();
