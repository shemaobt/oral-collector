# Noridoc: Home Notifiers

Path: @/lib/features/home/presentation/notifiers

### Overview

- `HomeNotifier` (`home_notifier.dart`) owns the home screen's greeting and
  the two numbers on its stats card: the recordings total and the
  unclassified count. `HomeState` (`home_state.dart`) is its immutable state.
- The home total is deliberately built as **two non-overlapping addends** —
  what the server already has, plus what only this device has — after an
  earlier formula that summed two overlapping local sets produced a
  different total on every device holding the identical recording list
  (ENG-355). That invariant is the reason this notifier exists as a
  standalone class rather than inline `Stats` math in the screen.

### How it fits into the larger codebase

- Reads the active project from
  [/lib/features/project/presentation/notifiers/project_notifier.dart](../../../project/presentation/notifiers/project_notifier.dart)
  and server-side genre aggregates from
  [/lib/features/project/presentation/notifiers/stats_notifier.dart](../../../project/presentation/notifiers/stats_notifier.dart)
  (`genreStats`, keyed by genre id, `kUnclassifiedGenreId` for the
  unclassified bucket).
- Reads the device-only addend from
  [/lib/features/recording/data/repositories/local_recording_repository.dart](../../../recording/data/repositories/local_recording_repository.dart)'s
  `getLocalOnlyStats` and `getLocalUnclassifiedStats`, via
  [/lib/features/recording/data/providers.dart](../../../recording/data/providers.dart).
- Consumed by
  [../home_screen.dart](../home_screen.dart), which drives *when* the
  notifier recomputes (see Core Implementation) — the notifier itself does
  not subscribe to anything.
- `getLocalOnlyStats`'s `uploadStatus NOT IN ('uploaded', 'verified')`
  predicate is the same status vocabulary the sync feature owns; see
  [/lib/features/sync/docs.md](../../../sync/docs.md) for what each
  `uploadStatus` value means and why some terminal statuses (`failed_conflict`,
  `failed_description`, `failed_exhausted`, `failed_missing_file`) are
  included here on purpose.

### Core Implementation

- `refreshAll()` reloads both addends from Drift (native only — `kIsWeb`
  skips the repository calls and the local addends stay `0`, so on web the
  total is purely the server's genre stats) and recomputes. It runs on pull-
  to-refresh and whenever the active project id changes
  ([../home_screen.dart](../home_screen.dart)).
- `computeTotals()` recomputes from the notifier's cached local fields plus
  whatever `statsNotifierProvider.genreStats` currently holds, **without**
  re-querying Drift. The screen calls it on every `genreStats` change
  (`ref.listen(statsNotifierProvider.select((s) => s.genreStats), ...)`), so
  a server-side stats refresh updates the card without a local re-query, and
  a local-only change (a new local recording, an upload finishing) requires
  `refreshAll()` to pick up the new device-only count.
- The formula: `totalRecordings = getLocalOnlyStats(projectId).count + Σ
  genreStats[*].recordingCount`, `totalDuration` mirrors it on
  `durationSeconds`. `unclassifiedCount` is computed separately —
  `getLocalUnclassifiedStats(projectId).count + genreStats[kUnclassifiedGenreId].recordingCount`
  — and is not part of the total formula; it powers a distinct badge that can
  overlap with the device-only addend (an unclassified local recording is
  counted in both numbers, which is correct — they answer different
  questions).

### Things to Know

- **The device addend must be a single query whose predicate partitions the
  local rows with no overlap (ENG-355).** The prior formula was
  `getPendingUploads().length + getLocalUnclassifiedStats().count`: a `local`,
  unclassified recording matched both queries and was counted twice, while a
  *classified* recording parked in a terminal `failed_*` state matched
  neither and vanished from the total. Both queries were legitimate on their
  own — `getPendingUploads` answers "what's queued", `getLocalUnclassifiedStats`
  answers "what's unclassified" — but neither answers "what does only this
  device have", and summing two answers to different questions is what
  produced the bug. `getLocalOnlyStats`'s predicate (`uploadStatus NOT IN
  ('uploaded', 'verified')`) is chosen specifically so it is impossible for a
  local row to fall outside it or be double-counted within it. Do not
  reintroduce a sum of thematic subsets here even if a new terminal status is
  added later — extend or replace this single query instead.
- **A `failed_conflict` / `failed_description` / `failed_exhausted` /
  `failed_missing_file` row counts in the home total, on purpose.** These are
  all "the device has it, the server does not" — exactly what the total is
  supposed to answer — and the recordings list already surfaces them under
  its pending filter for the same reason (see
  [/lib/features/sync/docs.md](../../../sync/docs.md)). This is a deliberate
  semantics decision made alongside the ENG-355 fix, not an incidental side
  effect of the new query's predicate.
- **The unclassified count and the total's device addend are allowed to
  overlap.** They are two separate numbers answering two separate questions
  ("how many recordings total" vs "how many need classification"), unlike
  the two addends *within* the total, which must not overlap.

Created and maintained by Nori.
