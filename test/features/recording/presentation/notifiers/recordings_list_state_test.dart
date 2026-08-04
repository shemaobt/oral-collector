import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recordings_list_state.dart';

LocalRecordingEntity _entity({
  required String id,
  String genreId = 'genre-1',
  String? registerId = 'reg-1',
  String? title,
  String? description,
  String uploadStatus = 'local',
}) => LocalRecordingEntity(
  id: id,
  projectId: 'proj-1',
  genreId: genreId,
  registerId: registerId,
  title: title,
  description: description,
  durationSeconds: 30,
  fileSizeBytes: 1024,
  format: 'm4a',
  localFilePath: '/tmp/$id.m4a',
  uploadStatus: uploadStatus,
  cleaningStatus: 'none',
  recordedAt: DateTime(2026, 1, 1),
  createdAt: DateTime(2026, 1, 1),
  retryCount: 0,
  uploadedBytes: 0,
);

void main() {
  group('RecordingsListState.filteredRecordings', () {
    test(
      'unclassified filter keeps only recordings missing genre or register',
      () {
        final classified = _entity(
          id: 'c',
          genreId: 'genre-1',
          registerId: 'reg-1',
        );
        final noGenre = _entity(
          id: 'g',
          genreId: 'unclassified',
          registerId: 'reg-1',
        );
        final noRegister = _entity(
          id: 'r',
          genreId: 'genre-1',
          registerId: null,
        );

        final state = RecordingsListState(
          recordings: [classified, noGenre, noRegister],
          selectedFilter: StatusFilter.unclassified,
        );

        expect(
          state.filteredRecordings.map((r) => r.id),
          unorderedEquals(['g', 'r']),
        );
      },
    );

    test('missing-description filter keeps only recordings without enough said '
        'about them', () {
      final described = _entity(
        id: 'd',
        description: 'Grandmother Ama retells the flood story at dusk.',
      );
      final tooShort = _entity(id: 's', description: 'a flood story');
      final blank = _entity(id: 'b', description: '   ');
      final absent = _entity(id: 'n');

      final state = RecordingsListState(
        recordings: [described, tooShort, blank, absent],
        selectedFilter: StatusFilter.missingDescription,
      );

      expect(
        state.filteredRecordings.map((r) => r.id),
        unorderedEquals(['s', 'b', 'n']),
      );
    });

    test('search query matches title and description, case-insensitively', () {
      final byTitle = _entity(id: 'a', title: 'Hello world');
      final byDescription = _entity(
        id: 'b',
        title: 'Nothing',
        description: 'has HELLO inside',
      );
      final unrelated = _entity(id: 'c', title: 'unrelated');

      final state = RecordingsListState(
        recordings: [byTitle, byDescription, unrelated],
        searchQuery: 'hello',
      );

      expect(state.filteredRecordings.map((r) => r.id), ['a', 'b']);
    });

    test('pending filter keeps a recording whose title clashed on upload', () {
      final conflict = _entity(id: 'x', uploadStatus: 'failed_conflict');
      final uploaded = _entity(id: 'u', uploadStatus: 'uploaded');

      final state = RecordingsListState(
        recordings: [conflict, uploaded],
        selectedFilter: StatusFilter.pending,
      );

      expect(state.filteredRecordings.map((r) => r.id), ['x']);
    });

    test('pending filter keeps a recording blocked on a short description', () {
      final blocked = _entity(id: 'd', uploadStatus: 'failed_description');
      final uploaded = _entity(id: 'u', uploadStatus: 'uploaded');

      final state = RecordingsListState(
        recordings: [blocked, uploaded],
        selectedFilter: StatusFilter.pending,
      );

      expect(state.filteredRecordings.map((r) => r.id), ['d']);
    });

    // These two left the upload queue on purpose (ENG-377), so this list is the
    // only place left that can show them. Dropping them here would take a
    // recording that still exists on the device off the screen entirely.
    test('pending filter keeps a recording that spent its retries', () {
      final exhausted = _entity(id: 'e', uploadStatus: 'failed_exhausted');
      final uploaded = _entity(id: 'u', uploadStatus: 'uploaded');

      final state = RecordingsListState(
        recordings: [exhausted, uploaded],
        selectedFilter: StatusFilter.pending,
      );

      expect(state.filteredRecordings.map((r) => r.id), ['e']);
    });

    test('pending filter keeps a recording whose audio file is gone', () {
      final lost = _entity(id: 'm', uploadStatus: 'failed_missing_file');
      final uploaded = _entity(id: 'u', uploadStatus: 'uploaded');

      final state = RecordingsListState(
        recordings: [lost, uploaded],
        selectedFilter: StatusFilter.pending,
      );

      expect(state.filteredRecordings.map((r) => r.id), ['m']);
    });
  });
}
