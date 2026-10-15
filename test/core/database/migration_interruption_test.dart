// Durability tests for the upgrade path: a migration that dies halfway must
// leave a database that still opens on the next boot, with its rows intact.
//
// Unlike migration_test.dart, which validates the *shape* the migration
// produces, these operate the database only from the outside — seed a file at
// an old version, kill the migration mid-flight, reopen the same file and ask
// whether it is usable. Nothing here asserts which statements ran, whether a
// transaction exists, or in what order columns were added. See ENG-425.
library;

import 'dart:io';

import 'package:drift/drift.dart'
    show
        ApplyInterceptor,
        OpeningDetails,
        QueryExecutor,
        QueryExecutorUser,
        QueryInterceptor,
        Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:path/path.dart' as p;

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v12.dart' as v12;

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('eng425_migration');
    dbFile = File(p.join(tempDir.path, 'oral_collector.sqlite'));
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'a database whose migration was killed inside one step still opens',
    () async {
      await _seedAtV12(dbFile);

      // v12 -> v13 adds four columns to local_recordings; dying on the second
      // one leaves the first written to the file, which is what a process
      // killed mid-step leaves behind.
      await _killMigration(dbFile, at: _nthAddColumnOn('local_recordings', 2));

      final db = AppDatabase.forTesting(NativeDatabase(dbFile));
      try {
        expect(await _userVersionOf(db), 14);

        final rows = await db.select(db.localRecordings).get();
        expect(rows, hasLength(1));
        expect(rows.single.title, 'My narration');
        expect(rows.single.localFilePath, '/audio/rec-1.m4a');
      } finally {
        await db.close();
      }
    },
  );

  test(
    'a database whose migration was killed several versions in still opens',
    () async {
      await _seedAtV1(dbFile);

      // v9 -> v10 adds four sync columns to local_storytellers, eight steps
      // into the upgrade — the long haul a user who skipped many releases runs,
      // and the one most exposed to being killed partway.
      await _killMigration(
        dbFile,
        at: _nthAddColumnOn('local_storytellers', 2),
      );

      final db = AppDatabase.forTesting(NativeDatabase(dbFile));
      try {
        expect(await _userVersionOf(db), 14);

        final rows = await db.select(db.localRecordings).get();
        expect(rows, hasLength(1));
        expect(rows.single.title, 'My narration');
        expect(rows.single.localFilePath, '/audio/rec-1.m4a');
      } finally {
        await db.close();
      }
    },
  );

  test('a recovered database still takes writes', () async {
    await _seedAtV12(dbFile);
    await _killMigration(dbFile, at: _nthAddColumnOn('local_recordings', 2));

    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    try {
      await db
          .into(db.localRecordings)
          .insert(
            LocalRecordingsCompanion.insert(
              id: 'rec-2',
              projectId: 'proj-1',
              genreId: 'genre-1',
              localFilePath: '/audio/rec-2.m4a',
              recordedAt: DateTime.fromMillisecondsSinceEpoch(1700000001000),
              title: const Value('A second narration'),
            ),
          );

      final rows = await db.select(db.localRecordings).get();
      expect(rows.map((r) => r.id), unorderedEquals(['rec-1', 'rec-2']));
    } finally {
      await db.close();
    }
  });
}

/// Writes a v12-shaped database holding one un-uploaded recording.
Future<void> _seedAtV12(File file) async {
  final db = v12.DatabaseAtV12(NativeDatabase(file));
  try {
    await db
        .into(db.localRecordings)
        .insert(
          v12.LocalRecordingsCompanion.insert(
            id: 'rec-1',
            projectId: 'proj-1',
            genreId: 'genre-1',
            localFilePath: '/audio/rec-1.m4a',
            recordedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
            title: const Value('My narration'),
          ),
        );
  } finally {
    await db.close();
  }
}

/// Writes a v1-shaped database holding one un-uploaded recording.
Future<void> _seedAtV1(File file) async {
  final db = v1.DatabaseAtV1(NativeDatabase(file));
  try {
    await db
        .into(db.localRecordings)
        .insert(
          v1.LocalRecordingsCompanion.insert(
            id: 'rec-1',
            projectId: 'proj-1',
            genreId: 'genre-1',
            localFilePath: '/audio/rec-1.m4a',
            recordedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
            title: const Value('My narration'),
          ),
        );
  } finally {
    await db.close();
  }
}

/// Opens [file] as the real database and kills the migration at the statement
/// [at] selects, then closes the handle so the next open sees only the disk.
Future<void> _killMigration(
  File file, {
  required bool Function(String statement) at,
}) async {
  final db = AppDatabase.forTesting(
    NativeDatabase(file).interceptWith(_DieAt(at)),
  );
  try {
    // Opening is lazy in drift: the migration only runs on the first query.
    await expectLater(
      db.customSelect('select 1').get(),
      throwsA(isA<_MigrationKilled>()),
    );
  } finally {
    await db.close();
  }
}

Future<int> _userVersionOf(AppDatabase db) async {
  final row = await db.customSelect('pragma user_version').getSingle();
  return row.read<int>('user_version');
}

/// Matches the [n]th `ADD COLUMN` issued against [table] during one migration.
bool Function(String) _nthAddColumnOn(String table, int n) {
  var seen = 0;
  return (statement) {
    if (!statement.contains('ADD COLUMN') || !statement.contains(table)) {
      return false;
    }
    return ++seen == n;
  };
}

/// Aborts the migration at a chosen DDL statement the way a dying process
/// would: everything before it really ran against the file, nothing after it
/// did. The database itself is real SQLite on a real file.
class _DieAt extends QueryInterceptor {
  _DieAt(this._isFatal);

  final bool Function(String statement) _isFatal;

  // drift hands the *inner* executor to `beforeOpen`, where the migration
  // runs, so the migration's statements bypass an interceptor unless the
  // database is wrapped as well.
  @override
  Future<bool> ensureOpen(QueryExecutor executor, QueryExecutorUser user) {
    return executor.ensureOpen(_MigratingThroughInterceptor(user, this));
  }

  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (_isFatal(statement)) {
      throw const _MigrationKilled();
    }
    return super.runCustom(executor, statement, args);
  }
}

class _MigratingThroughInterceptor implements QueryExecutorUser {
  _MigratingThroughInterceptor(this._database, this._interceptor);

  final QueryExecutorUser _database;
  final QueryInterceptor _interceptor;

  @override
  int get schemaVersion => _database.schemaVersion;

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) =>
      _database.beforeOpen(executor.interceptWith(_interceptor), details);
}

class _MigrationKilled implements Exception {
  const _MigrationKilled();

  @override
  String toString() => 'migration killed mid-flight';
}
