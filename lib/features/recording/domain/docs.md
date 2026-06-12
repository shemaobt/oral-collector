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
  implements; callers depend on the abstraction so it can be mocked.
- The entities — `Recording`, `ServerRecording`, `Register` — are the
  shared vocabulary. `ServerRecording` is the API DTO that the data layer
  maps to the local `LocalRecording` Drift row.
- `classification.dart` is **not** an entity type: it is the
  `kUnclassifiedGenreId` sentinel const plus top-level pure predicate
  functions (`recordingHasGenre`, `recordingIsUnclassified`,
  `recordingHasSecondary`, …) keyed on ids. The ergonomic
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
