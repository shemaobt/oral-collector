import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';

LocalRecordingEntity _entity() => LocalRecordingEntity(
  id: 'r1',
  projectId: 'proj-1',
  genreId: 'genre-1',
  title: 'Original',
  durationSeconds: 30,
  fileSizeBytes: 1024,
  format: 'm4a',
  localFilePath: '/tmp/r1.m4a',
  uploadStatus: 'local',
  serverId: 'srv-1',
  cleaningStatus: 'none',
  recordedAt: DateTime(2026, 1, 1),
  createdAt: DateTime(2026, 1, 1),
  retryCount: 0,
  uploadedBytes: 0,
);

void main() {
  group('LocalRecordingEntity.copyWith', () {
    test('replaces the given field and preserves every other field', () {
      final updated = _entity().copyWith(title: 'Renamed');

      expect(updated.title, 'Renamed');
      expect(updated.id, 'r1');
      expect(updated.serverId, 'srv-1');
      expect(updated.uploadStatus, 'local');
      expect(updated.durationSeconds, 30);
    });

    test('passing null to a nullable field clears it', () {
      final cleared = _entity().copyWith(serverId: null);

      expect(cleared.serverId, isNull);
      expect(cleared.title, 'Original', reason: 'omitted fields are preserved');
    });

    test('with no arguments returns an equal entity', () {
      final original = _entity();

      expect(original.copyWith(), original);
    });
  });
}
