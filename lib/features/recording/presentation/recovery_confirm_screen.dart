import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/l10n/content_l10n.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../genre/presentation/notifiers/genre_notifier.dart';
import 'notifiers/interrupted_sessions_notifier.dart';
import 'widgets/confirmation_step.dart';

/// Hosts the [ConfirmationStep] for a crash-recovered recording. The audio is
/// already finalized on disk but the session is still `crashed`: saving here
/// marks it recovered (and materializes the recording), discarding marks it
/// discarded, and leaving without deciding keeps it in the recovery banner —
/// the segments are preserved, so nothing is lost.
class RecoveryConfirmScreen extends ConsumerWidget {
  const RecoveryConfirmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingRecoveryProvider);
    final l10n = AppLocalizations.of(context);

    // Nothing pending (e.g. a refresh/deep-link straight to this route): there
    // is nothing to confirm, so bounce home.
    if (pending == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/home');
      });
      return const SizedBox.shrink();
    }

    final notifier = ref.read(interruptedSessionsNotifierProvider.notifier);
    final genreState = ref.watch(genreNotifierProvider);
    final genre = genreState.genres
        .where((g) => g.id == pending.genreId)
        .firstOrNull;
    final subcategory = genre?.subcategories
        .where((s) => s.id == pending.subcategoryId)
        .firstOrNull;

    void clearPending() =>
        ref.read(pendingRecoveryProvider.notifier).state = null;

    return Scaffold(
      appBar: ScreenHeader(
        title: l10n.recording_saveRecording,
        subtitle: l10n.quickRecord_subtitle,
        icon: LucideIcons.save,
      ),
      body: ConfirmationStep(
        result: pending.result,
        genreId: pending.genreId,
        subcategoryId: pending.subcategoryId,
        registerId: null,
        genreName: genre != null ? localizedGenreName(l10n, genre.name) : null,
        subcategoryName: subcategory != null
            ? localizedSubcategoryName(l10n, subcategory.name)
            : null,
        registerName: null,
        showReRecord: false,
        onReRecord: () {},
        onSaved: () {
          notifier.confirmRecovery(
            pending.sessionId,
            keepPath: pending.result.filePath,
            durationSeconds: pending.result.durationSeconds,
          );
          clearPending();
          context.go('/recordings');
        },
        onDiscard: () {
          // ConfirmationStep already deleted the finalized file; discard() just
          // clears the kept segments and marks the session discarded.
          notifier.discard(pending.sessionId);
          clearPending();
          context.go('/home');
        },
      ),
    );
  }
}
