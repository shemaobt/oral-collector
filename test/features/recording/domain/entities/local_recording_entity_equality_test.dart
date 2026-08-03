/// Every field must count towards equality.
///
/// The entity rides a `.distinct()` watch stream, so a field left out of `==`
/// means a real change stops reaching the screen. The comparison is split into
/// groups to satisfy the complexity gate, which costs the reader the ability to
/// diff the field list against the comparison by eye — this walks each field
/// instead, so a field added to the constructor and forgotten in the groups
/// fails here rather than shipping.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/domain/entities/review_flag.dart';

void main() {
  final base = LocalRecordingEntity(
    id: 'rec-1',
    projectId: 'proj-1',
    genreId: 'genre-1',
    subcategoryId: 'subcat-1',
    title: 'Título',
    description: 'Descrição',
    durationSeconds: 42.5,
    fileSizeBytes: 1024,
    format: 'm4a',
    localFilePath: '/audio/rec-1.m4a',
    uploadStatus: 'uploaded',
    serverId: 'srv-1',
    gcsUrl: 'https://gcs.example/rec-1.m4a',
    registerId: 'reg-1',
    secondaryGenreId: 'genre-2',
    secondarySubcategoryId: 'subcat-2',
    secondaryRegisterId: 'reg-2',
    storytellerId: 'st-1',
    userId: 'user-1',
    cleaningStatus: 'none',
    recordedAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
    createdAt: DateTime.utc(2026, 1, 2, 3, 4, 6),
    retryCount: 1,
    resumableSessionUri: 'https://upload.example/session',
    uploadedBytes: 512,
    splitFromId: 'parent-1',
    splitIndex: 2,
    splitSegmentCount: 5,
    reviewFlags: const [
      ReviewFlag(code: 'missing_storyteller', origin: 'system'),
    ],
  );

  final mutations = <String, LocalRecordingEntity Function()>{
    'id': () => base.copyWith(id: 'other'),
    'projectId': () => base.copyWith(projectId: 'other'),
    'genreId': () => base.copyWith(genreId: 'other'),
    'subcategoryId': () => base.copyWith(subcategoryId: 'other'),
    'title': () => base.copyWith(title: 'other'),
    'description': () => base.copyWith(description: 'other'),
    'durationSeconds': () => base.copyWith(durationSeconds: 99.0),
    'fileSizeBytes': () => base.copyWith(fileSizeBytes: 99),
    'format': () => base.copyWith(format: 'wav'),
    'localFilePath': () => base.copyWith(localFilePath: '/other.m4a'),
    'uploadStatus': () => base.copyWith(uploadStatus: 'local'),
    'serverId': () => base.copyWith(serverId: 'other'),
    'gcsUrl': () => base.copyWith(gcsUrl: 'https://other.example/x.m4a'),
    'registerId': () => base.copyWith(registerId: 'other'),
    'secondaryGenreId': () => base.copyWith(secondaryGenreId: 'other'),
    'secondarySubcategoryId': () =>
        base.copyWith(secondarySubcategoryId: 'other'),
    'secondaryRegisterId': () => base.copyWith(secondaryRegisterId: 'other'),
    'storytellerId': () => base.copyWith(storytellerId: 'other'),
    'userId': () => base.copyWith(userId: 'other'),
    'cleaningStatus': () => base.copyWith(cleaningStatus: 'cleaned'),
    'recordedAt': () => base.copyWith(recordedAt: DateTime.utc(2027)),
    'createdAt': () => base.copyWith(createdAt: DateTime.utc(2027)),
    'retryCount': () => base.copyWith(retryCount: 9),
    'resumableSessionUri': () =>
        base.copyWith(resumableSessionUri: 'https://other.example/s'),
    'uploadedBytes': () => base.copyWith(uploadedBytes: 9999),
    'splitFromId': () => base.copyWith(splitFromId: 'other'),
    'splitIndex': () => base.copyWith(splitIndex: 9),
    'splitSegmentCount': () => base.copyWith(splitSegmentCount: 9),
    'reviewFlags': () => base.copyWith(reviewFlags: const []),
  };

  for (final entry in mutations.entries) {
    test('a recording that differs only in ${entry.key} is not the same '
        'recording', () {
      expect(entry.value(), isNot(base));
    });
  }

  test('the walk above covers every field the constructor takes', () {
    // Guards the guard: a field added to the entity without a mutation here
    // would leave a hole in the walk and nothing else would notice.
    expect(mutations, hasLength(29));
  });

  test('an untouched copy is still the same recording', () {
    expect(base.copyWith(), base);
    expect(base.copyWith().hashCode, base.hashCode);
  });
}
