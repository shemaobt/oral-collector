import '../../../../core/database/app_database.dart';

const String kUnclassifiedGenreId = 'unclassified';

extension RecordingClassification on LocalRecording {
  bool get isUnclassified => genreId == kUnclassifiedGenreId;
  bool get isClassified => genreId != kUnclassifiedGenreId;
}
