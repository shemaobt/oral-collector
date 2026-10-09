import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/platform/file_source.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_snack_bar.dart';
import '../../data/local_recording_to_entity.dart';
import '../../data/providers.dart';
import '../../domain/entities/local_recording_entity.dart';
import '../notifiers/recording_session_notifier.dart';
import '../notifiers/recordings_list_notifier.dart';
import 'pending_web_upload_card.dart';

class PendingWebUploadsBanner extends ConsumerStatefulWidget {
  const PendingWebUploadsBanner({super.key});

  @override
  ConsumerState<PendingWebUploadsBanner> createState() =>
      _PendingWebUploadsBannerState();
}

class _PendingWebUploadsBannerState
    extends ConsumerState<PendingWebUploadsBanner> {
  List<LocalRecordingEntity> _pending = const [];

  /// Ids whose audio is still in browser storage. Kept as an answer taken at
  /// load time rather than as a property of the row: the row only carries an
  /// address, and an address is not a promise that the bytes are there.
  Set<String> _withStoredAudio = const {};
  final Set<String> _resuming = {};

  @override
  void initState() {
    super.initState();
    if (ref.read(isWebPlatformProvider)) {
      Future.microtask(_load);
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    final repo = ref.read(localRecordingRepositoryProvider);
    final pending = await repo.getPendingWebUploads();
    if (!mounted) return;
    final rows = pending.map(localRecordingToEntity).toList();
    final stored = <String>{};
    for (final row in rows) {
      if (await _hasStoredAudio(row)) stored.add(row.id);
    }
    if (!mounted) return;
    setState(() {
      _pending = rows;
      _withStoredAudio = stored;
    });
  }

  Future<bool> _hasStoredAudio(LocalRecordingEntity row) async {
    final key = row.localFilePath;
    if (key.isEmpty) return false;
    return ref.read(fileExistsProvider)(key);
  }

  /// The audio this row points at, or null when there is none to point at.
  ///
  /// Null is the ordinary answer, not a failure: rows written before the
  /// address was recorded carry an invented name that addresses nothing, a web
  /// import never had bytes in storage to begin with, and a recording older
  /// than a day may have been collected by the startup sweep. All of them mean
  /// the same thing here — ask the person for the file.
  Future<FileSource?> _storedAudio(LocalRecordingEntity row) async {
    if (!await _hasStoredAudio(row)) return null;
    final key = row.localFilePath;
    final bytes = await ref.read(readFileBytesProvider)(key);
    if (bytes.isEmpty) return null;
    return FileSource.fromBytes(
      bytes,
      name: key,
      mimeType: 'audio/${row.format}',
      // Carried through so an upload that is cut short again writes a row that
      // still leads back to these bytes (ENG-427).
      storageKey: key,
    );
  }

  Future<void> _resume(LocalRecordingEntity row) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _resuming.add(row.id);
    });
    try {
      final ext = row.format;
      var source = await _storedAudio(row);
      if (source == null) {
        source = await ref.read(audioFilePickerProvider)(
          allowedExtensions: [ext],
        );
        if (source == null) {
          return;
        }
        // Only the picker can hand over the wrong audio; stored bytes are the
        // original ones and there is nothing to check them against.
        if (source.length != row.fileSizeBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.recording_resumeSizeMismatch)),
            );
          }
          source.dispose();
          return;
        }
      }

      final serverId = row.serverId;
      if (serverId == null) {
        // Shadow row with no serverId — nothing we can resume; clean it up.
        await ref
            .read(localRecordingRepositoryProvider)
            .deleteRecording(row.id);
        await _load();
        source.dispose();
        return;
      }

      final service = ref.read(resumableUploadServiceProvider);
      final result = await service.uploadFromSource(
        recordingId: row.id,
        serverId: serverId,
        source: source,
        format: ext,
      );

      if (!result.success) {
        if (mounted) {
          showErrorSnackBar(
            context,
            result.error ?? 'unknown',
            template: l10n.recording_uploadFailed,
          );
        }
        return;
      }

      final storageKey = source.storageKey;
      if (storageKey != null) {
        // The upload is through, so nothing needs these bytes any more. Left
        // behind they would wait on the 24-hour sweep (ENG-426) — new litter
        // from the very change that closes the subject.
        await ref.read(deleteFileProvider)(storageKey);
      }
      await ref.read(localRecordingRepositoryProvider).deleteRecording(row.id);
      await _load();
      unawaited(
        ref.read(recordingsListNotifierProvider.notifier).fetchRecordings(),
      );
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _resuming.remove(row.id);
        });
      }
    }
  }

  Future<void> _discard(LocalRecordingEntity row) async {
    final repo = ref.read(localRecordingRepositoryProvider);
    await repo.deleteRecording(row.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(isWebPlatformProvider) || _pending.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final rec in _pending)
          PendingWebUploadCard(
            recording: rec,
            hasStoredAudio: _withStoredAudio.contains(rec.id),
            isResuming: _resuming.contains(rec.id),
            onResume: () => _resume(rec),
            onDiscard: () => _discard(rec),
          ),
      ],
    );
  }
}
