// Step-through migration tests for AppDatabase, driven by drift's SchemaVerifier
// against the committed per-version snapshots in drift_schemas/.
//
// These guard the upgrade path: a botched migration would strand (or, with a
// careless "fix", drop) un-uploaded recordings. See ENG-123.
import 'package:drift/drift.dart' show Value;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/database/app_database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v6.dart' as v6;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('migrating a database at each historical version up to v12', () {
    // A user who skipped builds upgrades straight from their on-disk version to
    // the current schema. drift runs onUpgrade(from, 12) once. The resulting
    // schema must match the official v12 reference for every starting point —
    // indexes included, so a forgotten createIndex in onUpgrade fails here
    // (migrateAndValidate diffs indexes, not just tables and columns).
    for (var from = 1; from < 12; from++) {
      test('v$from -> v12 yields the expected v12 schema', () async {
        final connection = await verifier.startAt(from);
        final db = AppDatabase.forTesting(connection);
        try {
          await verifier.migrateAndValidate(db, 12);
        } finally {
          await db.close();
        }
      });
    }
  });

  group('migrating a database one version at a time', () {
    // stepByStep honors the `to` argument: onUpgrade(from, from + 1) must land
    // exactly on the next version's schema instead of running through to the
    // latest. migrateAndValidate diffs tables, columns and indexes, so every
    // single step is validated against its own snapshot in isolation.
    for (var from = 1; from < 12; from++) {
      test(
        'v$from -> v${from + 1} yields the expected v${from + 1} schema',
        () async {
          final connection = await verifier.startAt(from);
          final db = AppDatabase.forTesting(connection);
          try {
            await verifier.migrateAndValidate(db, from + 1);
          } finally {
            await db.close();
          }
        },
      );
    }
  });

  test(
    'preserves an un-uploaded recording across the full v1 -> v12 upgrade',
    () async {
      final schema = await verifier.schemaAt(1);

      // Seed one un-uploaded recording (uploadStatus stays 'local') using the v1
      // schema, on an independent connection to the shared raw database. Distinct
      // non-default values are set so a reset/recreate of the row is detectable.
      final oldDb = v1.DatabaseAtV1(schema.newConnection());
      await oldDb
          .into(oldDb.localRecordings)
          .insert(
            v1.LocalRecordingsCompanion.insert(
              id: 'rec-1',
              projectId: 'proj-1',
              genreId: 'genre-1',
              localFilePath: '/audio/rec-1.m4a',
              recordedAt: DateTime.fromMillisecondsSinceEpoch(
                1700000000 * 1000,
              ),
              title: const Value('My narration'),
              durationSeconds: const Value(42.5),
              fileSizeBytes: const Value(123456),
              retryCount: const Value(2),
            ),
          );
      await oldDb.close();

      // Run the real migration to v12 on the app's database class.
      final db = AppDatabase.forTesting(schema.newConnection());
      try {
        await verifier.migrateAndValidate(db, 12);

        final rows = await db.select(db.localRecordings).get();
        expect(rows, hasLength(1));
        final row = rows.single;
        expect(row.id, 'rec-1');
        expect(row.localFilePath, '/audio/rec-1.m4a');
        expect(row.uploadStatus, 'local');
        expect(row.title, 'My narration');
        expect(row.durationSeconds, 42.5);
        expect(row.fileSizeBytes, 123456);
        expect(row.retryCount, 2);
        expect(row.recordedAt.millisecondsSinceEpoch, 1700000000 * 1000);
        // A row written before review flags existed reads as owing nothing,
        // rather than as a null the entity mapper would have to guess about.
        expect(row.reviewFlagsJson, '[]');
      } finally {
        await db.close();
      }
    },
  );

  test('preserves a storyteller across the v6 -> v12 upgrade', () async {
    final schema = await verifier.schemaAt(6);

    // Seed a storyteller at v6 — the version where local_storytellers exists
    // at its pre-sync 10-column shape, before serverId/syncStatus/retryCount/
    // lastRetryAt are added at v10. This proves the from5To6 (create) /
    // from9To10 (add sync columns) split upgrades a v6-shaped table without
    // duplicating columns.
    final oldDb = v6.DatabaseAtV6(schema.newConnection());
    await oldDb
        .into(oldDb.localStorytellers)
        .insert(
          v6.LocalStorytellersCompanion.insert(
            id: 'st-1',
            projectId: 'proj-1',
            name: 'Ada',
            sex: 'F',
            age: const Value(42),
          ),
        );
    await oldDb.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    try {
      await verifier.migrateAndValidate(db, 12);

      final rows = await db.select(db.localStorytellers).get();
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.id, 'st-1');
      expect(row.name, 'Ada');
      expect(row.sex, 'F');
      expect(row.age, 42);
      // Sync columns introduced at v10 land with their defaults.
      expect(row.syncStatus, 'synced');
      expect(row.retryCount, 0);
      expect(row.serverId, isNull);
    } finally {
      await db.close();
    }
  });
}
