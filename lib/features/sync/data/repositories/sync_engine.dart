import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/config/upload_retry_policy.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_exception.dart'
    show
        AppException,
        ConflictException,
        ForbiddenException,
        UnauthorizedException;
import '../../../../core/network/authenticated_client.dart';
import '../../../../core/network/response_decoder.dart';
import '../../../../core/platform/file_ops.dart' as file_ops;
import '../../../../core/serialization/safe_read.dart';
import '../../../../shared/utils/recording_description.dart';
import '../../../recording/data/repositories/local_recording_repository.dart';
import '../../../recording/domain/entities/pending_metadata_field.dart';
import '../../../recording/domain/entities/review_flag.dart';
import '../../../recording/domain/repositories/recording_api_repository.dart';
import '../../../storyteller/data/repositories/local_storyteller_repository.dart';
import '../../domain/repositories/connectivity_service.dart';
import '../../domain/repositories/sync_engine.dart';
import '../pending_metadata_request.dart';
import '../services/resumable_upload_service.dart';
import '../services/upload_downloader.dart';

const List<Duration> _kBackoffLadder = [
  Duration(seconds: 5),
  Duration(seconds: 15),
  Duration(seconds: 30),
  Duration(seconds: 60),
];

const double _kBackoffJitterFraction = 0.5;

/// Retry backoff for [attempt] (1-based): the [_kBackoffLadder] rung plus
/// additive random jitter in `[0, base * _kBackoffJitterFraction]`. The jitter
/// de-synchronizes retries from devices that failed at the same instant so they
/// don't realign on one schedule; it never shortens the delay below the rung.
/// Attempts past the ladder saturate at the last rung.
Duration backoffWithJitter(int attempt, Random random) {
  final index = (attempt - 1).clamp(0, _kBackoffLadder.length - 1);
  final base = _kBackoffLadder[index];
  final maxJitterMs = (base.inMilliseconds * _kBackoffJitterFraction).round();
  final jitterMs = maxJitterMs <= 0 ? 0 : random.nextInt(maxJitterMs + 1);
  return base + Duration(milliseconds: jitterMs);
}

/// Outcome of a single `_uploadRecording` attempt. `processQueue` uses it to
/// decide whether to re-probe connectivity (only on [failed]).
enum _UploadOutcome { uploaded, skipped, failed }

class SyncEngineImpl implements SyncEngine {
  static final _log = Logger('SyncEngine');

  final LocalRecordingRepository _recordingRepo;
  final LocalStorytellerRepository _storytellerRepo;
  final ConnectivityService _connectivity;
  final AuthenticatedClient _client;

  /// The metadata drain goes through the API repository rather than [_client]
  /// so it inherits the one place that knows what `PATCH /recordings/{id}`
  /// means: 403 as a refusal, 409 as a name clash, and the review flags the
  /// server recomputes on every accepted write (ENG-403).
  final RecordingApiRepository _recordingApi;
  late final ResumableUploadService _uploadService;

  static const Duration _apiTimeout = Duration(seconds: 30);

  final Random _random = Random();
  bool _isProcessing = false;

  SyncEngineImpl({
    required LocalRecordingRepository recordingRepo,
    required LocalStorytellerRepository storytellerRepo,
    required ConnectivityService connectivity,
    required AuthenticatedClient client,
    required RecordingApiRepository recordingApi,
    UploadDownloader? uploadDownloader,
  }) : _recordingRepo = recordingRepo,
       _storytellerRepo = storytellerRepo,
       _connectivity = connectivity,
       _client = client,
       _recordingApi = recordingApi {
    _uploadService = ResumableUploadService(
      client: _client,
      recordingRepo: _recordingRepo,
      downloader: uploadDownloader,
    );
  }

  @override
  bool get isProcessing => _isProcessing;

  bool _isWithinBackoffWindow(int retryCount, DateTime? lastRetryAt) {
    if (retryCount <= 0 || lastRetryAt == null) return false;
    final backoff = backoffWithJitter(retryCount, _random);
    return DateTime.now().difference(lastRetryAt) < backoff;
  }

  @override
  Future<void> processQueue({
    bool deleteAfterUpload = false,
    bool wifiOnly = false,
    int maxConcurrency = 1,
    void Function(String recordingId, int bytesSent, int totalBytes)?
    onProgress,
  }) async {
    // Set the guard before any await so two rapid callers can't both pass the
    // check while one is mid-connectivity-probe. The previous ordering left a
    // window where a second processQueue() entered before the first set the
    // flag, doubling the work and racing the coordinator's resume.
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      final online = await _connectivity.isOnline;
      if (!online) return;

      // Above the Wi-Fi gate on purpose (ENG-403): that preference exists to
      // keep megabytes of audio off a metered connection, and a metadata PATCH
      // is a few hundred bytes. The product rule is that an edit goes up when
      // the connection returns, not when Wi-Fi does.
      await _processPendingMetadata();

      if (wifiOnly) {
        final onWifi = await _connectivity.isOnWifi;
        if (!onWifi) return;
      }

      await _processPendingStorytellers();

      final pending = await _recordingRepo.getPendingUploads();

      final eligible = <LocalRecording>[];
      for (final recording in pending) {
        if (recording.retryCount >= kMaxUploadRetries) continue;
        // A row still in `uploading` is either in flight now or was reclaimed
        // at startup (resetStuckUploading); the drain must not start a second
        // attempt for it.
        if (recording.uploadStatus == 'uploading') continue;

        if (_isWithinBackoffWindow(
          recording.retryCount,
          recording.lastRetryAt,
        )) {
          continue;
        }

        eligible.add(recording);
      }

      if (maxConcurrency <= 1) {
        await _drainSerially(
          eligible,
          wifiOnly: wifiOnly,
          deleteAfterUpload: deleteAfterUpload,
          onProgress: onProgress,
        );
      } else {
        await _drainConcurrently(
          eligible,
          maxConcurrency: maxConcurrency,
          wifiOnly: wifiOnly,
          deleteAfterUpload: deleteAfterUpload,
          onProgress: onProgress,
        );
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _drainSerially(
    List<LocalRecording> eligible, {
    required bool wifiOnly,
    required bool deleteAfterUpload,
    void Function(String recordingId, int bytesSent, int totalBytes)?
    onProgress,
  }) async {
    for (final recording in eligible) {
      // The Wi-Fi-only policy is a network-TYPE constraint: a Wi-Fi→cellular
      // switch keeps uploads succeeding, so it can't be inferred from an
      // upload outcome — it must be re-checked per item. Reachability
      // (isOnline), by contrast, surfaces as an upload failure, so it is
      // sampled once at the gate and only re-probed after a failure
      // (ENG-125).
      if (wifiOnly && !await _connectivity.isOnWifi) break;

      final outcome = await _uploadRecording(
        recording.id,
        recording.localFilePath,
        deleteAfterUpload: deleteAfterUpload,
        onProgress: onProgress,
      );

      if (await _failedAndOffline(outcome)) break;
    }
  }

  Future<void> _drainConcurrently(
    List<LocalRecording> eligible, {
    required int maxConcurrency,
    required bool wifiOnly,
    required bool deleteAfterUpload,
    void Function(String recordingId, int bytesSent, int totalBytes)?
    onProgress,
  }) async {
    var index = 0;
    final active = <Future<void>>[];
    // Set once we should stop the pass (Wi-Fi-only policy broken, or an
    // upload failed and a re-probe confirms we are offline); it stops
    // admitting new uploads while the in-flight ones drain.
    var stopAdmitting = false;

    while (index < eligible.length || active.isNotEmpty) {
      while (!stopAdmitting &&
          index < eligible.length &&
          active.length < maxConcurrency) {
        // Re-check the Wi-Fi-only policy per admit: a Wi-Fi→cellular switch
        // keeps uploads succeeding, so it can't be inferred from outcomes
        // (see the serial loop for the isOnline/isOnWifi rationale).
        if (wifiOnly && !await _connectivity.isOnWifi) {
          stopAdmitting = true;
          break;
        }
        final recording = eligible[index++];
        late final Future<void> entry;
        entry =
            _uploadRecording(
                  recording.id,
                  recording.localFilePath,
                  deleteAfterUpload: deleteAfterUpload,
                  onProgress: onProgress,
                )
                .then((outcome) async {
                  if (await _failedAndOffline(outcome)) stopAdmitting = true;
                })
                .whenComplete(() => active.remove(entry));
        active.add(entry);
      }

      if (active.isNotEmpty) {
        await Future.any(active);
      } else {
        break;
      }
    }
  }

  Future<bool> _failedAndOffline(_UploadOutcome outcome) async =>
      outcome == _UploadOutcome.failed && !await _connectivity.isOnline;

  @override
  Future<void> uploadSingle(
    String recordingId, {
    bool deleteAfterUpload = false,
    void Function(String recordingId, int bytesSent, int totalBytes)?
    onProgress,
  }) async {
    final recording = await _recordingRepo.getRecordingById(recordingId);
    if (recording == null) return;

    final online = await _connectivity.isOnline;
    if (!online) return;

    await _uploadRecording(
      recording.id,
      recording.localFilePath,
      deleteAfterUpload: deleteAfterUpload,
      onProgress: onProgress,
    );
  }

  Future<String?> _resolveFilePath(String storedPath) async {
    if (kIsWeb) return storedPath;

    if (await file_ops.fileExists(storedPath)) return storedPath;

    final docsDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(storedPath);

    final resolved = '${docsDir.path}/$fileName';
    if (await file_ops.fileExists(resolved)) return resolved;

    final inSubdir = '${docsDir.path}/recordings/$fileName';
    if (await file_ops.fileExists(inSubdir)) return inSubdir;

    return null;
  }

  Future<_UploadOutcome> _uploadRecording(
    String id,
    String localFilePath, {
    bool deleteAfterUpload = false,
    void Function(String recordingId, int bytesSent, int totalBytes)?
    onProgress,
  }) async {
    try {
      final resolvedPath = await _resolveFilePath(localFilePath);
      if (resolvedPath == null) {
        // Terminal, not a retry: _resolveFilePath has already looked in all
        // three places the app ever puts a recording, and deletion is a hard
        // delete, so no later pass will find what this one could not. Marking
        // it failed without spending a retry (as this used to) left the row
        // pending forever — reselected on every drain, skipped on every drain.
        _log.warning('local audio file missing for $id');
        await _markPermanentlyFailed(id, status: 'failed_missing_file');
        return _UploadOutcome.skipped;
      }
      if (resolvedPath != localFilePath) {
        await _recordingRepo.updateRecording(
          id,
          LocalRecordingsCompanion(localFilePath: Value(resolvedPath)),
        );
      }

      final recording = await _recordingRepo.getRecordingById(id);
      if (recording == null) return _UploadOutcome.skipped;

      await _recordingRepo.markAsUploading(id);

      String serverId;

      if (recording.serverId != null && recording.serverId!.isNotEmpty) {
        serverId = recording.serverId!;
      } else {
        // Pre-flight, not a diagnosis of the refusal: the create call requires
        // a sufficient description and the client owns the same rule, so a row
        // that predates it (or a split child that inherited a short parent
        // description) is refused here instead of spending a round-trip to be
        // told. Deliberately not inferred from the 422 — other things 422 on
        // this endpoint, and a wrong explanation is worse than none.
        if (!isDescriptionSufficient(recording.description)) {
          _log.warning('description too short to create $id');
          await _markPermanentlyFailed(id, status: 'failed_description');
          return _UploadOutcome.failed;
        }

        final subcategoryId =
            (recording.subcategoryId != null &&
                recording.subcategoryId!.isNotEmpty)
            ? recording.subcategoryId
            : 'unclassified';
        final createBody = <String, dynamic>{
          'project_id': recording.projectId,
          'genre_id': recording.genreId,
          'subcategory_id': subcategoryId,
          'title': recording.title,
          'description': recording.description,
          'duration_seconds': recording.durationSeconds,
          'file_size_bytes': recording.fileSizeBytes,
          'format': recording.format,
          'recorded_at': recording.recordedAt.toUtc().toIso8601String(),
        };
        _addOptionalCreateFields(createBody, recording);
        if (recording.storytellerId != null &&
            recording.storytellerId!.isNotEmpty) {
          final resolvedStorytellerId = await _resolveStorytellerServerId(
            recording.storytellerId!,
          );
          if (resolvedStorytellerId == null) {
            _log.info(
              'skipping recording $id, referenced storyteller '
              '${recording.storytellerId} is not yet synced',
            );
            // Undo the optimistic markAsUploading so the row stays drain-eligible
            // once the storyteller syncs. Without this the uploading-skip in
            // processQueue would strand it until the next app restart.
            await _recordingRepo.updateRecording(
              id,
              const LocalRecordingsCompanion(uploadStatus: Value('local')),
            );
            return _UploadOutcome.skipped;
          }
          createBody['storyteller_id'] = resolvedStorytellerId;
        }
        final createResponse = await _client
            .post('/api/oc/recordings', body: createBody)
            .timeout(_apiTimeout);

        // Only *this* call deduplicates on (project_id, title), so only a 409
        // here is a name clash. Handled inline rather than in a catch arm: a
        // 409 raised anywhere else below (confirm-upload) has no rename that
        // could clear it, and parking those rows in failed_conflict would offer
        // the user an exit that leads straight back here.
        if (createResponse.statusCode == 409) {
          _log.warning('title conflict for $id');
          await _markPermanentlyFailed(id, status: 'failed_conflict');
          return _UploadOutcome.failed;
        }

        final createData = decodeObject(createResponse);
        serverId = readString(createData, 'id');

        // The create response is the first and only time the server states what
        // this recording still owes, and it recomputes before answering
        // (ENG-373). Stored in the same write as the `serverId` on purpose: the
        // two facts arrive together, and from the moment the `serverId` lands
        // the flags are what the pendency rule reads (ENG-379) — a second,
        // later write would leave a window where an uploaded recording reads as
        // complete. Extending `markAsUploaded` would open exactly that window,
        // and would lose the flags entirely when the transfer fails even though
        // the server already knows them.
        //
        // `readReviewFlagsOrNull` cannot throw, so joining it to the `serverId`
        // write adds no way for this to cost the upload.
        final createdFlags = readReviewFlagsOrNull(createData);
        await _recordingRepo.updateRecording(
          id,
          LocalRecordingsCompanion(
            serverId: Value(serverId),
            reviewFlagsJson: createdFlags == null
                ? const Value.absent()
                : Value(encodeReviewFlags(createdFlags)),
          ),
        );
      }

      final uploadResult = await _uploadService.upload(
        recordingId: id,
        serverId: serverId,
        localFilePath: resolvedPath,
        format: recording.format,
        fileSizeBytes: recording.fileSizeBytes,
        onProgress: onProgress != null
            ? (sent, total) => onProgress(id, sent, total)
            : null,
      );

      if (uploadResult.pausedByRecording) {
        await _recordingRepo.updateRecording(
          id,
          const LocalRecordingsCompanion(uploadStatus: Value('local')),
        );
        return _UploadOutcome.skipped;
      }

      if (!uploadResult.success) {
        throw Exception('Upload failed: ${uploadResult.error}');
      }

      final confirmBody = <String, dynamic>{};
      if (uploadResult.clientCrc32c != null) {
        confirmBody['crc32c'] = uploadResult.clientCrc32c;
      }

      final confirmResponse = await _client
          .post(
            '/api/oc/recordings/$serverId/confirm-upload',
            body: confirmBody,
          )
          .timeout(_apiTimeout);

      final confirmData = decodeObject(confirmResponse);
      final gcsUrl = readStringOrNull(confirmData, 'gcs_url');

      await _recordingRepo.markAsUploaded(id, serverId, gcsUrl);

      if (deleteAfterUpload && !kIsWeb) {
        await file_ops.deleteFile(resolvedPath);
      }
      return _UploadOutcome.uploaded;
    } on AppException catch (e, st) {
      // Retry decision by the typed flag (ENG-103), not by exception subtype.
      if (e.retryable) {
        _log.warning('retryable upload failure for $id', e);
        await _recordingRepo.markAsFailed(id);
      } else {
        // Warning, not severe: non-retryable here is dominated by expected
        // conditions (expired-session 401/403, server validation/conflict), so
        // keep it off the reporter. Genuinely malformed payloads surface via the
        // FormatException arm below.
        _log.warning('permanent upload failure for $id', e, st);
        await _markPermanentlyFailed(id);
      }
    } on FormatException catch (e, st) {
      // Server returned a non-JSON body. Retrying won't help; mark terminal.
      _log.severe('response parse error for $id', e, st);
      await _markPermanentlyFailed(id);
    } on Exception catch (e, st) {
      // Transport faults (socket/timeout/filesystem) and other transient
      // Exception subtypes → retry. Programmer errors (Error subtypes like
      // TypeError, StateError) are NOT caught here — they propagate as bugs.
      _log.warning('unexpected error uploading $id', e, st);
      await _recordingRepo.markAsFailed(id);
    }
    return _UploadOutcome.failed;
  }

  Future<void> _processPendingStorytellers() async {
    final pending = await _storytellerRepo.getPendingSyncs();
    for (final row in pending) {
      if (_isWithinBackoffWindow(row.retryCount, row.lastRetryAt)) continue;

      final stillOnline = await _connectivity.isOnline;
      if (!stillOnline) return;

      try {
        await _storytellerRepo.markUploading(row.id);

        final body = <String, dynamic>{
          'name': row.name,
          'sex': row.sex,
          'external_acceptance_confirmed': row.externalAcceptanceConfirmed,
          if (row.age != null) 'age': row.age,
          if (row.location != null && row.location!.isNotEmpty)
            'location': row.location,
          if (row.dialect != null && row.dialect!.isNotEmpty)
            'dialect': row.dialect,
        };

        final response = await _client
            .post('/api/oc/projects/${row.projectId}/storytellers', body: body)
            .timeout(_apiTimeout);

        if (response.statusCode != 201 && response.statusCode != 200) {
          _log.warning(
            'storyteller ${row.id} failed '
            'with ${response.statusCode}: ${response.body}',
          );
          await _storytellerRepo.markFailed(row.id);
          continue;
        }

        final data = decodeObject(response);
        final serverId = readString(data, 'id');
        await _storytellerRepo.markUploaded(row.id, serverId);
        await _recordingRepo.reassignStorytellerId(
          fromId: row.id,
          toId: serverId,
        );
      } on TimeoutException catch (e) {
        _log.warning('timeout syncing storyteller ${row.id}', e);
        await _storytellerRepo.markFailed(row.id);
      } on SocketException catch (e) {
        _log.warning('socket error syncing storyteller ${row.id}', e);
        await _storytellerRepo.markFailed(row.id);
      } on Exception catch (e) {
        _log.warning('error syncing storyteller ${row.id}', e);
        await _storytellerRepo.markFailed(row.id);
      }
    }
  }

  @override
  Future<void> processPendingMetadata() async {
    // Takes the same bail-if-busy guard as [processQueue], which already drains
    // this queue: whichever runs first wins, so the two can never both be
    // pushing the same row.
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      if (!await _connectivity.isOnline) return;
      await _processPendingMetadata();
    } finally {
      _isProcessing = false;
    }
  }

  /// First queue of the pass (ENG-403): metadata edits made while the server
  /// was out of reach.
  ///
  /// Same shape as [_processPendingStorytellers] on purpose — selection by
  /// predicate, the shared [_isWithinBackoffWindow], and no schedule of its own:
  /// the reconnect hook that already calls `processQueue` is what makes an
  /// offline edit go up by itself.
  Future<void> _processPendingMetadata() async {
    final pending = await _recordingRepo.getPendingMetadataSyncs();
    for (final row in pending) {
      if (_isWithinBackoffWindow(
        row.metadataRetryCount,
        row.metadataLastRetryAt,
      )) {
        continue;
      }

      final stillOnline = await _connectivity.isOnline;
      if (!stillOnline) return;

      if (await _pushPendingMetadata(row)) return;
    }
  }

  /// Sends one row's owed fields. Returns true when the metadata queue must
  /// give up for this pass; the rest of [processQueue] carries on regardless.
  Future<bool> _pushPendingMetadata(LocalRecording row) async {
    final fields = decodePendingMetadataFields(row.pendingMetadataJson);
    if (fields.isEmpty) {
      // Queued but owing nothing: a row written by a build whose field names
      // this one does not know. Clearing it beats reselecting it every pass.
      await _recordingRepo.clearPendingMetadataFields(
        row.id,
        PendingMetadataField.values.toSet(),
      );
      return false;
    }

    try {
      final outcome = await _recordingApi
          .updateRecording(
            row.serverId!,
            buildPendingMetadataRequest(row, fields),
          )
          .timeout(_apiTimeout);
      if (!outcome.success) {
        await _recordingRepo.markMetadataSyncFailed(row.id);
        return false;
      }
      // Compare-and-clear against the row the request was built from: an edit
      // that landed while the PATCH was in flight must stay owed, or the server
      // keeps the older value and the device the newer one with nothing left to
      // reconcile them.
      await _recordingRepo.clearPushedMetadataFields(row.id, fields, row);
      final flags = outcome.reviewFlags;
      if (flags != null) {
        await _recordingRepo.updateReviewFlags(row.id, flags);
      }
    } on ForbiddenException catch (e) {
      // Insisting cannot grant permission, and offering a retry would advertise
      // a way out that leads nowhere.
      _log.warning('metadata refused for ${row.id}', e);
      await _recordingRepo.markMetadataSyncTerminal(
        row.id,
        status: MetadataSyncStatus.failedForbidden,
      );
    } on ConflictException catch (e) {
      // The backend deduplicates on (project_id, title), and PATCH 409s on a
      // clash the same way create does. Terminal under the upload queue's own
      // name for it, because it has the same exit: renaming re-marks the row
      // pending with a fresh budget.
      _log.warning('metadata title conflict for ${row.id}', e);
      await _recordingRepo.markMetadataSyncTerminal(
        row.id,
        status: MetadataSyncStatus.failedConflict,
      );
    } on UnauthorizedException catch (e) {
      // The session, not the edit. The token can still refresh, and every other
      // row in this queue would hit the same wall — so give up on the metadata
      // queue for this pass and charge the edit nothing. Spending a retry here
      // would burn the budget of an edit that was never refused.
      //
      // It ends this queue only. `processQueue` carries on to the Wi-Fi gate,
      // the storyteller drain and the uploads, which meet the same 401 and do
      // spend their own retries — that is their existing policy, untouched.
      _log.info('metadata queue paused, session not accepted', e);
      return true;
    } on AppException catch (e, st) {
      if (e.retryable) {
        _log.warning('retryable metadata failure for ${row.id}', e);
        await _recordingRepo.markMetadataSyncFailed(row.id);
      } else {
        _log.warning('permanent metadata failure for ${row.id}', e, st);
        await _recordingRepo.markMetadataSyncTerminal(
          row.id,
          status: MetadataSyncStatus.failedExhausted,
        );
      }
    } on Exception catch (e, st) {
      // Transport faults and other transient Exception subtypes → retry.
      // `Error` subtypes are deliberately not caught; they propagate as bugs.
      _log.warning('unexpected error syncing metadata for ${row.id}', e, st);
      await _recordingRepo.markMetadataSyncFailed(row.id);
    }
    return false;
  }

  Future<String?> _resolveStorytellerServerId(String referencedId) async {
    final row = await _storytellerRepo.getRowById(referencedId);
    if (row == null) {
      return referencedId;
    }
    if (row.serverId != null && row.serverId!.isNotEmpty) {
      return row.serverId;
    }
    if (row.syncStatus == 'synced') {
      return row.id;
    }
    return null;
  }

  /// Adds the create-call fields the API treats as optional. Absent and empty
  /// are both omitted, so an empty local string never becomes a foreign key.
  void _addOptionalCreateFields(
    Map<String, dynamic> body,
    LocalRecording recording,
  ) {
    void put(String key, String? value) {
      if (value != null && value.isNotEmpty) body[key] = value;
    }

    put('register_id', recording.registerId);
    put('secondary_genre_id', recording.secondaryGenreId);
    put('secondary_subcategory_id', recording.secondarySubcategoryId);
    put('secondary_register_id', recording.secondaryRegisterId);
  }

  /// Writes a status the drain will never pick up again, with the retry budget
  /// spent to match. Every such status is its own — the generic `failed` is
  /// reserved for a row that still has attempts left — so the detail screen can
  /// name what happened and offer the way out. The budget path does not come
  /// through here: [LocalRecordingRepository.markAsFailed] owns it, because it
  /// is the one that reads the count.
  Future<void> _markPermanentlyFailed(
    String id, {
    String status = 'failed_exhausted',
  }) async {
    await _recordingRepo.updateRecording(
      id,
      LocalRecordingsCompanion(
        uploadStatus: Value(status),
        retryCount: const Value(kMaxUploadRetries),
        lastRetryAt: Value(DateTime.now()),
      ),
    );
  }
}
