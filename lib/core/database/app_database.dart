import 'package:drift/drift.dart';

import 'connection.dart';
import 'schema_versions.dart';

part 'app_database.g.dart';

@TableIndex(
  name: 'idx_recordings_project_recorded',
  columns: {#projectId, #recordedAt},
)
@TableIndex(
  name: 'idx_recordings_status_recorded',
  columns: {#uploadStatus, #recordedAt},
)
@TableIndex(name: 'idx_recordings_server_id', columns: {#serverId})
@TableIndex(name: 'idx_recordings_storyteller_id', columns: {#storytellerId})
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
  TextColumn get secondaryGenreId => text().nullable()();
  TextColumn get secondarySubcategoryId => text().nullable()();
  TextColumn get secondaryRegisterId => text().nullable()();
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
  TextColumn get splitFromId => text().nullable()();
  IntColumn get splitIndex => integer().nullable()();
  IntColumn get splitSegmentCount => integer().nullable()();

  /// Server-reported review flags, JSON-encoded (ENG-374). Stored so a device
  /// reading its local rows offline still knows what each recording owes;
  /// encoded as text like `RecordingSessions.segmentPathsJson` rather than
  /// through a converter, which is the existing shape for a list in this schema.
  TextColumn get reviewFlagsJson => text().withDefault(const Constant('[]'))();

  /// Metadata-outbox state (ENG-403): which fields this device edited while the
  /// server was unreachable, and the retry bookkeeping for pushing them.
  ///
  /// Columns on the recording rather than a queue table because the relation is
  /// 1:1 — a recording owes at most one set of fields — and because the values
  /// are not stored here at all: the row already holds the desired state, so
  /// [pendingMetadataJson] only names the fields the drain must read back off
  /// it. Successive offline edits therefore collapse instead of replaying.
  ///
  /// [metadataRetryCount] / [metadataLastRetryAt] mirror the upload queue's
  /// `retryCount` / `lastRetryAt` and feed the same backoff.
  TextColumn get metadataSyncStatus =>
      text().withDefault(const Constant('synced'))();
  TextColumn get pendingMetadataJson =>
      text().withDefault(const Constant('[]'))();
  IntColumn get metadataRetryCount =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get metadataLastRetryAt => dateTime().nullable()();

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

@TableIndex(name: 'idx_storytellers_project_id', columns: {#projectId})
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
  TextColumn get serverId => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastRetryAt => dateTime().nullable()();

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
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (m) => m.createAll(), onUpgrade: _upgrade);
}

// Each callback migrates exactly one version using that version's schema
// snapshot (from schema_versions.dart), so createTable/addColumn see each table
// as it existed at that version — local_storytellers is created at its pre-sync
// v6 shape, then the sync columns are added at v10. Kept top-level so a step
// can't reach the current database definition by mistake.
final OnUpgrade _upgrade = stepByStep(
  from1To2: (m, schema) async {
    await m.addColumn(
      schema.localRecordings,
      schema.localRecordings.registerId,
    );
  },
  from2To3: (m, schema) async {
    await m.addColumn(
      schema.localRecordings,
      schema.localRecordings.resumableSessionUri,
    );
    await m.addColumn(
      schema.localRecordings,
      schema.localRecordings.uploadedBytes,
    );
  },
  from3To4: (m, schema) async {
    await m.addColumn(schema.localRecordings, schema.localRecordings.md5Hash);
  },
  from4To5: (m, schema) async {
    await m.addColumn(
      schema.localRecordings,
      schema.localRecordings.description,
    );
  },
  from5To6: (m, schema) async {
    await m.addColumn(
      schema.localRecordings,
      schema.localRecordings.storytellerId,
    );
    await m.addColumn(schema.localRecordings, schema.localRecordings.userId);
    await m.createTable(schema.localStorytellers);
  },
  from6To7: (m, schema) async {
    await m.createTable(schema.recordingSessions);
  },
  from7To8: (m, schema) async {
    await m.addColumn(
      schema.localRecordings,
      schema.localRecordings.secondaryGenreId,
    );
    await m.addColumn(
      schema.localRecordings,
      schema.localRecordings.secondarySubcategoryId,
    );
    await m.addColumn(
      schema.localRecordings,
      schema.localRecordings.secondaryRegisterId,
    );
  },
  from8To9: (m, schema) async {
    await m.addColumn(
      schema.localRecordings,
      schema.localRecordings.splitFromId,
    );
    await m.addColumn(
      schema.localRecordings,
      schema.localRecordings.splitIndex,
    );
    await m.addColumn(
      schema.localRecordings,
      schema.localRecordings.splitSegmentCount,
    );
  },
  from9To10: (m, schema) async {
    await m.addColumn(
      schema.localStorytellers,
      schema.localStorytellers.serverId,
    );
    await m.addColumn(
      schema.localStorytellers,
      schema.localStorytellers.syncStatus,
    );
    await m.addColumn(
      schema.localStorytellers,
      schema.localStorytellers.retryCount,
    );
    await m.addColumn(
      schema.localStorytellers,
      schema.localStorytellers.lastRetryAt,
    );
  },
  from10To11: (m, schema) async {
    await m.create(schema.idxRecordingsProjectRecorded);
    await m.create(schema.idxRecordingsStatusRecorded);
    await m.create(schema.idxRecordingsServerId);
    await m.create(schema.idxRecordingsStorytellerId);
    await m.create(schema.idxStorytellersProjectId);
  },
  from11To12: (m, schema) async {
    await m.addColumn(
      schema.localRecordings,
      schema.localRecordings.reviewFlagsJson,
    );
  },
  from12To13: (m, schema) async {
    await m.addColumn(
      schema.localRecordings,
      schema.localRecordings.metadataSyncStatus,
    );
    await m.addColumn(
      schema.localRecordings,
      schema.localRecordings.pendingMetadataJson,
    );
    await m.addColumn(
      schema.localRecordings,
      schema.localRecordings.metadataRetryCount,
    );
    await m.addColumn(
      schema.localRecordings,
      schema.localRecordings.metadataLastRetryAt,
    );
  },
);
