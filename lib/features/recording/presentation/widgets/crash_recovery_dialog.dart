import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../data/providers.dart';
import '../../data/services/recovery_coordinator.dart';

Future<void> showCrashRecoveryDialog(
  BuildContext context,
  WidgetRef ref,
  RecoveryPrompt prompt,
) async {
  final l10n = AppLocalizations.of(context);
  final minutes = prompt.minutes <= 0 ? 1 : prompt.minutes;
  final action = await showDialog<_RecoveryAction>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.recording_recoverTitle),
      content: Text(l10n.recording_recoverBody(minutes)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(_RecoveryAction.discard),
          child: Text(l10n.recording_recoverDiscard),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(_RecoveryAction.recover),
          child: Text(l10n.recording_recoverButton),
        ),
      ],
    ),
  );

  if (!context.mounted) return;
  ref.read(pendingRecoveryProvider.notifier).state = null;

  switch (action) {
    case _RecoveryAction.recover:
      context.push('/recover/${prompt.sessionId}');
      break;
    case _RecoveryAction.discard:
    case null:
      final repo = ref.read(recordingSessionRepositoryProvider);
      await repo.markDiscarded(prompt.sessionId);
      break;
  }
}

enum _RecoveryAction { recover, discard }
