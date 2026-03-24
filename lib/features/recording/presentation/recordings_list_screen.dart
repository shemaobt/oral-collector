import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/l10n/content_l10n.dart';
import '../../../core/database/app_database.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/preview_helpers.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/status_banner.dart';
import '../../../shared/widgets/sync_status_indicator.dart';
import '../../genre/presentation/notifiers/genre_notifier.dart';
import '../../project/presentation/notifiers/project_notifier.dart';
import '../data/providers.dart';
import '../domain/entities/register.dart';
import '../../sync/presentation/notifiers/sync_notifier.dart';
import 'notifiers/recordings_list_notifier.dart';
import 'widgets/genre_filter_bar.dart';
import 'widgets/recording_card.dart';
import 'widgets/status_filter_bar.dart';

@Preview(name: 'Recordings List', wrapper: previewWrapper)
Widget recordingsListPreview() => const RecordingsListScreen();

class RecordingsListScreen extends ConsumerStatefulWidget {
  const RecordingsListScreen({super.key});

  @override
  ConsumerState<RecordingsListScreen> createState() =>
      _RecordingsListScreenState();
}

class _RecordingsListScreenState extends ConsumerState<RecordingsListScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_refreshAll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAll();
    }
  }

  Future<void> _deleteRecording(LocalRecording recording) async {
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

    final serverId = recording.serverId ?? recording.id;
    try {
      final apiRepo = ref.read(recordingApiRepositoryProvider);
      await apiRepo.deleteRecording(serverId);
    } on ForbiddenException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.recording_deleteNoPermission),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    } catch (_) {
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.recording_deleteFailed)));
        }
        return;
      }
    }

    if (!kIsWeb) {
      final repo = ref.read(localRecordingRepositoryProvider);
      await repo.deleteRecording(recording.id);
    }

    ref.read(recordingsListNotifierProvider.notifier).fetchRecordings();
  }

  void _refreshAll() {
    final isOnline = ref.read(syncNotifierProvider).isOnline;
    ref.read(recordingsListNotifierProvider.notifier).fetchRecordings();
    if (!isOnline) return;
    ref.read(genreNotifierProvider.notifier).fetchGenres();
    ref.read(syncNotifierProvider.notifier).processQueue();
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
    final genreState = ref.watch(genreNotifierProvider);
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
                  color: Colors.transparent,
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
                          color: Colors.white,
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
              slivers: [
                ScreenHeaderSliver(
                  title: l10n.recordings_title,
                  subtitle: l10n.recordings_subtitle,
                  icon: LucideIcons.mic,
                  actions: const [SyncStatusIndicator()],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: StatusFilterBar(
                      colors: colors,
                      theme: theme,
                      currentFilter: ref.watch(
                        recordingsListNotifierProvider.select(
                          (s) => s.selectedFilter,
                        ),
                      ),
                      onFilterChanged: (filter) => ref
                          .read(recordingsListNotifierProvider.notifier)
                          .setStatusFilter(filter),
                    ),
                  ),
                ),

                if (isOffline)
                  const SliverToBoxAdapter(child: StatusBanner.offline()),

                if (genreState.genres.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: GenreFilterBar(
                        colors: colors,
                        theme: theme,
                        genres: genreState.genres,
                        selectedGenreId: ref.watch(
                          recordingsListNotifierProvider.select(
                            (s) => s.selectedGenreId,
                          ),
                        ),
                        onGenreSelected: (id) => ref
                            .read(recordingsListNotifierProvider.notifier)
                            .setGenreFilter(id),
                      ),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      l10n.recordings_count(filtered.length),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.secondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),

                listState.isLoading
                    ? const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : filtered.isEmpty
                    ? SliverFillRemaining(
                        child: EmptyState(
                          icon: LucideIcons.mic,
                          title: l10n.recordings_noRecordings,
                          description: l10n.recordings_noRecordingsSubtitle,
                        ),
                      )
                    : SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          AppShell.scrollPaddingFor(context),
                        ),
                        sliver: SliverList.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
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
                                padding: const EdgeInsets.only(right: 24),
                                decoration: BoxDecoration(
                                  color: colors.error.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
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
                                relativeDate: formatTimeAgo(
                                  recording.recordedAt,
                                  l10n,
                                ),
                                formattedDuration: formatDurationHMS(
                                  recording.durationSeconds,
                                ),
                                onDelete: () => _deleteRecording(recording),
                                onTap: () async {
                                  await context.push(
                                    '/recording/${recording.id}',
                                  );
                                  ref
                                      .read(
                                        recordingsListNotifierProvider.notifier,
                                      )
                                      .fetchRecordings();
                                },
                              ),
                            );
                          },
                        ),
                      ),
              ],
            ),
    );
  }
}
