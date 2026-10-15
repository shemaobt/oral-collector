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
    required this.hasStoredAudio,
    required this.isResuming,
    required this.onResume,
    required this.onDiscard,
  });

  final LocalRecordingEntity recording;

  /// Whether the audio is still in browser storage. The two cases are not the
  /// same thing to read: with the audio here the app only has to carry on, and
  /// without it there is nothing to continue from until the person hands the
  /// file over again (ENG-427).
  final bool hasStoredAudio;

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
                    l10n.recording_resumePromptTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingScale.s8),
            Text(
              _body(
                l10n,
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
            // The two labels do not fit side by side on a narrow phone at 2.0x
            // in most locales, so they stack instead of running off the card.
            OverflowBar(
              alignment: MainAxisAlignment.end,
              overflowAlignment: OverflowBarAlignment.end,
              spacing: SpacingScale.s8,
              children: [
                TextButton(
                  onPressed: isResuming ? null : onDiscard,
                  child: Text(l10n.common_discard),
                ),
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

  String _body(AppLocalizations l10n, String name, String size) =>
      hasStoredAudio
      ? l10n.recording_resumePromptBodyStored(name, size)
      : l10n.recording_resumePromptBodyPickFile(name, size);

  String _filenameFromPath(String path) {
    final slash = path.lastIndexOf('/');
    if (slash < 0) return path;
    return path.substring(slash + 1);
  }
}
