# ADR-0008: Data serialization & typing — manual safe-readers

- Status: Accepted
- Date: 2026-06-05
- Epic: E8 (Data Serialization & Typing)
- Related: ENG-97 (epic), ENG-98 (investigation), ENG-147 (this change), ENG-146/148/149/150/152/153 (follow-ups), ADR-0001 (error model), ENG-81 (`needs-api`)

## Context

Every API entity is (de)serialized by hand with non-null force-casts: `json['id'] as String`, `(json['duration_seconds'] as num).toDouble()`, `DateTime.parse(json['recorded_at'] as String)`, nested `data['tokens']['access_token']`. A single missing field or wrong type throws a `TypeError`/`NoSuchMethodError` — both `Error`, **not** `Exception`, so they escape `on Exception` handlers and can blank an entire list page, fail login, or crash sync. The audit found ~23 files with hand-written `fromJson` (49 factories), ~241 force-casts, and ~0 round-trip tests.

The E8 investigation (ENG-98) evaluated codegen. `freezed` was **rejected**: it re-shapes every entity (equality/constructors change → not behavior-preserving) and does not fix the unsafe casts. `json_serializable` generates the same unsafe casts by default. The defect is the untyped, throw-on-`Error` parsing, not the lack of generated boilerplate.

The wire contract was verified against the backend (`tripod-api`, FastAPI + Pydantic v2): timestamps are ISO-8601 with a UTC offset; `duration_seconds` is a genuine `float` while other numerics are `int`; `tokens`/`user` are nested objects; nullable fields are explicit. The design below matches that contract with no API change required for this work.

## Decision

We will introduce hand-written **typed safe-readers** — no codegen — and migrate the call sites incrementally, behavior-preserving, keeping the wire format byte-identical.

- **Safe-readers** (`lib/core/serialization/`): pure top-level functions `readString/readInt/readDouble/readBool/readDate/readMap` and their `…OrNull` variants, each taking `(Map<String, dynamic> json, String key)`. They throw a `ParseException` on contract violation instead of a raw cast's uncatchable `Error`.
  - `readX` requires the key present, non-null and of the expected type.
  - `readXOrNull` returns null for an absent/null key but **throws** on a present value of the wrong type — a malformed value is a contract violation, not an optional miss (equivalent to `as T?`, only the throw type changes from `Error` to `Exception`).
  - Numerics accept any `num` and convert (`.toInt()`/`.toDouble()`), mirroring the existing `(x as num).toInt()` sites. `readInt` guards non-finite doubles (`NaN`/`Infinity`) into a `ParseException` rather than the `UnsupportedError` that `toInt()` would throw.
  - `readDate` parses an ISO-8601 String via `DateTime.parse`; a `FormatException` becomes a `ParseException`. Tolerance beyond String+parse is out of scope (ENG-152).
  - `readMap` is load-bearing: it converts the `NoSuchMethodError` of a chained `data['x']['y']` (when `x` is absent) into a `ParseException`, and returns a typed `Map<String, dynamic>` so reads chain.
- **`ParseException extends AppException`** (the sealed hierarchy of ADR-0001), carrying `field` (the JSON key) and `expected` (a type label) for diagnostics. It keeps the invariant: `cause` holds the raw value but `toString()` redacts it to its runtime type — never the value.
- **Tolerant enums** (`fromWire` → unknown sentinel, never throws) for `UploadStatus`/`CleaningStatus`/`StorytellerSex` (ENG-150).
- **Element-isolating `parseList<T>`** (ENG-146) that maps element-by-element, skipping+logging a bad record.
- **Page policy:** collection endpoints **skip-and-log** a bad record (one bad row cannot blank a screen); single-object reads (`getProject`, login) **fail**.

## Consequences

- `ParseException` is a `final` leaf of the `sealed AppException`, so adding it forced a new arm in the exhaustive `messageForException` switch — it maps to `error_generic` (a parse failure is not user-actionable). Dedicated l10n copy is a follow-up (touches the `.arb` files); reusing `error_generic` avoids that churn now, consistent with ADR-0001.
- Migration is incremental: ENG-147 ships the helpers + `ParseException`, fully unit-tested, with **no call-site migration**. Quick-wins, list repos, and leaf reads follow in ENG-148/146/153; dead `LocalRecording` consolidation in ENG-149.
- **ENG-150 / ENG-152 (entity parsing):** the seven entity `fromJson` factories now route every timestamp through `readDate`/`readDateOrNull` (ENG-152), and `StorytellerSex` became a tolerant enum — `fromWire` maps an unrecognized value to an `unknown` sentinel instead of throwing `ArgumentError`, while `toWire` stays byte-identical for `male`/`female`. The `UploadStatus`/`CleaningStatus` enums named in the Decision are **deferred**: they stay wire `String`s (now read via `readString`) because converting them touches ~200 client call sites plus the Drift text columns, their canonical value sets are still `needs-api` (ENG-81), and — unlike `StorytellerSex` — they never threw an uncatchable `Error` (the UI status switches already fall through to safe defaults).
- The `StorytellerSex.unknown` sentinel is **read-tolerant only**: it keeps a corrupt or future value from crashing a read, but is not yet write-safe — the edit form (`_canSubmit`) and the local-sync passthrough (`'sex': row.sex`) can still round-trip it back to a server that only knows `male`/`female`. This is latent (the server emits neither today), so hardening the write side — treating `unknown` as unsubmittable — is a follow-up rather than part of this change.
- `readInt` accepting any `num` relaxes the one hard `as int` site (`server_recording.dart`) to also accept `5.0`; the server sends integers, so this is inert in practice and removes the last non-`num` numeric cast.
- **Cross-stack (`needs-api`, ENG-81):** the verified contract surfaced drift to record for the API phase — `subcategory_id` is non-null server-side though the client parses it as nullable (over-lenient; tightenable later); `Invite.status` is not an authoritative `Literal` server-side (blocks fully-tolerant enum mapping); the authoritative enum value sets are now documented. A shared OpenAPI/codegen contract would let client and API share types and remove this drift — the durable fix, logged in ENG-81.
- No new dependency; `build_runner` stays Drift-only.

## Note on ADR file naming

The accepted ADRs `0001-sealed-app-exception.md` and `0006-pluggable-error-reporter-telemetry.md` dropped the `ADR-` filename prefix mandated by ADR-0000 and are absent from its index. This ADR follows the documented `ADR-NNNN-` convention; harmonizing the two misnamed files and the index is a small follow-up, not in scope here.
