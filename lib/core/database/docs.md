# Noridoc: Core Database

Path: @/lib/core/database

### Overview

- The app's local SQLite persistence layer, built on Drift.
  [./app_database.dart](app_database.dart) declares the tables, the current
  `schemaVersion`, and the `MigrationStrategy` that brings any older on-disk
  database up to the current shape. Generated code lives alongside it in
  `app_database.g.dart`.
- The rest of the app reaches the database through `appDatabaseProvider` in
  [./database_provider.dart](database_provider.dart); feature data layers under
  `lib/features/*/data/` are the only writers. The tables cover the local
  recordings upload queue, the genre/subcategory taxonomy, storytellers, and
  in-progress recording sessions.
- ENG-123 added a schema-snapshot + step-through migration-testing workflow
  (`drift_schemas/` snapshots and
  [/test/core/database/](../../../test/core/database/)) and fixed a
  duplicate-column crash on the upgrade path from an old pre-sync schema
  straight to the current version.

### How it fits into the larger codebase

- `appDatabaseProvider` builds one `AppDatabase` per Riverpod container and
  closes it on dispose. This is the single in-process handle; every feature
  repository is constructor-injected with it rather than reading Riverpod
  directly.
- The generated `LocalRecording` data class and `LocalRecordingsCompanion` are
  imported from here by the recording data layer.
  [LocalRecordingRepository](../../features/recording/data/repositories/docs.md)
  is the only legitimate writer for the `LocalRecordings` table; the taxonomy,
  storyteller, and session tables are likewise owned by their respective
  feature data layers (e.g. [genre](../../features/genre/data/docs.md),
  [project](../../features/project/data/docs.md)).
- `AppDatabase` is constructed only in [./database_provider.dart](database_provider.dart)
  behind `appDatabaseProvider`; background uploads reuse that same in-process
  handle (the Android upload pipeline stays in-process via the foreground
  service — see [sync docs](../../features/sync/docs.md)) rather than opening a
  second connection.
- Connection setup is platform-conditional. [./connection.dart](connection.dart)
  exports the native or web implementation at compile time:

  ```
  AppDatabase()  ->  openConnection()  ->  connection.dart (conditional export)
                                            |- connection/native.dart  (default)
                                            |     LazyDatabase -> NativeDatabase
                                            |     file in app documents dir
                                            '- connection/web.dart      (js_interop)
                                                  WebDatabase('oral_collector')
  ```

### Core Implementation

- `AppDatabase` is annotated with `@DriftDatabase(tables: [...])` and exposes
  the current `schemaVersion` (11). `AppDatabase.forTesting(e)` takes an
  explicit executor and is the entry point the migration tests and an in-memory
  `NativeDatabase.memory()` use.
- `MigrationStrategy` has two callbacks:

  | Callback | When it runs | Effect |
  | --- | --- | --- |
  | `onCreate` | fresh install | `createAll()` builds every table at the current shape, skipping the upgrade steps entirely |
  | `onUpgrade(m, from, to)` | an existing file is opened by a newer build | replays ordered `if (from < N)` steps once, from the on-disk version up to `to` |

- Each upgrade step is additive: a new column is `addColumn`-ed and a new table
  is `createTable`-d, in version order. A user who skipped several releases
  replays each intervening step in one `onUpgrade` call. The one non-trivial
  step adds the storyteller sync columns and is guarded
  `from >= 6 && from < 10` (see Things to Know).
- [./connection/native.dart](connection/native.dart) wraps the file open in a
  `LazyDatabase` and uses `NativeDatabase.createInBackground` so the SQLite
  handle (and any migration) runs off the UI isolate.
  [./connection/web.dart](connection/web.dart) is the IndexedDB-backed
  `WebDatabase` fallback.
- The migration-test workflow has three committed artifacts that must stay in
  lockstep with `app_database.dart`:
  - `drift_schemas/drift_schema_vN.json` — one snapshot per schema version. The
    current version is dumped from the real database; the older snapshots were
    reconstructed (no historical snapshots existed before ENG-123).
  - [/test/core/database/generated/](../../../test/core/database/generated/) —
    `drift_dev`-generated `GeneratedHelper` and per-version `DatabaseAtVN`
    classes, committed like `.g.dart` output and excluded from analysis in
    [/analysis_options.yaml](../../../analysis_options.yaml).
  - [/test/core/database/migration_test.dart](../../../test/core/database/migration_test.dart) —
    drives drift's `SchemaVerifier`: it `startAt(k)` for every historical
    version and `migrateAndValidate(db, 11)`, asserting the resulting schema
    matches the current reference, plus a data-integrity case that seeds an
    un-uploaded recording at the oldest version and asserts the row and its
    fields survive the full upgrade.

### Things to Know

- **`createTable` / `createAll` emit the table's CURRENT shape, not a historical
  one.** Inside `onUpgrade`, `m.createTable(localStorytellers)` in the older
  step builds the table at today's definition, which already carries the sync
  columns added in a later version. The duplicate-column crash fixed in ENG-123
  came from then `addColumn`-ing those same columns: the
  `from >= 6 && from < 10` guard makes the adds run **only** for databases that
  already had the table at an older, pre-sync shape. The migration test is the
  guard against reintroducing this whenever a table is both created in one step
  and altered in a later step.
- **`@TableIndex` indexes follow the same fresh-vs-upgrade split.** `createAll()`
  builds them for fresh installs, but `onUpgrade` must create each one
  explicitly with `m.createIndex(...)` — the `if (from < 11)` step added in
  ENG-117. A forgotten `onUpgrade` index ships an un-indexed upgrade path while
  fresh installs look fine; the migration test catches it because
  `migrateAndValidate` diffs indexes, not just tables and columns.
- **A failed migration is not recovered by wiping the database.** The open path
  in [./connection/](connection/) has no `beforeOpen`, no try/catch, and no
  delete-and-recreate. A bad migration therefore bricks the database — data is
  stranded (un-uploaded recordings cannot be reached), not deleted — until a
  build with a corrected migration ships. This is why the upgrade path is
  test-guarded rather than left to recover at runtime.
- **Adding a new schema version is a fixed five-step process.** Skipping any
  step makes the migration test fail or, worse, lets an untested upgrade path
  ship:
  1. bump `schemaVersion` in [./app_database.dart](app_database.dart);
  2. add the `if (from < N)` step to `onUpgrade` (`addColumn`/`createTable` for
     columns and tables, `m.createIndex(...)` for an `@TableIndex`);
  3. dump a new snapshot:
     `dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/drift_schema_vN.json`;
  4. regenerate fixtures:
     `dart run drift_dev schema generate --data-classes --companions drift_schemas/ test/core/database/generated/`;
  5. extend the `startAt(N)` coverage in
     [the migration test](../../../test/core/database/migration_test.dart).
- **The generated fixtures are committed and analysis-excluded.** Treat
  `test/core/database/generated/` like `*.g.dart`: never hand-edit it, always
  regenerate. The exclusion in
  [/analysis_options.yaml](../../../analysis_options.yaml) keeps the
  drift-generated lint noise out of `flutter analyze`.
- **Snapshots are the source of truth for old shapes; the live database is the
  source of truth for the current shape.** Because the pre-current snapshots
  were reconstructed, the migration test's job is to prove the migration code
  reproduces the current reference from each reconstructed starting point — not
  to trust the snapshots blindly.

Created and maintained by Nori.
