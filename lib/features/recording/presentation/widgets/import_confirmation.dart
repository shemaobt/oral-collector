import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/format.dart';

class ImportConfirmation extends StatelessWidget {
  const ImportConfirmation({
    super.key,
    required this.fileName,
    required this.format,
    required this.durationSeconds,
    required this.fileSizeBytes,
    this.fileCount = 1,
    this.saveProgress = 0,
    required this.genreName,
    required this.subcategoryName,
    this.registerName,
    required this.titleController,
    required this.isSaving,
    required this.onSave,
    required this.onCancel,
    this.hasWavFiles = false,
    this.compressWav = true,
    this.onCompressWavChanged,
  });

  final String? fileName;
  final String format;
  final double durationSeconds;
  final int fileSizeBytes;
  final int fileCount;
  final int saveProgress;
  final String? genreName;
  final String? subcategoryName;
  final String? registerName;
  final TextEditingController titleController;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool hasWavFiles;
  final bool compressWav;
  final ValueChanged<bool>? onCompressWavChanged;

  bool get _isBatch => fileCount > 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    final tagParts = <String>[];
    if (genreName != null) tagParts.add(genreName!);
    if (subcategoryName != null) tagParts.add(subcategoryName!);
    if (registerName != null) tagParts.add(registerName!);
    final tagLabel = tagParts.join(' / ');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.info.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(
                  _isBatch ? LucideIcons.files : LucideIcons.fileAudio,
                  size: 48,
                  color: colors.info,
                ),
                const SizedBox(height: 12),
                Text(
                  fileName ?? l10n.import_unknownFile,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _isBatch
                      ? '${formatFileSize(fileSizeBytes)} total'
                      : '${format.toUpperCase()} \u2022 ${formatDurationHMS(durationSeconds)} \u2022 ${formatFileSize(fileSizeBytes)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.foreground.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (tagLabel.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tagLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                ),
              ),
            ),

          const SizedBox(height: 24),

          if (!_isBatch)
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: l10n.recording_titleHint,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),

          if (hasWavFiles && !kIsWeb) ...[
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Compress WAV to M4A',
                style: theme.textTheme.bodyMedium,
              ),
              subtitle: Text(
                '~10x smaller, no quality loss for ML pipeline',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.foreground.withValues(alpha: 0.5),
                ),
              ),
              value: compressWav,
              onChanged: isSaving ? null : onCompressWavChanged,
            ),
          ],

          if (isSaving && _isBatch) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: fileCount > 0 ? saveProgress / fileCount : 0,
              backgroundColor: colors.border.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(colors.success),
            ),
            const SizedBox(height: 8),
            Text(
              '$saveProgress / $fileCount',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.foreground.withValues(alpha: 0.6),
              ),
            ),
          ],

          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(LucideIcons.download),
              label: Text(l10n.import_importAndSave),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.success,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: isSaving ? null : onCancel,
              child: Text(l10n.common_cancel),
            ),
          ),
        ],
      ),
    );
  }
}
