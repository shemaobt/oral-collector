import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class LocalRecordings extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get genreId => text()();
  TextColumn get subcategoryId => text().nullable()();
  TextColumn get title => text().nullable()();
  RealColumn get durationSeconds => real().withDefault(const Constant(0.0))();
  IntColumn get fileSizeBytes => integer().withDefault(const Constant(0))();
  TextColumn get format => text().withDefault(const Constant('m4a'))();
  TextColumn get localFilePath => text()();
  TextColumn get uploadStatus =>
      text().withDefault(const Constant('local'))();
  TextColumn get serverId => text().nullable()();
  TextColumn get gcsUrl => text().nullable()();
  TextColumn get cleaningStatus =>
      text().withDefault(const Constant('none'))();
  DateTimeColumn get recordedAt => dateTime()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastRetryAt => dateTime().nullable()();

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

@DriftDatabase(tables: [LocalRecordings, LocalGenres, LocalSubcategories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'oral_collector.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
