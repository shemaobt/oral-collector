import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/platform/web_file_picker.dart' as web_picker;
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_snack_bar.dart';
import '../../data/local_recording_to_entity.dart';
import '../../data/providers.dart';
import '../../domain/entities/local_recording_entity.dart';
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
  final Set<String> _resuming = {};

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      Future.microtask(_load);
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    final repo = ref.read(localRecordingRepositoryProvider);
    final pending = await repo.getPendingWebUploads();
    if (!mounted) return;
    setState(() {
      _pending = pending.map(localRecordingToEntity).toList();
    });
  }

  Future<void> _resume(LocalRecordingEntity row) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _resuming.add(row.id);
    });
    try {
      final ext = row.format;
      final source = await web_picker.pickSingleAudioFile(
        allowedExtensions: [ext],
      );
      if (source == null) {
        return;
      }
      if (source.length != row.fileSizeBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.import_resumeSizeMismatch)),
          );
        }
        source.dispose();
        return;
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
    if (!kIsWeb || _pending.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final rec in _pending)
          PendingWebUploadCard(
            recording: rec,
            isResuming: _resuming.contains(rec.id),
            onResume: () => _resume(rec),
            onDiscard: () => _discard(rec),
          ),
      ],
    );
  }
}
