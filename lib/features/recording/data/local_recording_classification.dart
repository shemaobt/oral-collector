import '../../../core/database/app_database.dart';
import '../domain/entities/classification.dart';

extension RecordingClassification on LocalRecording {
  bool get hasGenre => recordingHasGenre(genreId);
  bool get hasRegister => recordingHasRegister(registerId);
  bool get isUnclassified =>
      recordingIsUnclassified(genreId: genreId, registerId: registerId);
  bool get isClassified =>
      recordingIsClassified(genreId: genreId, registerId: registerId);
  bool get hasSecondaryGenre => recordingHasSecondaryGenre(secondaryGenreId);
  bool get hasSecondaryRegister =>
      recordingHasSecondaryRegister(secondaryRegisterId);
  bool get hasSecondary => recordingHasSecondary(
    secondaryGenreId: secondaryGenreId,
    secondaryRegisterId: secondaryRegisterId,
  );
}
