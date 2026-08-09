import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/l10n/content_l10n.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/observability/error_reporter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../features/auth/data/providers/role_provider.dart';
import '../../../shared/preview_helpers.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_snack_bar.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/status_banner.dart';
import '../../../shared/widgets/sync_status_indicator.dart';
import '../../genre/presentation/notifiers/genre_notifier.dart';
import '../../project/presentation/notifiers/project_notifier.dart';
import '../../sync/presentation/notifiers/sync_notifier.dart';
import '../domain/entities/local_recording_entity.dart';
import '../domain/entities/register.dart';
import '../domain/entities/review_pendency.dart';
import '../domain/upload_status_actions.dart';
import 'notifiers/recordings_list_notifier.dart';
import 'notifiers/recordings_list_state.dart';
import 'widgets/active_filter_chips.dart';
import 'widgets/filters_icon_button.dart';
import 'widgets/import_drop_zone.dart';
import 'widgets/pendency_filter_chips.dart';
import 'widgets/pending_web_uploads_banner.dart';
import 'widgets/recording_card.dart';
import 'widgets/recordings_filter_sheet.dart';

@Preview(name: 'Recordings List', wrapper: previewWrapper)
Widget recordingsListPreview() => const RecordingsListScreen();

class RecordingsListScreen extends ConsumerStatefulWidget {
  const RecordingsListScreen({
    super.key,
    this.initialGenreId,
    this.initialSubcategoryId,
    this.initialReviewFlag,
  });

  final String? initialGenreId;
  final String? initialSubcategoryId;
  final PendencyKind? initialReviewFlag;

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
    final flag = widget.initialReviewFlag;
    Future.microtask(() {
      if (!mounted) return;
      final notifier = ref.read(recordingsListNotifierProvider.notifier);
      if (gid != null && gid.isNotEmpty) notifier.setGenreFilter(gid);
      if (sid != null && sid.isNotEmpty) notifier.setSubcategoryFilter(sid);
      // Applied only when the route names one, exactly like the two above: a
      // pendency the user picked in the sheet is not in the URL, and clearing
      // it here would make it the one filter that cannot survive leaving this
      // screen and coming back. Route changes are `didUpdateWidget`'s job,
      // including the change to null that the tab bar makes.
      //
      // refresh: false — _refreshAll fetches on the next line, and the pendency
      // filter is a server-side one, so letting it fetch too would ask twice.
      if (flag != null) {
        unawaited(notifier.setReviewFlagFilter(flag, refresh: false));
      }
      _refreshAll();
    });
  }

  @override
  void didUpdateWidget(RecordingsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The tab bar, deep links and back navigation all reach this screen through
    // the router, which rebuilds the widget with the route's parameters but
    // reuses the State, so `initState` never runs again and a pendency from an
    // earlier visit outlives the URL that named it.
    //
    // The comparison is against the old widget, never against the notifier: a
    // filter the user picked from the sheet or a chip is not in the URL, and
    // keying this on the route alone would wipe it on any rebuild.
    //
    // Only the pendency: `initialGenreId`/`initialSubcategoryId` diverge the
    // same way in principle, but no live path produces one — the only route
    // that names a genre comes from a screen this one is never rebuilt from —
    // so following them here would be untestable code for a hypothetical.
    if (widget.initialReviewFlag == oldWidget.initialReviewFlag) return;
    final flag = widget.initialReviewFlag;
    Future.microtask(() {
      if (!mounted) return;
      unawaited(
        ref
            .read(recordingsListNotifierProvider.notifier)
            .setReviewFlagFilter(flag),
      );
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

  /// No confirmation dialog and no online pre-check, both dropped with the
  /// delete this replaced (ENG-404). A confirmation buys the user a chance to
  /// back out of something irreversible; requeueing destroys nothing and is
  /// idempotent, so the prompt would only charge a second tap and keep
  /// signalling danger where there is none. The write is local, and useful
  /// offline at that — the rows drain on their own once reachability returns.
  Future<void> _retryFailedUploads() async {
    final l10n = AppLocalizations.of(context);

    try {
      final requeued = await ref
          .read(recordingsListNotifierProvider.notifier)
          .retryFailedUploads();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.recordings_retryQueuedCount(requeued))),
      );
    } on Exception catch (e, st) {
      ref.read(errorReporterProvider).reportError(e, st);
      if (!mounted) return;
      // A fixed message rather than the mapped one: what can fail here is a
      // local write, and `friendlyErrorFor` would dress it as something the
      // user could act on. The real error goes to telemetry above.
      showErrorSnackBar(
        context,
        '',
        template: (_) => l10n.recordings_retryFailed,
      );
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

    // An empty list under a pendency filter is only an answer when the server
    // gave one. Offline, or after a fetch that failed, it is the absence of an
    // answer — and "no recordings yet" would tell the user the work is done
    // seconds after the project screen said three recordings still need
    // details. Read from `recordings`, not `filtered`: a genre, status or
    // search sieve emptying the list is this device's doing, and blaming the
    // connection for it sends the user looking for a signal they do not need.
    final pendencyUnanswered =
        listState.selectedReviewFlag != null &&
        listState.recordings.isEmpty &&
        (isOffline || listState.fetchFailed);
    final activeProject = ref.watch(
      projectNotifierProvider.select((s) => s.activeProject),
    );

    final fabOffset = AppShell.fabBottomOffset(context);

    return Scaffold(
      floatingActionButton: activeProject != null
          ? Padding(
              padding: EdgeInsets.only(bottom: fabOffset - 70),
              child: const _ImportFab(),
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
                  child: _SearchField(
                    controller: _searchController,
                    hasQuery: listState.searchQuery.isNotEmpty,
                    onChanged: (value) => ref
                        .read(recordingsListNotifierProvider.notifier)
                        .setSearchQuery(value),
                    onClear: () {
                      _searchController.clear();
                      ref
                          .read(recordingsListNotifierProvider.notifier)
                          .setSearchQuery('');
                    },
                  ),
                ),

                SliverToBoxAdapter(
                  child: PendencyFilterChips(projectId: activeProject.id),
                ),

                const SliverToBoxAdapter(child: ActiveFilterChips()),

                SliverToBoxAdapter(
                  child: Padding(
                    // Tighter than it was, to the design package's 14/16/6 —
                    // snapped to the 4px scale, which is what closes the gap
                    // the chip row opened above it.
                    padding: const EdgeInsets.fromLTRB(
                      SpacingScale.s16,
                      SpacingScale.s12,
                      SpacingScale.s16,
                      SpacingScale.s4,
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
                            hasRetryableFailedUploads(filtered) &&
                            ref
                                .watch(roleNotifierProvider.notifier)
                                .canManageProject(activeProject.id))
                          TextButton.icon(
                            onPressed: _retryFailedUploads,
                            icon: Icon(
                              LucideIcons.refreshCw,
                              size: 14,
                              color: colors.primary,
                            ),
                            label: Text(
                              l10n.recordings_retryFailedUploads,
                              style: TextStyle(
                                color: colors.primary,
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
                        child: pendencyUnanswered
                            ? _PendencyFilterUnanswered(offline: isOffline)
                            : ImportDropZone(
                                onFilesDropped: (files) {
                                  if (!mounted) return;
                                  context.push<void>(
                                    '/import-file',
                                    extra: files,
                                  );
                                },
                                hoverLabel: l10n.import_dropHint,
                                child: EmptyState(
                                  icon: LucideIcons.mic,
                                  title: l10n.recordings_noRecordings,
                                  description:
                                      ImportDropZone.isSupportedPlatform
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
                                recording: recording,
                                genreName: rawGenre != null
                                    ? localizedGenreName(l10n, rawGenre)
                                    : null,
                                subcategoryName: rawSubcat != null
                                    ? localizedSubcategoryName(l10n, rawSubcat)
                                    : null,
                                registerName: rawReg != null
                                    ? localizedRegisterName(l10n, rawReg)
                                    : null,
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

class _ImportFab extends StatelessWidget {
  const _ImportFab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    return Semantics(
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
                colors: [colors.accent, colors.accent.withValues(alpha: 0.85)],
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
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hasQuery,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingScale.s16,
        SpacingScale.s12,
        SpacingScale.s16,
        SpacingScale.s4,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: l10n.recordings_searchHint,
          prefixIcon: const Icon(LucideIcons.search, size: 18),
          suffixIcon: hasQuery
              ? IconButton(
                  icon: const Icon(LucideIcons.x, size: 16),
                  onPressed: onClear,
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
            borderSide: BorderSide(color: colors.accent, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// What the list says when a pendency filter is on and nothing came back
/// because nothing could be asked (ENG-381).
///
/// Not "no recordings yet": there may well be plenty. Only the server can say
/// which of them still carry a review flag, so an empty list here is the
/// absence of an answer rather than an answer of zero.
class _PendencyFilterUnanswered extends ConsumerWidget {
  const _PendencyFilterUnanswered({required this.offline});

  /// Whether the connection is the reason. It usually is not: a 5xx, a
  /// timeout or an expired session all land here with the device online, and
  /// telling that user to reconnect sends them after a signal they have.
  final bool offline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(recordingsListNotifierProvider.notifier);

    return EmptyState(
      icon: offline ? LucideIcons.cloudOff : LucideIcons.alertTriangle,
      title: offline
          ? l10n.recordings_offlineFilterTitle
          : l10n.recordings_filterErrorTitle,
      description: offline
          ? l10n.recordings_offlineFilterDescription
          : l10n.recordings_filterErrorDescription,
      // Dropping the filter is the only way forward offline; a failed request
      // is worth asking again before giving the filter up.
      action: offline
          ? FilledButton.icon(
              onPressed: notifier.clearAllFilters,
              icon: const Icon(LucideIcons.x, size: 18),
              label: Text(l10n.filter_clearAll),
            )
          : FilledButton.icon(
              onPressed: notifier.fetchRecordings,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: Text(l10n.common_retry),
            ),
    );
  }
}
