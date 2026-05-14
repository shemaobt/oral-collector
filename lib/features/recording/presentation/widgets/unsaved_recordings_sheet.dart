import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/format.dart';
import '../../data/services/recovery_coordinator.dart';
import '../notifiers/interrupted_sessions_notifier.dart';
import '../notifiers/recording_session_notifier.dart';
import '../notifiers/recording_session_state.dart';
import 'unsaved_recording_row.dart';

class UnsavedRecordingsSheet extends ConsumerWidget {
  const UnsavedRecordingsSheet({
    super.key,
    required this.onSessionSaved,
    this.onSessionResumed,
  });

  final ValueChanged<RecordingResult> onSessionSaved;
  final VoidCallback? onSessionResumed;

  static Future<void> show(
    BuildContext context,
    ValueChanged<RecordingResult> onSessionSaved, {
    VoidCallback? onSessionResumed,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UnsavedRecordingsSheet(
        onSessionSaved: onSessionSaved,
        onSessionResumed: onSessionResumed,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(interruptedSessionsProvider);
    final colors = AppColors.of(context);
    final localeTag = Localizations.localeOf(context).toString();

    if (sessions.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: _Handle(color: colors.border),
              ),
              SliverToBoxAdapter(
                child: _SheetHeader(
                  count: sessions.length,
                  onDiscardAll: () =>
                      _handleDiscardAll(context, ref, sessions.length),
                ),
              ),
              SliverToBoxAdapter(
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: colors.border.withValues(alpha: 0.3),
                ),
              ),
              SliverList.separated(
                itemCount: sessions.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: colors.border.withValues(alpha: 0.25),
                ),
                itemBuilder: (context, index) {
                  final l10n = AppLocalizations.of(context);
                  final session = sessions[index];
                  final isMostRecent = index == 0;
                  final number = sessions.length - index;
                  return UnsavedRecordingRow(
                    session: session,
                    title: isMostRecent
                        ? l10n.recovery_mostRecent
                        : l10n.recovery_recordingNumbered(number),
                    showNewBadge: isMostRecent,
                    localeTag: localeTag,
                    onResume: () => _handleResume(context, ref, session),
                    onSave: () => _handleSave(context, ref, session),
                    onDiscard: () =>
                        _handleDiscardOne(context, ref, session),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 16,
                ),
              ),
            ],
          ),
        );

      },
    );

  }

  Future<void> _handleResume(
    BuildContext context,
    WidgetRef ref,
    InterruptedSession session,
  ) async {
    HapticFeedback.selectionClick();
    final notifier = ref.read(recordingSessionNotifierProvider.notifier);
    final ok = await notifier.loadInterruptedSession(session.sessionId);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    if (!ok) return;
    onSessionResumed?.call();
  }

  Future<void> _handleSave(
    BuildContext context,
    WidgetRef ref,
    InterruptedSession session,
  ) async {
    HapticFeedback.selectionClick();
    final notifier = ref.read(interruptedSessionsNotifierProvider.notifier);
    final result = await notifier.save(session.sessionId);
    if (!context.mounted) return;
    if (result != null) {
      Navigator.of(context).pop();
      onSessionSaved(result);
    }
  }

  Future<void> _handleDiscardOne(
    BuildContext context,
    WidgetRef ref,
    InterruptedSession session,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.recovery_confirmDiscardTitle),
        content: Text(
          l10n.recovery_confirmDiscardBody(
            formatDurationCompactWithSeconds(session.totalDuration),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.recording_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.recovery_discard),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    HapticFeedback.mediumImpact();
    final notifier = ref.read(interruptedSessionsNotifierProvider.notifier);
    await notifier.discard(session.sessionId);
  }

  Future<void> _handleDiscardAll(
    BuildContext context,
    WidgetRef ref,
    int count,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.recovery_discardAllTitle),
        content: Text(l10n.recovery_discardAllBody(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.recording_cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.of(ctx).error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.recovery_discardAll),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    HapticFeedback.mediumImpact();
    final notifier = ref.read(interruptedSessionsNotifierProvider.notifier);
    final ids = ref
        .read(interruptedSessionsProvider)
        .map((s) => s.sessionId)
        .toList();
    for (final id in ids) {
      await notifier.discard(id);
    }
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _Handle extends StatelessWidget {
  const _Handle({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(top: 10, bottom: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.count, required this.onDiscardAll});

  final int count;
  final VoidCallback onDiscardAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.recovery_unsavedTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.recovery_unsavedSubtitle(count),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.secondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onDiscardAll,
            icon: Icon(LucideIcons.trash2, size: 16, color: colors.error),
            label: Text(
              l10n.recovery_discardAll,
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

