import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/format.dart';
import '../../../genre/domain/entities/genre.dart';
import '../../../storyteller/domain/entities/storyteller.dart';
import '../file_import_entry.dart';
import 'classification_field.dart';

class FileMetadataCard extends StatelessWidget {
  const FileMetadataCard({
    super.key,
    required this.entry,
    required this.projectId,
    required this.genres,
    required this.hasError,
    required this.onGenreChanged,
    required this.onSubcategoryChanged,
    required this.onRegisterChanged,
    required this.onStorytellerChanged,
    required this.onRemove,
  });

  final FileImportEntry entry;
  final String projectId;
  final List<Genre> genres;
  final bool hasError;
  final ValueChanged<String?> onGenreChanged;
  final ValueChanged<String?> onSubcategoryChanged;
  final ValueChanged<String?> onRegisterChanged;
  final ValueChanged<Storyteller?> onStorytellerChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    final genre = genres.where((g) => g.id == entry.genreId).firstOrNull;
    final showSubcategory = genre?.subcategories.isNotEmpty ?? false;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError
              ? colors.error.withValues(alpha: 0.5)
              : colors.border.withValues(alpha: 0.4),
          width: hasError ? 1.3 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasError)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.alertCircle, size: 14, color: colors.error),
                  const SizedBox(width: 6),
                  Text(
                    l10n.import_fieldRequired,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.fileAudio,
                      size: 16,
                      color: colors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.fileName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onRemove,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          LucideIcons.x,
                          size: 16,
                          color: colors.foreground.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 12,
                      color: colors.foreground.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatDurationHMS(entry.durationSeconds),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.foreground.withValues(alpha: 0.55),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${entry.format.toUpperCase()} · ${formatFileSize(entry.sizeBytes)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.foreground.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: entry.descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.recording_descriptionHint,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: colors.border.withValues(alpha: 0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: colors.border.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ClassificationField.genre(
                  value: entry.genreId,
                  onChanged: onGenreChanged,
                  genres: genres,
                  hasError: hasError && entry.genreId == null,
                ),
                if (showSubcategory) ...[
                  const SizedBox(height: 10),
                  ClassificationField.subcategory(
                    value: entry.subcategoryId,
                    onChanged: onSubcategoryChanged,
                    genres: genres,
                    genreId: entry.genreId,
                    hasError: hasError && entry.subcategoryId == null,
                  ),
                ],
                const SizedBox(height: 10),
                ClassificationField.register(
                  value: entry.registerId,
                  onChanged: onRegisterChanged,
                  hasError: hasError && entry.registerId == null,
                ),
                const SizedBox(height: 10),
                StorytellerFieldCell(
                  projectId: projectId,
                  selected: entry.storyteller,
                  onChanged: onStorytellerChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
