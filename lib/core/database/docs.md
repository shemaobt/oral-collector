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
- ENG-161 rewrote `onUpgrade` from hand-written `if (from < N)` blocks to
  drift's generated `stepByStep` helper, so each step migrates exactly one
  version against that version's schema snapshot. This eliminated the
  duplicate-column footgun by construction (no conditional guard) and made the
  upgrade honor drift's `to` argument instead of always migrating to the
  current version.
- ENG-425 made the upgrade path atomic: the whole run of steps happens inside
  one transaction, so a migration interrupted partway (process kill, battery,
  OOM) is rolled back whole instead of leaving the file half-migrated and
  permanently unopenable.
- ENG-420 (slice 1) added `finalizedAudioPath`/`finalizedDurationSeconds` to
  `RecordingSessions` at v14 — an ordinary additive `from13To14` step, no
  different mechanically from any other. What the columns mean (a durable
  pointer from a session row to the audio file it produced, written before the
  row is marked completed) and why the migration does no back-fill is documented
  where the columns are written, not here — see
  [../../features/recording/data/repositories/docs.md](../../features/recording/data/repositories/docs.md).
  Slice 2 gave the columns their first reader: the crash-recovery sweep in
  [RecoveryCoordinator](../../features/recording/data/services/recovery_coordinator.dart)
  stats the anchored file to decide whether a finished session still owes the
  user a recovery offer — see the same repositories doc.

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
  the current `schemaVersion` (14). `AppDatabase.forTesting(e)` takes an
  explicit executor and is the entry point the migration tests and an in-memory
  `NativeDatabase.memory()` use.
- `MigrationStrategy` has two callbacks:

  | Callback | When it runs | Effect |
  | --- | --- | --- |
  | `onCreate` | fresh install | `createAll()` builds every table at the current shape, skipping the upgrade steps entirely |
  | `onUpgrade` (`_upgrade`) | an existing file is opened by a newer build | runs each `from(N-1)ToN` callback in order, from the on-disk version up to `to`, all inside one transaction |

- `onUpgrade` is the top-level `_upgrade`, which opens a transaction and drives
  the generated per-version steps through drift's `VersionedSchema.runMigrationSteps`
  (the same thing the generated `stepByStep` helper does, minus the transaction —
  see Things to Know for why the wrapper is hand-written). The step callbacks
  themselves are passed to `migrationSteps(...)` from
  [./schema_versions.dart](schema_versions.dart). `_upgrade` is deliberately
  top-level: a top-level declaration has no `this`, so a step cannot accidentally
  reach the *current* table definitions.
- Each upgrade step is additive and applies only that one version's delta. The
  callback receives `(Migrator m, SchemaN schema)` where `schema` is the
  **destination** version's typed snapshot, so `m.addColumn`,
  `m.createTable`, and `m.create` operate on the table/index *as it existed at
  that version* — e.g. `from5To6` creates `local_storytellers` at its pre-sync
  v6 shape and `from9To10` adds the sync columns. A user who skipped several
  releases runs each intervening step in order in one upgrade, and drift's `to`
  argument bounds how far it goes (see Things to Know).
- [./connection/native.dart](connection/native.dart) wraps the file open in a
  `LazyDatabase` and uses `NativeDatabase.createInBackground` so the SQLite
  handle (and any migration) runs off the UI isolate.
  [./connection/web.dart](connection/web.dart) is the IndexedDB-backed
  `WebDatabase` (drift's legacy `package:drift/web.dart`), which persists the
  database under the name `oral_collector` in the browser. Its SQLite engine is
  the `sql.js` WebAssembly build, served **same-origin from `web/` with no CDN**
  (see Things to Know).
- The migration workflow has several committed artifacts that must stay in
  lockstep with `app_database.dart`:
  - `drift_schemas/drift_schema_vN.json` — one snapshot per schema version. The
    current version is dumped from the real database; the older snapshots were
    reconstructed (no historical snapshots existed before ENG-123).
  - [./schema_versions.dart](schema_versions.dart) — `drift_dev`-generated from
    those snapshots (`schema steps`); holds the `SchemaN` typed snapshots and the
    `migrationSteps` factory that `_upgrade` calls. Committed and analysis-excluded
    like `.g.dart` (ENG-161); `app_database.dart` imports it.
  - [/test/core/database/generated/](../../../test/core/database/generated/) —
    `drift_dev`-generated `GeneratedHelper` and per-version `DatabaseAtVN`
    classes, committed like `.g.dart` output and excluded from analysis in
    [/analysis_options.yaml](../../../analysis_options.yaml).
  - [/test/core/database/migration_test.dart](../../../test/core/database/migration_test.dart) —
    drives drift's `SchemaVerifier`. For every historical version it `startAt(k)`
    and both `migrateAndValidate(db, 14)` (the skip-many-releases path) and
    `migrateAndValidate(db, k + 1)` (a single step lands exactly on the next
    version, exercising that the upgrade honors `to`). Plus data-integrity
    cases that seed an un-uploaded recording at the oldest version, a
    storyteller at v6, and (ENG-420) a `RecordingSessions` row in each of its
    five statuses at v13, asserting the rows and fields survive the upgrade —
    the sessions case is also what proves the new v14 anchor columns come out
    `null` rather than guessed at.
  - [/test/core/database/migration_interruption_test.dart](../../../test/core/database/migration_interruption_test.dart) —
    the durability half (ENG-425). It seeds a real file at an old version, kills
    the migration mid-flight with a `QueryInterceptor` that throws on a chosen
    `ALTER TABLE`, then reopens the same file and asserts it opens, reaches the
    current version, still holds the seeded recording, and still takes writes.
    It asserts nothing about statements or transactions, so it survives a change
    of approach.

### Things to Know

- **Step-by-step migration made each step see the table at its own version,
  removing the duplicate-column footgun.** The danger is real and worth remembering: bare
  `createTable`/`createAll` on the *current* table definitions emit today's
  shape, so a step that created `local_storytellers` in an old release would
  build it already carrying the sync columns added later — and then
  `addColumn`-ing those same columns crashed the upgrade (the bug fixed in
  ENG-123, which needed a hand-written `from >= 6 && from < 10` guard so the
  adds ran only for databases that had the table at its older, pre-sync shape).
  With the step-by-step callbacks each step gets the **destination version's** `schema`
  snapshot: `from5To6` creates `local_storytellers` at its v6 shape (no sync
  columns) and `from9To10` adds them, so there is no duplication and the
  conditional guard no longer exists. The migration test still backs this up —
  `migrateAndValidate` diffs every starting point against its reference.
- **`@TableIndex` indexes follow the same fresh-vs-upgrade split.** `createAll()`
  builds them for fresh installs, but the upgrade path must create each one
  explicitly. They are created in the `from10To11` step via
  `m.create(schema.<index>)` (e.g. `schema.idxRecordingsProjectRecorded`) —
  introduced for the v11 indexes in ENG-117 and ported onto the step-by-step
  callbacks in ENG-161. A forgotten upgrade index ships an un-indexed upgrade path while
  fresh installs look fine; the migration test catches it because
  `migrateAndValidate` diffs indexes, not just tables and columns.
- **An *interrupted* migration recovers itself; a *wrong* one still bricks the
  database.** These are two different failures and only the first is handled.
  `_upgrade` runs every step inside one transaction (ENG-425), so a process
  killed partway — the OS reclaiming memory, the battery dying, the user force-
  quitting during a long upgrade — leaves SQLite to roll the whole run back:
  `user_version` goes back to the on-disk value along with the DDL, and the next
  launch migrates from scratch and succeeds. Before that, statements already
  applied stayed on disk while `user_version` did not advance, so the next
  launch re-ran the step and died on `duplicate column name` — forever, on every
  subsequent launch. Progress is deliberately not kept per step: an interrupted
  v1 → v14 upgrade restarts at v1, which is cheap because every step is additive
  and runs in milliseconds, and a transaction per step would reopen the same
  window between committing a step and writing `user_version`. What the
  transaction does *not* fix is a migration that is simply wrong (a step that
  contradicts the schema, or a missing step): that fails identically on every
  launch, and the open path in [./connection/](connection/) has no `beforeOpen`,
  no try/catch, and no delete-and-recreate, so the database stays unopenable —
  data stranded, not deleted — until a build with a corrected migration ships.
  This is why the upgrade path stays test-guarded rather than left to recover at
  runtime. The transaction is also not a repair: a device *already* bricked by
  an interrupted migration on an older build stays bricked, because its file is
  half-migrated before this code ever runs.
- **Transactions during migration work on web too.** The rollback is not a
  native-only guarantee: drift's legacy `WebDatabase` reports the same
  `NoTransactionDelegate` as the native executor, so `BEGIN`/`COMMIT`/`ROLLBACK`
  are issued as ordinary statements against the sql.js engine, which is real
  SQLite. The migration tests run native only, so this half is verified by
  reading drift, not by a test.
- **Adding a new schema version is a fixed multi-step process.** Skipping any
  step makes the migration test fail or, worse, lets an untested upgrade path
  ship. The commands match the `Codegen` workflow
  ([/.github/workflows/codegen.yml](../../../.github/workflows/codegen.yml)); the
  repo builds under FVM, so prefix `fvm`:
  1. bump `schemaVersion` in [./app_database.dart](app_database.dart);
  2. dump a new snapshot:
     `fvm dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/drift_schema_vN.json`;
  3. regenerate the step helper (must run **before** `build_runner`, since
     `app_database.dart` imports it):
     `fvm dart run drift_dev schema steps drift_schemas/ lib/core/database/schema_versions.dart`;
  4. add the `from(N-1)ToN` callback to the `migrationSteps` call in
     `app_database.dart` (`m.addColumn`/`m.createTable` for columns and tables,
     `m.create(schema.<index>)` for an `@TableIndex`), operating on the
     destination version's `schema`;
  5. regenerate the migration-test fixtures:
     `fvm dart run drift_dev schema generate --data-classes --companions drift_schemas/ test/core/database/generated/`;
  6. extend the `startAt(N)` coverage in
     [the migration test](../../../test/core/database/migration_test.dart).
- **The generated drift artifacts are committed and analysis-excluded.** Treat
  `test/core/database/generated/` and
  [./schema_versions.dart](schema_versions.dart) like `*.g.dart`: never hand-edit
  them, always regenerate. Their exclusions in
  [/analysis_options.yaml](../../../analysis_options.yaml) keep the
  drift-generated lint noise out of `flutter analyze` (the `schema_versions.dart`
  path is listed explicitly because it does not match the `**/*.g.dart` glob).
- **Schema codegen is reproducible because the toolchain is pinned (ENG-165).**
  `drift`/`drift_dev` are pinned to an exact version in
  [/pubspec.yaml](../../../pubspec.yaml) with `pubspec.lock` committed, so
  regeneration is deterministic — this is what makes the "always regenerate"
  rule above safe. Before pinning, a floating `drift_dev` rewrote the older
  fixtures on every `schema generate` (retyping `dateTime()` columns int↔DateTime
  and churning the schema-format), which is why an earlier version had to be
  hand-registered instead of regenerated. The pinned version is the ceiling
  resolvable under `custom_lint`'s `analyzer ^7` constraint, so raising
  `drift_dev` requires a coordinated lint-toolchain bump. The `Codegen`
  workflow ([/.github/workflows/codegen.yml](../../../.github/workflows/codegen.yml))
  enforces this: on every PR it regenerates the step helper, runs `build_runner`,
  and regenerates the test fixtures, then fails if `*.g.dart`,
  `schema_versions.dart`, `test/core/database/generated/`, or `pubspec.lock`
  drift from the committed source.
- **Snapshots are the source of truth for old shapes; the live database is the
  source of truth for the current shape.** Because the pre-current snapshots
  were reconstructed, the migration test's job is to prove the migration code
  reproduces the current reference from each reconstructed starting point — not
  to trust the snapshots blindly.
- **This is not the only IndexedDB database on web.** `WebDatabase`
  (`oral_collector`, drift over `sql.js`/WASM) holds recording *metadata*,
  i.e. the row in `LocalRecordings`. Recorded/imported audio *bytes* live in
  a second, separate IndexedDB database, `oral_collector_files`, owned by
  [/lib/core/platform/web_file_store.dart](../platform/web_file_store.dart)
  and used through [/lib/core/platform/file_ops.dart](../platform/file_ops.dart)
  (see [/lib/core/platform/docs.md](../platform/docs.md)). Audio bytes were
  never put in Drift: they do not fit a relational row cleanly, and this
  database's schema-migration machinery (above) exists to evolve typed
  columns, not to version an opaque blob store with its own capacity/eviction
  concerns. Before ENG-421 the bytes were not persisted anywhere on web — a
  module-level `Map` in `file_ops_web.dart` held them in memory only, so a
  page reload destroyed the audio while the Drift row (already durable via
  `WebDatabase`) survived, leaving a recording whose audio existed nowhere.
- **On web the sql.js engine is self-hosted, not loaded from a CDN (ENG-130).**
  The `.js` loader and `.wasm` binary live in the repo's `web/` directory and
  are served same-origin. This is a security boundary: a CDN compromise could
  otherwise inject JS/WASM into the app origin and exfiltrate the local DB.
  Subresource Integrity on the `<script>` was insufficient because it cannot
  cover a `.wasm` fetched programmatically via `WebAssembly.instantiateStreaming`;
  self-hosting gives same-origin integrity for both files. (CSP hardening is a
  separate effort, ENG-167.)
- **The only hook that points the wasm at the right origin is
  `window.Module.locateFile` in `web/index.html`.** Drift's `WebDatabase`
  (see [./connection/web.dart](connection/web.dart)) calls the global
  `initSqlJs()` with **no arguments**, so it never passes `locateFile`. The
  MODULARIZE sql.js build merges a pre-defined `window.Module`, so that block is
  the sole place Emscripten learns where `sql-wasm.wasm` lives. It returns the
  bare filename so the URL resolves against `<base href>` (works for both
  root and subpath deploys). No Dart code is involved; that block must be kept
  and repointed, never removed.
- **The `web/` sql.js `.js` and `.wasm` are a version-pinned matched pair.** They
  must be re-vendored **together** on any version bump. nginx
  ([/docker/nginx.conf](../../../docker/nginx.conf)) caches `.wasm` for one year
  `immutable` on its stable filename, so a future bump must also cache-bust
  (e.g. rename) to avoid serving a stale wasm.

Created and maintained by Nori.
