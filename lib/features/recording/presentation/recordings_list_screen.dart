import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/l10n/content_l10n.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../features/auth/data/providers/role_provider.dart';
import '../../../shared/preview_helpers.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/status_banner.dart';
import '../../../shared/widgets/sync_status_indicator.dart';
import '../../genre/presentation/notifiers/genre_notifier.dart';
import '../../project/presentation/notifiers/project_notifier.dart';
import '../../sync/presentation/notifiers/sync_notifier.dart';
import '../domain/entities/local_recording_entity.dart';
import '../domain/entities/register.dart';
import 'notifiers/recordings_list_notifier.dart';
import 'notifiers/recordings_list_state.dart';
import 'widgets/active_filter_chips.dart';
import 'widgets/filters_icon_button.dart';
import 'widgets/import_drop_zone.dart';
import 'widgets/pending_web_uploads_banner.dart';
import 'widgets/recording_card.dart';
import 'widgets/recordings_filter_sheet.dart';

@Preview(name: 'Recordings List', wrapper: previewWrapper)
Widget recordingsListPreview() => const RecordingsListScreen();

// TEMP seam (ENG-197): the list now holds LocalRecordingEntity, but RecordingCard
// still takes the Drift LocalRecording row. F2 migrates the card to the entity
// and deletes this. lastRetryAt/md5Hash are dropped fields the card never reads.
LocalRecording _entityToCardRow(LocalRecordingEntity e) => LocalRecording(
  id: e.id,
  projectId: e.projectId,
  genreId: e.genreId,
  subcategoryId: e.subcategoryId,
  title: e.title,
  description: e.description,
  durationSeconds: e.durationSeconds,
  fileSizeBytes: e.fileSizeBytes,
  format: e.format,
  localFilePath: e.localFilePath,
  uploadStatus: e.uploadStatus,
  serverId: e.serverId,
  gcsUrl: e.gcsUrl,
  registerId: e.registerId,
  secondaryGenreId: e.secondaryGenreId,
  secondarySubcategoryId: e.secondarySubcategoryId,
  secondaryRegisterId: e.secondaryRegisterId,
  storytellerId: e.storytellerId,
  userId: e.userId,
  cleaningStatus: e.cleaningStatus,
  recordedAt: e.recordedAt,
  createdAt: e.createdAt,
  retryCount: e.retryCount,
  resumableSessionUri: e.resumableSessionUri,
  uploadedBytes: e.uploadedBytes,
  splitFromId: e.splitFromId,
  splitIndex: e.splitIndex,
  splitSegmentCount: e.splitSegmentCount,
);

class RecordingsListScreen extends ConsumerStatefulWidget {
  const RecordingsListScreen({
    super.key,
    this.initialGenreId,
    this.initialSubcategoryId,
  });

  final String? initialGenreId;
  final String? initialSubcategoryId;

  @override
  ConsumerState<RecordingsListScreen> createState() =>
      _RecordingsListScreenState();
}

class _RecordingsListScreenState extends ConsumerState<RecordingsListScreen>
    with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    final gid = widget.initialGenreId;
    final sid = widget.initialSubcategoryId;
    Future.microtask(() {
      if (!mounted) return;
      final notifier = ref.read(recordingsListNotifierProvider.notifier);
      if (gid != null && gid.isNotEmpty) notifier.setGenreFilter(gid);
      if (sid != null && sid.isNotEmpty) notifier.setSubcategoryFilter(sid);
      _refreshAll();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (currentScroll >= maxScroll - 300) {
      ref.read(recordingsListNotifierProvider.notifier).loadMore();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAll();
    }
  }

  Future<void> _deleteRecording(LocalRecordingEntity recording) async {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.recording_deleteTitle),
        content: Text(l10n.recording_deleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: colors.error),
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await ref
        .read(recordingsListNotifierProvider.notifier)
        .deleteRecording(recording);
    if (!mounted) return;
    switch (result) {
      case DeleteRecordingResult.ok:
        break;
      case DeleteRecordingResult.forbidden:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.recording_deleteNoPermission),
            backgroundColor: AppColors.of(context).warning,
          ),
        );
      case DeleteRecordingResult.failed:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.recording_deleteFailed)));
    }
  }

  void _refreshAll() {
    final isOnline = ref.read(syncNotifierProvider).isOnline;
    ref.read(recordingsListNotifierProvider.notifier).fetchRecordings();
    if (!isOnline) return;
    ref.read(genreNotifierProvider.notifier).fetchGenres();
    ref.read(syncNotifierProvider.notifier).processQueue();
  }

  Future<void> _clearStaleRecordings() async {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    if (!ref.read(syncNotifierProvider).isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.error_network),
          backgroundColor: colors.error,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.recordings_clearStale),
        content: Text(l10n.recordings_clearStaleMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: colors.error),
            child: Text(l10n.recordings_clearStale),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final deleted = await ref
          .read(recordingsListNotifierProvider.notifier)
          .clearStaleRecordings();
      if (!mounted) return;
      if (deleted == null) {
        // Connectivity dropped between the dialog confirm and the API call.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.error_network),
            backgroundColor: colors.error,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.recordings_clearedCount(deleted))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.recordings_clearFailed),
            backgroundColor: colors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-fetch when connectivity is restored
    ref.listen(syncNotifierProvider.select((s) => s.isOnline), (prev, next) {
      if (next && prev == false) {
        _refreshAll();
      }
    });

    // Refresh list when sync completes (lastSyncAt changes)
    ref.listen(syncNotifierProvider.select((s) => s.lastSyncAt), (_, _) {
      ref.read(recordingsListNotifierProvider.notifier).fetchRecordings();
    });

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final listState = ref.watch(recordingsListNotifierProvider);
    final filtered = listState.filteredRecordings;
    final syncState = ref.watch(syncNotifierProvider);
    final isOffline = !syncState.isOnline;
    final activeProject = ref.watch(
      projectNotifierProvider.select((s) => s.activeProject),
    );

    final fabOffset = AppShell.fabBottomOffset(context);

    return Scaffold(
      floatingActionButton: activeProject != null
          ? Padding(
              padding: EdgeInsets.only(bottom: fabOffset - 70),
              child: Semantics(
                label: l10n.recordings_importAudio,
                button: true,
                child: Material(
                  color: AppColors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () => context.push('/import-file'),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.accent,
                            colors.accent.withValues(alpha: 0.85),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.accent.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: colors.accent.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.filePlus,
                          size: 26,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: activeProject == null
          ? EmptyState(
              icon: LucideIcons.folderOpen,
              title: l10n.recordings_selectProject,
              description: l10n.recordings_selectProjectSubtitle,
              action: FilledButton.icon(
                onPressed: () => context.go('/projects'),
                icon: const Icon(LucideIcons.folderOpen, size: 18),
                label: Text(l10n.home_browseProjects),
              ),
            )
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                ScreenHeaderSliver(
                  title: l10n.recordings_title,
                  subtitle: l10n.recordings_subtitle,
                  icon: LucideIcons.mic,
                  actions: [
                    const SyncStatusIndicator(),
                    FiltersIconButton(
                      count: listState.activeFilterCount,
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        useRootNavigator: true,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(RadiusScale.r20),
                          ),
                        ),
                        builder: (_) =>
                            RecordingsFilterSheet(projectId: activeProject.id),
                      ),
                    ),
                  ],
                ),

                if (isOffline)
                  SliverToBoxAdapter(child: StatusBanner.offline(l10n)),

                const SliverToBoxAdapter(child: PendingWebUploadsBanner()),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      SpacingScale.s16,
                      SpacingScale.s12,
                      SpacingScale.s16,
                      SpacingScale.s4,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => ref
                          .read(recordingsListNotifierProvider.notifier)
                          .setSearchQuery(value),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: l10n.recordings_searchHint,
                        prefixIcon: const Icon(LucideIcons.search, size: 18),
                        suffixIcon: listState.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(LucideIcons.x, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(
                                        recordingsListNotifierProvider.notifier,
                                      )
                                      .setSearchQuery('');
                                },
                              )
                            : null,
                        isDense: true,
                        filled: true,
                        fillColor: colors.surfaceAlt,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: SpacingScale.s12,
                          vertical: SpacingScale.s8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(RadiusScale.r12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(RadiusScale.r12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(RadiusScale.r12),
                          borderSide: BorderSide(
                            color: colors.accent,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: ActiveFilterChips()),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      SpacingScale.s16,
                      SpacingScale.s16,
                      SpacingScale.s16,
                      SpacingScale.s8,
                    ),
                    child: Row(
                      children: [
                        Text(
                          listState.hasMore
                              ? '${filtered.length}+'
                              : l10n.recordings_count(filtered.length),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.secondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const Spacer(),
                        if ((listState.selectedFilter == StatusFilter.pending ||
                                listState.selectedFilter == StatusFilter.all) &&
                            filtered.any(
                              (r) =>
                                  r.uploadStatus == 'failed' ||
                                  r.uploadStatus == 'uploading',
                            ) &&
                            ref
                                .watch(roleNotifierProvider.notifier)
                                .canManageProject(activeProject.id))
                          TextButton.icon(
                            onPressed: _clearStaleRecordings,
                            icon: Icon(
                              LucideIcons.trash2,
                              size: 14,
                              color: colors.error,
                            ),
                            label: Text(
                              l10n.recordings_clearStale,
                              style: TextStyle(
                                color: colors.error,
                                fontSize: 12,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SpacingScale.s8,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                listState.isLoading
                    ? const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : filtered.isEmpty
                    ? SliverFillRemaining(
                        child: ImportDropZone(
                          onFilesDropped: (files) {
                            if (!mounted) return;
                            context.push<void>('/import-file', extra: files);
                          },
                          hoverLabel: l10n.import_dropHint,
                          child: EmptyState(
                            icon: LucideIcons.mic,
                            title: l10n.recordings_noRecordings,
                            description: ImportDropZone.isSupportedPlatform
                                ? '${l10n.recordings_noRecordingsSubtitle}\n\n${l10n.recordings_dropToImport}'
                                : l10n.recordings_noRecordingsSubtitle,
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          SpacingScale.s16,
                          0,
                          SpacingScale.s16,
                          AppShell.scrollPaddingFor(context),
                        ),
                        sliver: SliverList.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: SpacingScale.s8),
                          itemBuilder: (context, index) {
                            final recording = filtered[index];
                            final rawGenre = ref
                                .read(genreNotifierProvider.notifier)
                                .getGenreName(recording.genreId);
                            final rawSubcat = recording.subcategoryId != null
                                ? ref
                                      .read(genreNotifierProvider.notifier)
                                      .getSubcategoryName(
                                        recording.subcategoryId!,
                                      )
                                : null;
                            final rawReg = getRegisterName(
                              recording.registerId,
                            );
                            return Dismissible(
                              key: ValueKey(recording.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) async {
                                await _deleteRecording(recording);
                                return false;
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(
                                  right: SpacingScale.s24,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.error.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(
                                    RadiusScale.r16,
                                  ),
                                ),
                                child: Icon(
                                  LucideIcons.trash2,
                                  color: colors.error,
                                ),
                              ),
                              child: RecordingCard(
                                recording: _entityToCardRow(recording),
                                genreName: rawGenre != null
                                    ? localizedGenreName(l10n, rawGenre)
                                    : null,
                                subcategoryName: rawSubcat != null
                                    ? localizedSubcategoryName(l10n, rawSubcat)
                                    : null,
                                registerName: rawReg != null
                                    ? localizedRegisterName(l10n, rawReg)
                                    : null,
                                formattedDuration: formatDurationLong(
                                  recording.durationSeconds,
                                ),
                                onDelete: () => _deleteRecording(recording),
                                onTap: () async {
                                  await context.push(
                                    '/recording/${recording.id}',
                                  );
                                  unawaited(
                                    ref
                                        .read(
                                          recordingsListNotifierProvider
                                              .notifier,
                                        )
                                        .fetchRecordings(),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),

                if (!listState.isLoading && listState.isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: SpacingScale.s24),
                      child: Center(
                        child: SizedBox(
                          width: SpacingScale.s24,
                          height: SpacingScale.s24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
