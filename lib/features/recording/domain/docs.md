# Noridoc: Recording Domain

Path: @/lib/features/recording/domain

### Overview

- The dependency-light core of the recording feature: the entity/DTO
  types under [./entities/](entities/), the abstract repository contract
  under [./repositories/](repositories/), and pure policy logic — the
  edit-authorization policy in
  [./recording_edit_policy.dart](recording_edit_policy.dart), the
  upload-status affordance predicates in
  [./upload_status_actions.dart](upload_status_actions.dart), the
  classification predicates in
  [./entities/classification.dart](entities/classification.dart), and the
  server-deletion eligibility check in
  [./server_deletion_policy.dart](server_deletion_policy.dart).
- Holds no Flutter, Riverpod, Drift, or `http` dependencies: every file
  here imports nothing but other domain types (the edit policy depends
  only on the auth `User` entity; `canRetryUpload` and `isRetryableFailure` in
  `upload_status_actions.dart` import nothing at all,
  `hasRetryableFailedUploads` reads only `LocalRecordingEntity`;
  `classification.dart` imports nothing at all). This keeps the rules
  headless-testable in isolation from any row or screen. The
  classification predicates are pure id-logic — they take genre/register
  id arguments rather than reading them off the Drift `LocalRecording`
  row, which is what lets this file stay Drift-free.
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
- `ReviewFlag` ([./entities/review_flag.dart](entities/review_flag.dart),
  ENG-374) models one thing the server says a recording still owes (e.g. no
  classification, an insufficient description, no narrator). `code`/`origin`
  are free strings rather than an enum, so a code this build has never heard
  of still round-trips. The same file exposes `decodeReviewFlags`/
  `encodeReviewFlags`, the JSON-text codec the data layer uses to persist the
  list on the Drift row (see [../data/docs.md](../data/docs.md)).
  `ServerRecording.reviewFlags` reads the API's `review_flags` array; a
  missing key, a `null`, or any non-list value all read as "no flags" instead
  of throwing, and a malformed element inside an otherwise-good list is
  dropped individually via `parseList`
  ([/lib/core/serialization/parse_list.dart](../../../core/serialization/parse_list.dart))
  — the flags are advisory, so a parsing hiccup must never cost the recording
  itself. `LocalRecordingEntity.reviewFlags` (default `const []`) is the read
  side the UI will consume; it participates in `copyWith`, `==`, and
  `hashCode` like every other field. The admin-facing `Recording` DTO
  ([./entities/recording.dart](entities/recording.dart)) deliberately does
  not carry this field — it belongs to a different feature and no admin
  screen reads pending review state.
- [`PendingMetadataField`/`MetadataSyncStatus`](entities/pending_metadata_field.dart)
  (ENG-403) are the mirror image of `ReviewFlag` above: where a `ReviewFlag`
  is something the server says a recording still owes, a `PendingMetadataField`
  is something *this device* still owes the *server* — a field edited while
  the server was unreachable. The set names fields, never values: the local
  row already holds the desired state (every mutation writes it there
  first), so the sync drain
  ([/lib/features/sync/docs.md](../../sync/docs.md)) reads the value back
  off the row at send time instead of replaying a stored payload, which is
  what makes two offline edits to the same field collapse into one write.
  `secondary` names all three secondary-classification columns as one token
  because the wire contract only ever clears them together.
  `encodePendingMetadataFields`/`decodePendingMetadataFields` are the
  JSON-text codec for the Drift column (`pendingMetadataJson`), mirroring
  `decodeReviewFlags`'s tolerance of an unknown token or invalid JSON — a
  stored value from a newer or older build must cost at most the un-pushed
  edit, never the read of the whole recording.
  `LocalRecordingEntity.metadataSyncStatus`/`pendingMetadataFields`/
  `hasPendingMetadata` carry this state onto the entity, because the
  recordings list and card read the entity, not the row; nothing in the UI
  reads them yet — a future consumer is tracked as ENG-405.
- [`PendencyKind`/`recordingPendencies`](entities/review_pendency.dart)
  (ENG-374 PR-B) turn `reviewFlags`, plus the classification/description/
  storyteller fields, into the ordered list of steps the guided completion
  flow walks the user through
  ([../presentation/widgets/complete_ficha_sheet.dart](../presentation/widgets/complete_ficha_sheet.dart)).
  `RecordingCard` (card V3, ENG-374 PR-C) is a second consumer: the list card's
  pendency chip names the list's length the same way the sheet's step list
  does, collapsing to a count once more than one field is open (see
  [../presentation/widgets/docs.md](../presentation/widgets/docs.md)).
  The rule: once a recording has a `serverId`, the server's flags decide what
  it owes — even where they disagree with the local fields, since the server
  may apply a rule this build predates — and a flag `code` this build has no
  editor for (the private `_knownCodes` map in that file) is dropped rather
  than shown or rendered as raw wire text. A recording with no `serverId` has
  no server opinion yet, so the same field predicates that `classification.dart`
  and `isDescriptionSufficient`
  ([/lib/shared/utils/recording_description.dart](../../../shared/utils/recording_description.dart))
  already expose answer instead — otherwise a recording captured minutes ago
  would read as complete while its maker is still there to finish it.
  `pendencyKindForCode` and its inverse `reviewFlagCodeFor` (ENG-381) both
  derive from `_knownCodes` — one forward, one built by inverting the same
  map — so a code and a kind can never disagree about which one names the
  other. `reviewFlagCodeFor` is what the recordings-list notifier
  ([../presentation/notifiers/docs.md](../presentation/notifiers/docs.md))
  sends as the `review_flag` query parameter when the project settings screen's
  pendency breakdown is tapped: the enum stays total over the server's closed
  code set, so a code the server would 422 on is unreachable from this path by
  construction. What this file deliberately does **not** own is the *label*:
  `pendencyLabel(AppLocalizations, PendencyKind)` lives on the presentation
  side, at
  [../presentation/pendency_label.dart](../presentation/pendency_label.dart),
  shared by the project screen's breakdown and the recordings list's filter
  chip so two switches over one closed enum cannot drift apart. The split is
  the point: the domain owns what a pendency *is* and which wire code names
  it, and neither of those knows what language the reader speaks. Keeping the
  translated string out means `domain/` never imports `AppLocalizations`, and
  so never imports Flutter — the layer rule in
  [/docs/adr/ADR-0011-architecture-dependency-rules.md](../../../../docs/adr/ADR-0011-architecture-dependency-rules.md).
  (`RecordingCard`'s footer keeps its own version — it collapses two or more
  pendencies into a count, which is a different sentence, not a different
  name.)
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
  adds `isUnclassified` and `hasSecondary` to `LocalRecordingEntity`.
  `hasSecondary` (added by ENG-196 once `RecordingCard` switched to the entity)
  delegates directly to the pure predicate `recordingHasSecondary` in
  [./entities/classification.dart](entities/classification.dart). As of
  ENG-374, `isUnclassified` no longer calls `recordingIsUnclassified`
  directly — it reads through `recordingPendencies` (above) instead, so it
  inherits the server-decides rule for any recording the server already knows
  about, and the breadcrumb/menu/quick-actions warning affordances can never
  disagree with the guided completion flow about whether a recording is
  classified. The row-level `RecordingClassification` extension this used to
  mirror was deleted once the presentation layer finished moving onto the
  entity (ENG-199/ENG-200) and it lost its last importer. The list state's
  `unclassified` filter reads `isUnclassified`; the list card reads both.
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
  columns straight off a Drift row. The row-level ergonomic extension that
  used to read those ids off a `LocalRecording` row and delegate to these
  functions lived in the data layer (ENG-175 / ENG-95 Phase 0); it was
  deleted in ENG-374 once the entity-side `LocalRecordingEntityClassification`
  extension (below) became the only caller — domain still owns the rule, but
  there is no longer a Drift-bound sugar layer on top of it.
- `recording_edit_policy.dart` is consumed only by the detail screen's
  `_canEditRecording` getter (see
  [../presentation/docs.md](../presentation/docs.md)). It is the single
  client-side authorization decision for a recording.
- It reaches across to the auth feature for the `User` entity
  ([/lib/features/auth/domain/entities/user.dart](../../auth/domain/entities/user.dart))
  and is fed the boolean result of `RoleNotifier.canManageProject`
  ([/lib/features/auth/data/providers/role_provider.dart](../../auth/data/providers/role_provider.dart)).
- `upload_status_actions.dart` (ENG-46) holds two predicates gating
  upload-adjacent affordances, both built on the shared `isRetryableFailure`
  (ENG-404): `recording_detail_screen.dart`'s Retry button calls
  `canRetryUpload`, and `recordings_list_screen.dart`'s bulk-retry button
  calls `hasRetryableFailedUploads`. Both started as inline boolean
  expressions in the presentation layer and moved here in two steps —
  extracted alongside the ENG-46 fix, then relocated from `presentation/`
  into `domain/` as a pure follow-up refactor once it was clear neither
  function touches Flutter, Riverpod, or Drift — following the
  `recording_edit_policy.dart` precedent above: same shape (a pure predicate
  consumed by exactly the screen it gates), same test placement under
  `test/features/recording/domain/`. ENG-407 deliberately did **not** add a
  third one here: the "does the server have this recording?" question its
  cache clear needed was already answered by `serverHasRecording` in
  `server_deletion_policy.dart` below, and cloning a predicate that guards
  against losing audio is how the two copies drift apart.
- `server_deletion_policy.dart` (ENG-45) is the single definition of which
  local row a hard delete on the server is *allowed* to erase. It is a
  necessary condition, never a sufficient one: both consumers pair it with a
  confirmed 404 for that specific recording — `RecordingDetailNotifier`'s
  metadata-heal branch, and, since ENG-400, `RecordingsListNotifier`'s sweep,
  where absence from the listing only nominates a candidate (see
  [../presentation/notifiers/docs.md](../presentation/notifiers/docs.md)).

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
- `isRetryableFailure(uploadStatus)` (ENG-404) is true for `failed` and
  `failed_exhausted` — the two failures a bare retry can still move, because
  `failed` is still inside the queue (a retry just skips the backoff wait)
  and `failed_exhausted` only needs its budget handed back.
  `failed_conflict`, `failed_description`, and `failed_missing_file` are
  excluded: each would be refused the same way on the next attempt (a
  duplicate title, a description under the minimum, or no audio file at
  all), and each already has its own banner leading to its own fix. Both
  `canRetryUpload` and `hasRetryableFailedUploads` below delegate to it, so
  the two affordances cannot disagree about which statuses a retry can
  touch.
- `canRetryUpload(uploadStatus, retryCount)` returns true for
  `isRetryableFailure(uploadStatus)` or `local` with `retryCount > 0` (a row
  that already burned at least one attempt before landing back on `local`,
  e.g. via `resetAndRetry`). It excludes `uploading`: the upload is already
  happening, so offering Retry there would queue a second attempt on top of
  the one in flight and reset a budget that has not actually been spent.
- `hasRetryableFailedUploads(recordings)` is true iff at least one entity in
  the iterable satisfies `isRetryableFailure`. It mirrors — deliberately, by
  scope not by shared code — the `WHERE` clause
  `LocalRecordingRepository.requeueFailedUploads` uses (see
  [../data/repositories/docs.md](../data/repositories/docs.md)), so the
  list's bulk-retry button only ever appears over a set the write would
  actually touch. Nothing enforces the two stay in sync beyond both being
  reviewed together and the shared `isRetryableFailure` predicate; a future
  change to one without the other would reopen the ENG-46 shape of bug (an
  affordance advertising an action it does not perform, or an action
  reaching rows the button never showed).
- `serverHasRecording({serverId, uploadStatus})` returns true only
  for a non-empty `serverId` whose `uploadStatus` is `uploaded` or
  `verified`; an empty string and a null id are the same "no id" case. Any
  other status means the row may never have completed the
  round trip to the server — `markAsUploaded` is what writes `uploaded`
  alongside the server id, so anything still `local`/`uploading`/`failed`
  may be the only copy of that audio, and no caller may erase it no
  matter what the server answers (ENG-45, after the loss in PR #193). It was
  named `canEraseAsDeletedOnServer` until ENG-407 gave it a second caller that
  is not about server-side deletion at all, so it now states the fact
  ("the server has this recording") and lets each caller supply its own reason
  to care. Two callers, one definition on purpose:
  - The **heal paths** treat it as a *necessary* condition and pair it with a
    confirmed 404 for that specific recording (see
    [../presentation/notifiers/docs.md](../presentation/notifiers/docs.md)) —
    only a recording the server acknowledged can be *missing* from it.
  - **`SyncNotifier.clearLocalCache`** (ENG-407, `@/lib/features/sync/docs.md`)
    treats it as *sufficient* on its own: no 404 confirmation, because a cache
    clear never asks the server anything. Getting it wrong there is asymmetric
    by design — keeping a copy the server already has costs disk space,
    dropping one it does not costs the recording, which is why both conditions
    are required rather than either alone.

  Resist cloning this condition for a third caller. ENG-407 first shipped a
  second copy of it in `upload_status_actions.dart` and that was reverted: a
  duplicated safety predicate is how someone tightens one and forgets the
  other, and the cost of forgetting is lost audio. If a future caller needs a
  different rule, it needs a different *rule*, not a copy of this one. (PR #193
  was an earlier, abandoned attempt at the ENG-407 fix.)

### Things to Know

- **`LocalRecordingEntity` hand-writes value equality, and that is
  load-bearing (ENG-195).** Unlike the `Storyteller` entity (which has no
  equality override), it overrides `operator ==`/`hashCode` across its whole
  field set — a new pattern for this codebase's entities, demanded by the watch
  stream. The data layer maps row→entity *before* `.distinct()` on the watch
  stream, so dedup keys on this `==` rather than the Drift row's generated
  equality. Without the override, each emission would be a fresh unequal object
  and `.distinct()` would never collapse anything. `pendingMetadataFields`
  (ENG-403) needs the same treatment as `reviewFlags` below for the same
  reason — it is a `Set`, which also compares by identity — but its
  comparison is order-insensitive (`containsAll` + length,
  `Object.hashAllUnordered`) where `reviewFlags`'s is order-sensitive: a
  `Set`'s iteration order carries no meaning the way the server's flag order
  does.
- **The equality check is split into private grouped comparisons
  (`_sameSubject`, `_sameClassification`, `_sameAudio`, `_sameUpload`,
  `_sameSplit`, ENG-374).** Adding `reviewFlags` pushed `operator ==` over the
  `dart_code_linter` cyclomatic-complexity gate (the ratchet itself is
  ENG-208). The grouping is by what each field describes, not by any
  difference in comparison strategy — every field still participates in one
  `&&` chain. `reviewFlags` needs its own helper, `_sameFlags`, for a
  different reason: a `List` compares by identity, so two structurally
  identical entities would otherwise read as unequal and the watch stream's
  `.distinct()` would rebuild on every emission. `_sameFlags` is
  order-sensitive, which relies on the server always emitting the flags in a
  stable order.
- **`reviewFlags` has two known gaps; the guided completion flow (ENG-374
  PR-B) exposes them rather than fixing them.** First, only the *insert*
  branch of `LocalRecordingRepository.cacheDownloadedAudio` writes the field
  (see [../data/repositories/docs.md](../data/repositories/docs.md)); a
  recording this device already made and uploaded already has a local row,
  so it takes the *update* branch (which only ever touches `localFilePath`)
  and its flags stay at the `'[]'` default. Second, nothing clears a flag
  locally when the user fixes what it flagged. `CompleteFichaSheet`
  ([../presentation/docs.md](../presentation/docs.md)) marks a step done only
  once it drops out of a fresh `recordingPendencies` read, and every edit
  that reaches the server reloads the entity from the server's response — so
  online this reads as instant progress. **This still holds after ENG-399**,
  though not for the reason it used to: offline no longer stops the entity
  from being rebuilt — `classify`/`moveCategory`/`saveSecondary`
  ([../presentation/notifiers/docs.md](../presentation/notifiers/docs.md))
  write the new classification to the local row and call `load()` regardless
  of whether the server was reached (a refusal still returns early with the
  local row untouched, as before). What still blocks the step on the
  unreachable path is `_storeReviewFlags`: it is a no-op when there are no
  server flags to store, and an unreachable write's `reviewFlags` is always
  `null`, so the stale flags the reload reads are untouched —
  `recordingPendencies` for a server-known recording reads only
  `reviewFlags`, never the entity's own classification fields, so the step
  still cannot be checked off without connectivity.
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
- **`upload_status_actions.dart` exists because `RecordingDetailScreen`
  cannot be pumped in its loaded state in a widget test** — the hero
  player takes near-unbounded height under the test font (see
  [../presentation/docs.md](../presentation/docs.md)) — so a predicate
  that stayed inline on that screen could only be exercised by mounting
  something the test harness cannot render. Pulling it into a plain
  function over primitives/an entity is the same move ENG-374 made for
  `CompleteFichaOverlay`: when the screen a piece of logic lives on is
  untestable as a whole, the logic moves somewhere it can be tested
  directly instead of going unverified.

Created and maintained by Nori.
