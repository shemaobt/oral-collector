import '../../../../core/database/app_database.dart';

const String kUnclassifiedGenreId = 'unclassified';

extension RecordingClassification on LocalRecording {
  bool get hasGenre => genreId != kUnclassifiedGenreId;
  bool get hasRegister => registerId != null && registerId!.isNotEmpty;
  bool get isUnclassified => !hasGenre || !hasRegister;
  bool get isClassified => hasGenre && hasRegister;

  bool get hasSecondaryGenre =>
      secondaryGenreId != null &&
      secondaryGenreId!.isNotEmpty &&
      secondaryGenreId != kUnclassifiedGenreId;

  bool get hasSecondaryRegister =>
      secondaryRegisterId != null && secondaryRegisterId!.isNotEmpty;

  bool get hasSecondary => hasSecondaryGenre || hasSecondaryRegister;
}
