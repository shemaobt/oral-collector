import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/platform/file_ops.dart' as file_ops;

const String prefsKeyBgToken = 'bg_sync_access_token';
const String prefsKeyBgBaseUrl = 'bg_sync_base_url';

const int _smallFileThreshold = 5 * 1024 * 1024;

Future<void> storeBackgroundSyncCredentials({
  required String accessToken,
  required String baseUrl,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(prefsKeyBgToken, accessToken);
  await prefs.setString(prefsKeyBgBaseUrl, baseUrl);
}

Future<void> clearBackgroundSyncCredentials() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(prefsKeyBgToken);
  await prefs.remove(prefsKeyBgBaseUrl);
}

Future<bool> runBackgroundUpload() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(prefsKeyBgToken);
  final baseUrl = prefs.getString(prefsKeyBgBaseUrl);

  if (token == null || token.isEmpty || baseUrl == null || baseUrl.isEmpty) {
    return true;
  }

  final db = AppDatabase();
  final client = http.Client();

  try {
    return await runBackgroundUploadWith(db, client, token, baseUrl);
  } finally {
    client.close();
    await db.close();
  }
}

Future<bool> runBackgroundUploadWith(
  AppDatabase db,
  http.Client client,
  String token,
  String baseUrl,
) async {
  final pendingRows =
      await (db.select(db.localRecordings)
            ..where(
              (t) =>
                  t.uploadStatus.equals('local') |
                  t.uploadStatus.equals('failed'),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.recordedAt)])
            ..limit(5))
          .get();

  if (pendingRows.isEmpty) return true;

  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  for (final recording in pendingRows) {
    if (recording.retryCount >= 5) continue;
    if (recording.fileSizeBytes >= _smallFileThreshold) continue;

    try {
      await _uploadSingleRecording(db, client, headers, baseUrl, recording);
    } on Exception {
      await (db.update(
        db.localRecordings,
      )..where((t) => t.id.equals(recording.id))).write(
        LocalRecordingsCompanion(
          uploadStatus: const Value('failed'),
          retryCount: Value(recording.retryCount + 1),
          lastRetryAt: Value(DateTime.now()),
        ),
      );
    }
  }

  return true;
}

Future<void> _uploadSingleRecording(
  AppDatabase db,
  http.Client client,
  Map<String, String> headers,
  String baseUrl,
  LocalRecording recording,
) async {
  await (db.update(db.localRecordings)..where((t) => t.id.equals(recording.id)))
      .write(const LocalRecordingsCompanion(uploadStatus: Value('uploading')));

  String serverId;
  if (recording.serverId != null && recording.serverId!.isNotEmpty) {
    serverId = recording.serverId!;
  } else {
    final createBody = jsonEncode({
      'project_id': recording.projectId,
      'genre_id': recording.genreId,
      'subcategory_id': recording.subcategoryId,
      'title': recording.title,
      'duration_seconds': recording.durationSeconds,
      'file_size_bytes': recording.fileSizeBytes,
      'format': recording.format,
      'recorded_at': recording.recordedAt.toUtc().toIso8601String(),
      if (recording.registerId != null && recording.registerId!.isNotEmpty)
        'register_id': recording.registerId,
    });

    final createResp = await client
        .post(
          Uri.parse('$baseUrl/api/oc/recordings'),
          headers: headers,
          body: createBody,
        )
        .timeout(const Duration(seconds: 30));

    if (createResp.statusCode != 201) return;

    final createData = jsonDecode(createResp.body) as Map<String, dynamic>;
    serverId = createData['id'] as String;

    await (db.update(db.localRecordings)
          ..where((t) => t.id.equals(recording.id)))
        .write(LocalRecordingsCompanion(serverId: Value(serverId)));
  }

  final urlResp = await client
      .post(
        Uri.parse('$baseUrl/api/oc/recordings/upload-url'),
        headers: headers,
        body: jsonEncode({
          'recording_id': serverId,
          'format': recording.format,
        }),
      )
      .timeout(const Duration(seconds: 30));

  if (urlResp.statusCode != 200) return;

  final urlData = jsonDecode(urlResp.body) as Map<String, dynamic>;
  final uploadUrl = urlData['upload_url'] as String;
  final contentType =
      urlData['content_type'] as String? ?? 'application/octet-stream';

  if (!await file_ops.fileExists(recording.localFilePath)) return;
  final fileBytes = await file_ops.readFileBytes(recording.localFilePath);

  final md5Hash = crypto.md5.convert(fileBytes).toString();

  final putResp = await client
      .put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': contentType},
        body: fileBytes,
      )
      .timeout(
        Duration(seconds: 120 + (fileBytes.length ~/ (10 * 1024 * 1024)) * 60),
      );

  if (putResp.statusCode != 200) return;

  final confirmResp = await client
      .post(
        Uri.parse('$baseUrl/api/oc/recordings/$serverId/confirm-upload'),
        headers: headers,
        body: jsonEncode({'md5_hash': md5Hash}),
      )
      .timeout(const Duration(seconds: 30));

  if (confirmResp.statusCode != 200) return;

  String? gcsUrl;
  String verifiedStatus = 'uploaded';

  for (var i = 0; i < 15; i++) {
    await Future<void>.delayed(const Duration(seconds: 2));
    try {
      final pollResp = await client
          .get(
            Uri.parse('$baseUrl/api/oc/recordings/$serverId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (pollResp.statusCode != 200) continue;

      final pollData = jsonDecode(pollResp.body) as Map<String, dynamic>;
      final status = pollData['upload_status'] as String?;

      if (status == 'verified') {
        gcsUrl = pollData['gcs_url'] as String?;
        verifiedStatus = 'uploaded';
        break;
      }
      if (status == 'upload_failed') return;
    } on Exception {
      continue;
    }
  }

  await (db.update(
    db.localRecordings,
  )..where((t) => t.id.equals(recording.id))).write(
    LocalRecordingsCompanion(
      uploadStatus: Value(verifiedStatus),
      serverId: Value(serverId),
      gcsUrl: Value(gcsUrl),
    ),
  );
}
