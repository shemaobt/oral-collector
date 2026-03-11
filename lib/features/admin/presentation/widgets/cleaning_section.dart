import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/format.dart';
import '../../../recording/domain/entities/recording.dart';
import '../notifiers/admin_notifier.dart';
import 'admin_mini_stat.dart';

class CleaningSection extends ConsumerStatefulWidget {
  const CleaningSection({super.key, required this.recordings});

  final List<Recording> recordings;

  @override
  ConsumerState<CleaningSection> createState() => _CleaningSectionState();
}

class _CleaningSectionState extends ConsumerState<CleaningSection> {
  final Set<String> _selectedIds = {};
  bool _isCleaning = false;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == widget.recordings.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(widget.recordings.map((r) => r.id));
      }
    });
  }

  Future<void> _cleanSingle(String recordingId) async {
    final success = await ref
        .read(adminNotifierProvider.notifier)
        .triggerClean(recordingId);
    if (mounted) {
      final colors = AppColors.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Cleaning triggered' : 'Failed to trigger cleaning',
          ),
          backgroundColor: success ? colors.success : colors.error,
        ),
      );
    }
    _selectedIds.remove(recordingId);
  }

  Future<void> _cleanSelected() async {
    if (_selectedIds.isEmpty) return;

    setState(() => _isCleaning = true);
    final ids = _selectedIds.toList();
    final count = await ref
        .read(adminNotifierProvider.notifier)
        .triggerBatchClean(ids);

    if (mounted) {
      final colors = AppColors.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cleaning triggered for $count of ${ids.length} recordings',
          ),
          backgroundColor: count > 0 ? colors.success : colors.error,
        ),
      );
      setState(() {
        _isCleaning = false;
        _selectedIds.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Audio Cleaning Queue',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (_selectedIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton.icon(
                  onPressed: _isCleaning ? null : _cleanSelected,
                  icon: _isCleaning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.sparkles, size: 18),
                  label: Text('Clean Selected (${_selectedIds.length})'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(LucideIcons.refreshCw, size: 20),
              onPressed: () => ref
                  .read(adminNotifierProvider.notifier)
                  .refreshCleaningQueue(),
              tooltip: 'Refresh cleaning queue',
            ),
          ],
        ),
        const SizedBox(height: 8),

        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: colors.info.withValues(alpha: 0.1),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(LucideIcons.monitor, size: 16, color: colors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Audio cleaning is a web-only feature. Cleaning processes run on the server.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.info),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (widget.recordings.isEmpty)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No recordings flagged for cleaning')),
            ),
          )
        else if (isWide)
          _buildDesktopTable()
        else
          _buildMobileList(),
      ],
    );
  }

  Widget _buildDesktopTable() {
    final colors = AppColors.of(context);
    final allSelected =
        _selectedIds.length == widget.recordings.length &&
        widget.recordings.isNotEmpty;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(
              label: Checkbox(
                value: allSelected,
                onChanged: (_) => _toggleSelectAll(),
                activeColor: colors.primary,
              ),
            ),
            const DataColumn(label: Text('Title')),
            const DataColumn(label: Text('Duration')),
            const DataColumn(label: Text('Size')),
            const DataColumn(label: Text('Format')),
            const DataColumn(label: Text('Recorded')),
            const DataColumn(label: Text('Actions')),
          ],
          rows: widget.recordings.map((recording) {
            final isSelected = _selectedIds.contains(recording.id);
            return DataRow(
              selected: isSelected,
              cells: [
                DataCell(
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(recording.id),
                    activeColor: colors.primary,
                  ),
                ),
                DataCell(
                  Text(
                    recording.title ?? 'Untitled',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                DataCell(
                  Text(formatDurationCompact(recording.durationSeconds)),
                ),
                DataCell(Text(formatFileSize(recording.fileSizeBytes))),
                DataCell(Text(recording.format.toUpperCase())),
                DataCell(Text(formatDateISO(recording.createdAt))),
                DataCell(
                  FilledButton.tonal(
                    onPressed: () => _cleanSingle(recording.id),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Clean'),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    final colors = AppColors.of(context);
    final allSelected =
        _selectedIds.length == widget.recordings.length &&
        widget.recordings.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Checkbox(
                value: allSelected,
                onChanged: (_) => _toggleSelectAll(),
                activeColor: colors.primary,
              ),
              Text(
                allSelected ? 'Deselect All' : 'Select All',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        ...widget.recordings.map((recording) {
          final isSelected = _selectedIds.contains(recording.id);
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(recording.id),
                    activeColor: colors.primary,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recording.title ?? 'Untitled',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            AdminMiniStat(
                              icon: LucideIcons.clock,
                              value: formatDurationCompact(
                                recording.durationSeconds,
                              ),
                            ),
                            const SizedBox(width: 12),
                            AdminMiniStat(
                              icon: LucideIcons.hardDrive,
                              value: formatFileSize(recording.fileSizeBytes),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => _cleanSingle(recording.id),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Clean'),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
