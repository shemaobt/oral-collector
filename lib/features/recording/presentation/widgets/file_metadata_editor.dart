import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/format.dart';
import '../../../genre/domain/entities/genre.dart';
import '../../../storyteller/domain/entities/storyteller.dart';
import '../file_import_entry.dart';
import 'bulk_metadata_bar.dart';
import 'classification_field.dart';
import 'file_metadata_card.dart';
import 'supported_formats_banner.dart';

class FileMetadataEditor extends StatelessWidget {
  const FileMetadataEditor({
    super.key,
    required this.entries,
    required this.projectId,
    required this.genres,
    required this.genresLoading,
    required this.errorEntryIds,
    required this.errorKeys,
    required this.bulkGenreId,
    required this.bulkSubcategoryId,
    required this.bulkRegisterId,
    required this.bulkStoryteller,
    required this.onBulkGenreChanged,
    required this.onBulkSubcategoryChanged,
    required this.onBulkRegisterChanged,
    required this.onBulkStorytellerChanged,
    required this.onApplyBulk,
    required this.onEntryGenreChanged,
    required this.onEntrySubcategoryChanged,
    required this.onEntryRegisterChanged,
    required this.onEntryStorytellerChanged,
    required this.onRemoveEntry,
    required this.isSaving,
    required this.saveProgress,
    required this.hasWavFiles,
    required this.compressWav,
    required this.onCompressWavChanged,
    required this.onCancel,
    required this.onSave,
    required this.showFormatsBanner,
    required this.onDismissFormatsBanner,
  });

  final List<FileImportEntry> entries;
  final String projectId;
  final List<Genre> genres;
  final bool genresLoading;
  final Set<String> errorEntryIds;
  final Map<String, GlobalKey> errorKeys;

  final String? bulkGenreId;
  final String? bulkSubcategoryId;
  final String? bulkRegisterId;
  final Storyteller? bulkStoryteller;
  final ValueChanged<String?> onBulkGenreChanged;
  final ValueChanged<String?> onBulkSubcategoryChanged;
  final ValueChanged<String?> onBulkRegisterChanged;
  final ValueChanged<Storyteller?> onBulkStorytellerChanged;
  final VoidCallback onApplyBulk;

  final void Function(String entryId, String? value) onEntryGenreChanged;
  final void Function(String entryId, String? value) onEntrySubcategoryChanged;
  final void Function(String entryId, String? value) onEntryRegisterChanged;
  final void Function(String entryId, Storyteller? value)
  onEntryStorytellerChanged;
  final void Function(String entryId) onRemoveEntry;

  final bool isSaving;
  final int saveProgress;
  final bool hasWavFiles;
  final bool compressWav;
  final ValueChanged<bool> onCompressWavChanged;

  final VoidCallback onCancel;
  final VoidCallback onSave;

  final bool showFormatsBanner;
  final VoidCallback onDismissFormatsBanner;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  isWide ? 24 : 16,
                  16,
                  isWide ? 24 : 16,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showFormatsBanner)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SupportedFormatsBanner(
                          dense: true,
                          onDismiss: onDismissFormatsBanner,
                        ),
                      ),
                    if (entries.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BulkMetadataBar(
                          projectId: projectId,
                          genres: genres,
                          bulkGenreId: bulkGenreId,
                          bulkSubcategoryId: bulkSubcategoryId,
                          bulkRegisterId: bulkRegisterId,
                          bulkStoryteller: bulkStoryteller,
                          onGenreChanged: onBulkGenreChanged,
                          onSubcategoryChanged: onBulkSubcategoryChanged,
                          onRegisterChanged: onBulkRegisterChanged,
                          onStorytellerChanged: onBulkStorytellerChanged,
                          onApply: onApplyBulk,
                          isNarrow: !isWide,
                        ),
                      ),
                    if (genresLoading && genres.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (isWide)
                      _buildTable(context)
                    else
                      _buildCardList(context),
                  ],
                ),
              ),
            ),
            _buildFooter(context),
          ],
        );
      },
    );
  }

  Widget _buildCardList(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < entries.length; i++) ...[
          KeyedSubtree(
            key: errorKeys[entries[i].id],
            child: FileMetadataCard(
              entry: entries[i],
              projectId: projectId,
              genres: genres,
              hasError: errorEntryIds.contains(entries[i].id),
              onGenreChanged: (v) => onEntryGenreChanged(entries[i].id, v),
              onSubcategoryChanged: (v) =>
                  onEntrySubcategoryChanged(entries[i].id, v),
              onRegisterChanged: (v) =>
                  onEntryRegisterChanged(entries[i].id, v),
              onStorytellerChanged: (v) =>
                  onEntryStorytellerChanged(entries[i].id, v),
              onRemove: () => onRemoveEntry(entries[i].id),
            ),
          ),
          if (i < entries.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildTable(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    final anyGenreHasSubcategories = genres.any(
      (g) => g.subcategories.isNotEmpty,
    );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 88,
            ),
            child: DataTable(
              headingRowHeight: 44,
              dataRowMinHeight: 72,
              dataRowMaxHeight: 80,
              horizontalMargin: 8,
              columnSpacing: 16,
              dividerThickness: 0.6,
              headingTextStyle: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(
                    color: colors.foreground.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                  ),
              columns: [
                DataColumn(label: Text(l10n.recording_titleHint)),
                DataColumn(label: Text(l10n.detail_duration)),
                DataColumn(label: Text(l10n.moveCategory_genre)),
                if (anyGenreHasSubcategories)
                  DataColumn(label: Text(l10n.moveCategory_subcategory)),
                DataColumn(label: Text(l10n.classify_register)),
                DataColumn(label: Text(l10n.detail_storyteller)),
                const DataColumn(label: Text('')),
              ],
              rows: entries
                  .map(
                    (e) => _rowFor(
                      context,
                      e,
                      showSubcategoryCol: anyGenreHasSubcategories,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _rowFor(
    BuildContext context,
    FileImportEntry entry, {
    required bool showSubcategoryCol,
  }) {
    final colors = AppColors.of(context);
    final hasError = errorEntryIds.contains(entry.id);
    final rowKey = errorKeys[entry.id];
    final theme = Theme.of(context);

    return DataRow(
      color: hasError
          ? WidgetStateProperty.all(colors.error.withValues(alpha: 0.06))
          : null,
      cells: [
        DataCell(
          SizedBox(
            width: 220,
            child: KeyedSubtree(
              key: rowKey,
              child: TextField(
                controller: entry.titleController,
                decoration: InputDecoration(
                  hintText: entry.fileName,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colors.border.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
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
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        DataCell(
          SizedBox(
            width: 180,
            child: ClassificationField.genre(
              value: entry.genreId,
              onChanged: (v) => onEntryGenreChanged(entry.id, v),
              genres: genres,
              hasError: hasError && entry.genreId == null,
            ),
          ),
        ),
        if (showSubcategoryCol)
          DataCell(
            SizedBox(
              width: 180,
              child: ClassificationField.subcategory(
                value: entry.subcategoryId,
                onChanged: (v) => onEntrySubcategoryChanged(entry.id, v),
                genres: genres,
                genreId: entry.genreId,
                hasError:
                    hasError &&
                    _subcategoryRequired(entry) &&
                    entry.subcategoryId == null,
              ),
            ),
          ),
        DataCell(
          SizedBox(
            width: 180,
            child: ClassificationField.register(
              value: entry.registerId,
              onChanged: (v) => onEntryRegisterChanged(entry.id, v),
              hasError: hasError && entry.registerId == null,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 200,
            child: StorytellerFieldCell(
              projectId: projectId,
              selected: entry.storyteller,
              onChanged: (v) => onEntryStorytellerChanged(entry.id, v),
              compact: true,
            ),
          ),
        ),
        DataCell(
          IconButton(
            onPressed: () => onRemoveEntry(entry.id),
            icon: Icon(
              LucideIcons.x,
              size: 16,
              color: colors.foreground.withValues(alpha: 0.55),
            ),
            tooltip: AppLocalizations.of(context).import_remove,
          ),
        ),
      ],
    );
  }

  bool _subcategoryRequired(FileImportEntry entry) {
    final g = genres.where((g) => g.id == entry.genreId).firstOrNull;
    return g != null && g.subcategories.isNotEmpty;
  }

  Widget _buildFooter(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final showProgress = isSaving && entries.length > 1;
    final showCompressToggle = hasWavFiles && !kIsWeb;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: 0.4)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showCompressToggle)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: SwitchListTile.adaptive(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.import_compressWav,
                      style: theme.textTheme.bodyMedium,
                    ),
                    subtitle: Text(
                      l10n.import_compressWavHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.foreground.withValues(alpha: 0.5),
                      ),
                    ),
                    value: compressWav,
                    onChanged: isSaving ? null : onCompressWavChanged,
                  ),
                ),
              if (showProgress) ...[
                LinearProgressIndicator(
                  value: entries.isEmpty ? 0 : saveProgress / entries.length,
                  backgroundColor: colors.border.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(colors.success),
                ),
                const SizedBox(height: 6),
                Text(
                  '$saveProgress / ${entries.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.foreground.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSaving ? null : onCancel,
                      child: Text(l10n.common_cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: isSaving ? null : onSave,
                      icon: isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(LucideIcons.download, size: 16),
                      label: Text(l10n.import_importNFiles(entries.length)),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
