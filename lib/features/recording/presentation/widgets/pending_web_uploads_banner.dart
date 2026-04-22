import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/platform/web_file_picker.dart' as web_picker;
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/format.dart';
import '../../data/providers.dart';
import '../notifiers/recordings_list_notifier.dart';

class PendingWebUploadsBanner extends ConsumerStatefulWidget {
  const PendingWebUploadsBanner({super.key});

  @override
  ConsumerState<PendingWebUploadsBanner> createState() =>
      _PendingWebUploadsBannerState();
}

class _PendingWebUploadsBannerState
    extends ConsumerState<PendingWebUploadsBanner> {
  List<LocalRecording> _pending = const [];
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
      _pending = pending;
    });
  }

  Future<void> _resume(LocalRecording row) async {
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.import_saveError(result.error ?? 'unknown')),
            ),
          );
        }
        return;
      }

      await ref.read(localRecordingRepositoryProvider).deleteRecording(row.id);
      await _load();
      ref.read(recordingsListNotifierProvider.notifier).fetchRecordings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.import_saveError(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _resuming.remove(row.id);
        });
      }
    }
  }

  Future<void> _discard(LocalRecording row) async {
    final repo = ref.read(localRecordingRepositoryProvider);
    await repo.deleteRecording(row.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || _pending.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _pending)
          Card(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.uploadCloud, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.import_resumePromptTitle,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.import_resumePromptBody(
                      row.title ?? _filenameFromPath(row.localFilePath),
                      formatFileSize(row.fileSizeBytes),
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (row.uploadedBytes > 0 && row.fileSizeBytes > 0) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (row.uploadedBytes / row.fileSizeBytes).clamp(
                        0.0,
                        1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatFileSize(row.uploadedBytes)} / ${formatFileSize(row.fileSizeBytes)}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _resuming.contains(row.id)
                            ? null
                            : () => _discard(row),
                        child: Text(l10n.common_discard),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _resuming.contains(row.id)
                            ? null
                            : () => _resume(row),
                        child: _resuming.contains(row.id)
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.common_resume),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _filenameFromPath(String path) {
    final slash = path.lastIndexOf('/');
    if (slash < 0) return path;
    return path.substring(slash + 1);
  }
}
