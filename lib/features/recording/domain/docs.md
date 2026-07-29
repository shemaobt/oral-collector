# Noridoc: Recording Domain

Path: @/lib/features/recording/domain

### Overview

- The dependency-light core of the recording feature: the entity/DTO
  types under [./entities/](entities/), the abstract repository contract
  under [./repositories/](repositories/), and pure policy logic — the
  edit-authorization policy in
  [./recording_edit_policy.dart](recording_edit_policy.dart) and the
  classification predicates in
  [./entities/classification.dart](entities/classification.dart).
- Holds no Flutter, Riverpod, Drift, or `http` dependencies: every file
  here imports nothing but other domain types (the policy depends only on
  the auth `User` entity; `classification.dart` imports nothing at all).
  This keeps the rules headless-testable in isolation from any row or
  screen. The classification predicates are pure id-logic — they take
  genre/register id arguments rather than reading them off the Drift
  `LocalRecording` row, which is what lets this file stay Drift-free.
- This layer defines *what* a recording is and *who may edit one*; the
  data layer ([../data/](../data/)) supplies the implementation and the
  presentation layer ([../presentation/](../presentation/)) consumes
  both.

### How it fits into the larger codebase

- `RecordingApiRepository` (in [./repositories/](repositories/)) is the
  abstract server contract that `RecordingApiRepositoryImpl` in
  [../data/repositories/docs.md](../data/repositories/docs.md)
  implements; callers depend on the abstraction so it can be mocked. Its
  partial-update entry point is `updateRecording(serverId, request)`, where
  `request` is a [`UpdateRecordingRequest`](entities/update_recording_request.dart)
  (ENG-205) — see below.
- The entities — `Recording`, `ServerRecording`, `Register` — are the
  shared vocabulary. `ServerRecording` is the API DTO that the data layer
  maps to the local `LocalRecording` Drift row.
- [`UpdateRecordingRequest`](entities/update_recording_request.dart) (ENG-205)
  is the PATCH-body params object for `updateRecording`: a plain `const` class
  with the thirteen optional update fields and a `toJson()` that builds the
  wire body. It is the idiomatic mirror of the genre feature's `GenreUpdate`
  (which backs `updateGenre`) and of
  [`SplitSegmentRequest`](entities/split_segment_request.dart) — no
  freezed/equatable, no `==`/`copyWith`. `toJson()` omits a null field (leaves
  it untouched), while `clearSecondary` sends explicit nulls for the three
  secondary-classification keys to clear them. It was extracted purely to
  collapse the thirteen named parameters `updateRecording` used to take into one
  argument (the `dart_code_linter` `number-of-parameters` gate; the threshold
  ratchet itself is ENG-208) — the JSON on the wire is byte-identical, so the
  OC↔API update contract (ENG-81) is unchanged.
- `LocalRecordingEntity` (ENG-195) is the row-decoupled domain view of a
  recording: an immutable (`const` ctor, all-`final`), Drift-free class
  carrying the operational fields the UI reads (`localFilePath`,
  `uploadStatus`, `serverId`, `gcsUrl`, `retryCount`, `resumableSessionUri`,
  `uploadedBytes`, …) plus identity/content/classification fields. It exists
  to begin peeling the recording domain/UI off the Drift-generated
  `LocalRecording` row. The row→entity projection has a single public source of
  truth, `localRecordingToEntity` in
  [../data/local_recording_to_entity.dart](../data/local_recording_to_entity.dart);
  the repository's private `_fromRow` and the list notifier both delegate to it
  (see [../data/docs.md](../data/docs.md) and
  [../data/repositories/docs.md](../data/repositories/docs.md)).
- The migration off the row is staged (ENG-195 → ENG-197 → ENG-198 → ENG-201 →
  ENG-196 → ENG-199). ENG-197 repointed the recordings-list state/notifier
  ([../presentation/notifiers/docs.md](../presentation/notifiers/docs.md)) onto
  `List<LocalRecordingEntity>` — the first consumer to actually hold the entity.
  ENG-198 then re-typed the trim editor's editing state and its split-persist
  path (`TrimEditorState.recording`, `RecordingSplitPersister`, and
  `LocalRecordingRepository.splitRecordingReplacingParent`) onto the entity,
  the first time it reaches a write-path input (as a read-only `parent`). ENG-201
  (F4b) then added the first reverse mapper, `localRecordingEntityToCompanion`,
  and re-typed `saveRecording` onto the entity (see
  [../data/docs.md](../data/docs.md) and
  [../data/repositories/docs.md](../data/repositories/docs.md)). ENG-196 migrated
  the list's leaf widgets: `RecordingCard` and the per-item pending-web-upload
  card now take the entity, and the temporary list-screen adapter that
  re-hydrated a row for the card was deleted (see
  [../presentation/docs.md](../presentation/docs.md)). The recording-detail watch
  stream is repointed in a later task (F5b), and the detail-screen section
  widgets in ENG-199.
- `LocalRecordingEntity.copyWith` uses **sentinel** semantics for nullable
  fields: passing `null` *clears* a nullable field, omitting it *preserves* the
  current value. Each nullable parameter defaults to a private `_sentinel`
  object, and the body uses `identical(arg, _sentinel)` to tell "leave
  unchanged" apart from an explicit `null`. A plain `value ?? this.value` could
  not express "clear", which is why the list notifier's `patchRecordingTitle`
  can use `copyWith(title: …)` directly instead of Drift's `Value(...)` wrapper.
- `LocalRecordingEntityClassification` (in
  [./entities/local_recording_entity_classification.dart](entities/local_recording_entity_classification.dart))
  is the entity-side mirror of the row's `RecordingClassification` extension
  ([../data/local_recording_classification.dart](../data/local_recording_classification.dart)):
  it adds `isUnclassified` and `hasSecondary` (the latter added by ENG-196 once
  `RecordingCard` switched to the entity) and delegates both to the **same** pure
  predicates in
  [./entities/classification.dart](entities/classification.dart), so the entity
  and the Drift row classify identically. The list state's `unclassified` filter
  reads `isUnclassified`; the list card reads both.
- `classification.dart` is **not** an entity type: it is the
  `kUnclassifiedGenreId` sentinel const plus top-level pure predicate
  functions (`recordingHasGenre`, `recordingIsUnclassified`,
  `recordingHasSecondary`, …) keyed on ids, plus
  `secondaryEqualsPrimary(...)` — the one definition of a
  secondary-classification collision (whole `(register, genre,
  subcategory)` triple identical, ENG-72) shared by the pickers, the
  detail-screen banner, the trim editor's entry guard and the split
  guard — and the `SegmentClassificationCollisionException` that guard
  throws. Like its siblings it treats `''` as absent (`blankToNull`,
  exported for the pickers), because callers hand it raw nullable
  columns straight off a Drift row. The ergonomic
  `RecordingClassification` extension that reads those ids off a
  `LocalRecording` row lives in the data layer
  ([../data/local_recording_classification.dart](../data/local_recording_classification.dart))
  and delegates to these functions — domain owns the rule, data owns the
  Drift-bound sugar (ENG-175 / ENG-95 Phase 0).
- `recording_edit_policy.dart` is consumed only by the detail screen's
  `_canEditRecording` getter (see
  [../presentation/docs.md](../presentation/docs.md)). It is the single
  client-side authorization decision for a recording.
- It reaches across to the auth feature for the `User` entity
  ([/lib/features/auth/domain/entities/user.dart](../../auth/domain/entities/user.dart))
  and is fed the boolean result of `RoleNotifier.canManageProject`
  ([/lib/features/auth/data/providers/role_provider.dart](../../auth/data/providers/role_provider.dart)).

### Core Implementation

- `canEditRecording({user, canManageProject, recordingUserId})` returns
  editable iff the user is non-null *and* one of: the user is a platform
  admin, `canManageProject` is true, or the recording's `userId` equals
  the user's id. A null user is never editable; a null `recordingUserId`
  never counts as ownership.
- The function takes a plain `bool canManageProject` rather than the
  `RoleNotifier` so the policy carries no Riverpod/network dependency —
  the caller resolves the role boolean and passes it in. This is the
  seam that makes the rule unit-testable without a container.

### Things to Know

- **`LocalRecordingEntity` hand-writes value equality, and that is
  load-bearing (ENG-195).** Unlike the `Storyteller` entity (which has no
  equality override), it overrides `operator ==`/`hashCode` across its whole
  field set — a new pattern for this codebase's entities, demanded by the watch
  stream. The data layer maps row→entity *before* `.distinct()` on the watch
  stream, so dedup keys on this `==` rather than the Drift row's generated
  equality. Without the override, each emission would be a fresh unequal object
  and `.distinct()` would never collapse anything.
- **The entity deliberately drops the persistence internals `lastRetryAt`
  and `md5Hash`.** They are not fields the UI reads, and omitting them means
  a write touching only those produces an *equal* entity, which `.distinct()`
  then suppresses — quieting the entity stream against pure retry/hash
  bookkeeping. The fields still live on the Drift row.
- **`localFilePath` is a non-null `String`; `''` is the sentinel for "not on
  this device".** Callers check `localFilePath.isEmpty` before touching the
  file rather than treating absence as null. This matches the Drift column,
  which is also non-null.
- **The reverse mapper is scoped to the save path (ENG-201).** The first
  entity→companion mapper, `localRecordingEntityToCompanion`
  ([../data/local_recording_entity_to_companion.dart](../data/local_recording_entity_to_companion.dart)),
  backs `saveRecording` for a freshly captured row; it is the inverse of
  `localRecordingToEntity` scoped to the insert companion, not a full serializer.
  The split write path is deliberately *not* migrated onto it — ENG-198 re-typed
  `splitRecordingReplacingParent`'s `parent` to the entity but still builds child
  companions by hand, because each child mixes inherited / segment-specific /
  reset fields. See [../data/repositories/docs.md](../data/repositories/docs.md).
- **The `isPlatformAdmin` term is intentionally redundant.**
  `RoleNotifier.canManageProject` already returns true for platform
  admins (it short-circuits on `isPlatformAdmin` before checking
  per-project roles, see
  [/lib/features/auth/data/providers/role_provider.dart](../../auth/data/providers/role_provider.dart)).
  The explicit admin term in the policy is defensive and
  self-documenting so the rule reads correctly even if a future caller
  passes a `canManageProject` that is not admin-aware.
- **This is a UX/authorization-surface gate, not a security boundary
  (ENG-142).** Before this policy existed, the detail screen's gate was
  dead code that always returned true, so every authenticated user saw
  edit/replace/delete controls regardless of role or ownership. Hiding
  them client-side is the fix; the server is still the enforcement point
  and a matching server-side authorization check is tracked separately
  (ENG-81, out of scope here).
- **Keep the policy pure.** The value of extracting it from the screen
  is that it can be exercised across the admin / manager / owner /
  non-owner / null-user matrix without a widget or provider. Do not pull
  Riverpod, Drift, or `BuildContext` into this file — resolve those at
  the call site and pass primitives in.

Created and maintained by Nori.
