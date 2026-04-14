import 'package:drift/drift.dart';

import 'connection.dart';

part 'app_database.g.dart';

class LocalRecordings extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get genreId => text()();
  TextColumn get subcategoryId => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get description => text().nullable()();
  RealColumn get durationSeconds => real().withDefault(const Constant(0.0))();
  IntColumn get fileSizeBytes => integer().withDefault(const Constant(0))();
  TextColumn get format => text().withDefault(const Constant('m4a'))();
  TextColumn get localFilePath => text()();
  TextColumn get uploadStatus => text().withDefault(const Constant('local'))();
  TextColumn get serverId => text().nullable()();
  TextColumn get gcsUrl => text().nullable()();
  TextColumn get registerId => text().nullable()();
  TextColumn get storytellerId => text().nullable()();
  TextColumn get userId => text().nullable()();
  TextColumn get cleaningStatus => text().withDefault(const Constant('none'))();
  DateTimeColumn get recordedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastRetryAt => dateTime().nullable()();
  TextColumn get resumableSessionUri => text().nullable()();
  IntColumn get uploadedBytes => integer().withDefault(const Constant(0))();
  TextColumn get md5Hash => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalGenres extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalSubcategories extends Table {
  TextColumn get id => text()();
  TextColumn get genreId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalStorytellers extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get name => text()();
  TextColumn get sex => text()();
  IntColumn get age => integer().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get dialect => text().nullable()();
  BoolColumn get externalAcceptanceConfirmed =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class RecordingSessions extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get genreId => text()();
  TextColumn get subcategoryId => text().nullable()();
  TextColumn get registerId => text().nullable()();
  TextColumn get storytellerId => text().nullable()();
  TextColumn get userId => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get lastCheckpointAt => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  RealColumn get totalDurationSeconds =>
      real().withDefault(const Constant(0.0))();
  TextColumn get segmentPathsJson => text().withDefault(const Constant('[]'))();
  BoolColumn get isPaused => boolean().withDefault(const Constant(false))();
  IntColumn get lastSegmentIndex => integer().withDefault(const Constant(-1))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    LocalRecordings,
    LocalGenres,
    LocalSubcategories,
    LocalStorytellers,
    RecordingSessions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(localRecordings, localRecordings.registerId);
      }
      if (from < 3) {
        await m.addColumn(localRecordings, localRecordings.resumableSessionUri);
        await m.addColumn(localRecordings, localRecordings.uploadedBytes);
      }
      if (from < 4) {
        await m.addColumn(localRecordings, localRecordings.md5Hash);
      }
      if (from < 5) {
        await m.addColumn(localRecordings, localRecordings.description);
      }
      if (from < 6) {
        await m.addColumn(localRecordings, localRecordings.storytellerId);
        await m.addColumn(localRecordings, localRecordings.userId);
        await m.createTable(localStorytellers);
      }
      if (from < 7) {
        await m.createTable(recordingSessions);
      }
    },
  );
}
