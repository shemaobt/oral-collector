import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/format.dart';
import '../../domain/entities/local_recording_entity.dart';

/// Presentational card for a single pending web upload, rendered by
/// `PendingWebUploadsBanner`. Kept stateless and platform-agnostic so it can be
/// exercised in widget tests — the banner itself is gated behind `kIsWeb`.
class PendingWebUploadCard extends StatelessWidget {
  const PendingWebUploadCard({
    super.key,
    required this.recording,
    required this.isResuming,
    required this.onResume,
    required this.onDiscard,
  });

  final LocalRecordingEntity recording;
  final bool isResuming;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(
        SpacingScale.s12,
        SpacingScale.s8,
        SpacingScale.s12,
        0,
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacingScale.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.uploadCloud, size: 18),
                const SizedBox(width: SpacingScale.s8),
                Expanded(
                  child: Text(
                    l10n.import_resumePromptTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingScale.s8),
            Text(
              l10n.import_resumePromptBody(
                recording.title ?? _filenameFromPath(recording.localFilePath),
                formatFileSize(recording.fileSizeBytes),
              ),
              style: theme.textTheme.bodySmall,
            ),
            if (recording.uploadedBytes > 0 && recording.fileSizeBytes > 0) ...[
              const SizedBox(height: SpacingScale.s8),
              LinearProgressIndicator(
                value: (recording.uploadedBytes / recording.fileSizeBytes)
                    .clamp(0.0, 1.0),
              ),
              const SizedBox(height: SpacingScale.s4),
              Text(
                '${formatFileSize(recording.uploadedBytes)} / ${formatFileSize(recording.fileSizeBytes)}',
                style: theme.textTheme.labelSmall,
              ),
            ],
            const SizedBox(height: SpacingScale.s8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: isResuming ? null : onDiscard,
                  child: Text(l10n.common_discard),
                ),
                const SizedBox(width: SpacingScale.s8),
                FilledButton(
                  onPressed: isResuming ? null : onResume,
                  child: isResuming
                      ? const SizedBox(
                          width: SpacingScale.s16,
                          height: SpacingScale.s16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.common_resume),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _filenameFromPath(String path) {
    final slash = path.lastIndexOf('/');
    if (slash < 0) return path;
    return path.substring(slash + 1);
  }
}
