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

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('migrating a database at each historical version up to v10', () {
    // A user who skipped builds upgrades straight from their on-disk version to
    // the current schema. drift runs onUpgrade(from, 10) once. The resulting
    // schema must match the official v10 reference for every starting point.
    for (var from = 1; from < 10; from++) {
      test('v$from -> v10 yields the expected v10 schema', () async {
        final connection = await verifier.startAt(from);
        final db = AppDatabase.forTesting(connection);
        try {
          await verifier.migrateAndValidate(db, 10);
        } finally {
          await db.close();
        }
      });
    }
  });

  test(
    'preserves an un-uploaded recording across the full v1 -> v10 upgrade',
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
              recordedAt: 1700000000,
              title: const Value('My narration'),
              durationSeconds: const Value(42.5),
              fileSizeBytes: const Value(123456),
              retryCount: const Value(2),
            ),
          );
      await oldDb.close();

      // Run the real migration to v10 on the app's database class.
      final db = AppDatabase.forTesting(schema.newConnection());
      try {
        await verifier.migrateAndValidate(db, 10);

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
      } finally {
        await db.close();
      }
    },
  );
}
