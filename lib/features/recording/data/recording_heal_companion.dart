import 'package:drift/drift.dart' show Value;

import '../../../core/database/app_database.dart';
import '../domain/entities/server_recording.dart';

/// Builds a [LocalRecordingsCompanion] that heals metadata fields on a row
/// corrupted by the original ENG-64 bug (the hand-picked cache insert in the
/// detail screen omitted [description], [storytellerId], [userId], and the
/// secondary classification trio).
///
/// Strategy: the pre-fix hand-picked Companion also omitted `userId`, so a
/// local row whose [LocalRecording.userId] is `null` paired with a server row
/// that has a userId is the marker of "this row was written by the buggy
/// path". When that marker is present, every user-content field on the
/// returned companion takes the server value. When the marker is absent, no
/// user-content field is touched — so a user who intentionally cleared the
/// description (writes `''`) or removed the storyteller (writes `null`)
/// keeps that change across a server refresh.
///
/// Server-controlled upload state ([gcsUrl], [uploadStatus]) is adopted from
/// the server whenever the server reports a gcsUrl, independent of the
/// corruption marker.
LocalRecordingsCompanion buildHealMetadataCompanion({
  required LocalRecording local,
  required ServerRecording server,
}) {
  final hasServerGcs = server.gcsUrl != null && server.gcsUrl!.isNotEmpty;
  final localUserIdEmpty = local.userId == null || local.userId!.isEmpty;
  final serverHasUserId = server.userId != null && server.userId!.isNotEmpty;
  final isCorrupted = localUserIdEmpty && serverHasUserId;

  Value<String?> healIfCorrupted(String? serverValue) {
    if (!isCorrupted) return const Value.absent();
    if (serverValue == null || serverValue.isEmpty) return const Value.absent();
    return Value(serverValue);
  }

  return LocalRecordingsCompanion(
    gcsUrl: hasServerGcs ? Value(server.gcsUrl!) : const Value.absent(),
    uploadStatus: hasServerGcs
        ? Value(server.uploadStatus)
        : const Value.absent(),
    userId: healIfCorrupted(server.userId),
    description: healIfCorrupted(server.description),
    storytellerId: healIfCorrupted(server.storytellerId),
    secondaryGenreId: healIfCorrupted(server.secondaryGenreId),
    secondarySubcategoryId: healIfCorrupted(server.secondarySubcategoryId),
    secondaryRegisterId: healIfCorrupted(server.secondaryRegisterId),
  );
}
