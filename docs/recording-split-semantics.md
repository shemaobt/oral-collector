# Recording Split Semantics

When a recording is split into N child segments, every field on the child rows comes from one of three sources: **inherited from parent**, **segment-specific**, or **reset to default**. This document is the single source of truth for that mapping.

Two implementations write child rows independently — the Flutter client (`_saveSplitLocally` → `LocalRecordingRepository.splitRecording`, native mobile) and the backend (`persist_split_segments` in `tripod-api`, web). Both implementations must follow this table. Both test suites assert against it.

## Field propagation table

| Field (client / server name) | Behavior | Source |
|---|---|---|
| `id` | new value per child | UUID generated for the child |
| `projectId` / `project_id` | inherit | parent.projectId |
| `genreId` / `genre_id` | segment override OR inherit | spec.genreId (if non-empty) else parent.genreId |
| `subcategoryId` / `subcategory_id` | segment override OR inherit | spec.subcategoryId (if non-empty) else parent.subcategoryId |
| `registerId` / `register_id` | segment override OR inherit | spec.registerId (if non-empty) else parent.registerId |
| `secondaryGenreId` / `secondary_genre_id` | **inherit** | parent.secondaryGenreId |
| `secondarySubcategoryId` / `secondary_subcategory_id` | **inherit** | parent.secondarySubcategoryId |
| `secondaryRegisterId` / `secondary_register_id` | **inherit** | parent.secondaryRegisterId |
| `storytellerId` / `storyteller_id` | **inherit** | parent.storytellerId |
| `userId` / `user_id` | **inherit** | parent.userId |
| `description` | **inherit** | parent.description |
| `title` | segment-specific | original title if N=1, otherwise `"{original} ({k+1}/{N})"` |
| `durationSeconds` / `duration_seconds` | segment-specific | end - start (from ffmpeg) |
| `fileSizeBytes` / `file_size_bytes` | segment-specific | size of the cut file |
| `format` | inherit | parent.format (typically `m4a`) |
| `localFilePath` (client) | segment-specific | new file path produced by ffmpeg |
| `gcs_url` (server) | segment-specific | new GCS blob URL of the cut |
| `uploadStatus` / `upload_status` | reset | `'local'` on client (child not uploaded yet); `VERIFIED` on server (child already in GCS) |
| `serverId` (client) | reset | `null` |
| `gcsUrl` (client) | reset | `null` |
| `md5Hash` (client) | reset | `null` |
| `uploadedBytes` (client) | reset | `0` |
| `resumableSessionUri` (client) | reset | `null` |
| `cleaning_status` / `cleaningStatus` | **reset** | `'none'` / `CleaningStatus.NONE` — split children must be re-cleaned |
| `cleaning_error` (server) | reset | `null` |
| `splitting_status` (server-only column) | reset | `SplittingStatus.NONE` (children are not themselves being split). The client schema has no equivalent column. |
| `splitFromId` / `split_from_id` | lineage | `parent.id` on server; **not set** on client (client deletes parent, so the link would dangle) |
| `splitIndex` / `split_index` | lineage | `k` (zero-based index) on server; not set on client |
| `splitSegmentCount` / `split_segment_count` | lineage | `N` (total kept segments) on server; not set on client |
| `recordedAt` / `recorded_at` | inherit | parent.recordedAt |
| `retryCount` (client) | reset | `0` |
| `lastRetryAt` (client) | reset | `null` |
| `uploaded_at` (server) | new value | `datetime.now(UTC)` — server already has the file in GCS |
| `createdAt` / `created_at` | new value | "now" |
| `updated_at` (server) | new value | "now" |

## Parent disposition after split

This is intentionally different between the two implementations:

- **Client (native)**: parent row is **deleted** from the local Drift DB; the server-side parent is also deleted via the existing `apiRepo.deleteRecording(serverId)` call.
- **Server (web)**: parent row is **kept** and marked `splitting_status = ARCHIVED_AFTER_SPLIT`.

This asymmetry pre-dates ENG-64 and is **not part of the contract this doc defines**. If you want to revisit it, file a separate ticket.

## Why this document exists

[ENG-64](https://linear.app/shema-obt/issue/ENG-64) reported silent data loss: the trim/split editor was wiping `description`, `storyteller_id`, `secondary_*`, and `user_id` from child recordings. Investigation found two parallel implementations of the split — one on the phone (`_saveSplitLocally`) and one on the server (`persist_split_segments`) — and both had been written omitting the same set of fields. The fix added the missing field propagation to both implementations and locked the contract behind this doc plus parallel unit tests.

If you change the propagation rules, update this table **and** both test files (`local_recording_repository_split_test.dart` and `test_oc_split_metadata.py`) in the same change.

## Cache hydration (server → local)

A second flavor of the same anti-pattern lived in the detail screen's "download for trim" code path. When the user opened a server-only recording and tapped Edit, `_ensureLocalFile()` downloaded the audio and hand-built a `LocalRecordingsCompanion` for the insert, omitting `description`, `storytellerId`, `userId`, `secondaryGenreId/SubcategoryId/RegisterId`, and the `splitFromId/splitIndex/splitSegmentCount` lineage. The `localRecordingStreamProvider` listener in the same screen would then re-render the recording with those fields as `null`. The user perceived this as "I tapped Edit, didn't change anything, and the description disappeared."

The contract is the same as the split table above: **every recording-level metadata field on the in-memory `LocalRecording` must reach the persisted row**. The canonical write site is now `LocalRecordingRepository.cacheDownloadedAudio(recording: …, localFilePath: …)`. It uses Drift's generated `toCompanion(false)` so the column list is always exhaustive — adding a new column to the `LocalRecordings` schema cannot silently divorce cache writes from the contract.

For rows already corrupted on a device before this fix landed, the detail screen heals them on the next online refresh via `buildHealMetadataCompanion(local, server)`. The bug omitted `userId` along with the user-content fields, so a local row with `userId IS NULL` paired with a server row that has one is the marker of corruption. When that marker is present, every user-content field on the row is rehydrated from the server. When it is absent, no user-content field is touched — so an intentionally cleared description (`''`) or a removed storyteller (`null`) survives a refresh instead of getting resurrected.

If you add a new `nullable` metadata column to `LocalRecordings`:

1. Make sure `serverRecordingToLocal` carries it from the server DTO.
2. Make sure `splitRecording` propagates it from parent to children (and update the table above).
3. Make sure `buildHealMetadataCompanion` heals it when the server has a value and the local row is empty.
4. Add the column to the cache tests in `local_recording_repository_cache_download_test.dart` and the heal tests in `recording_heal_companion_test.dart`.
