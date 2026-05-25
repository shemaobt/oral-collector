import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/recording_session_notifier.dart';
import 'block_navigation_dialog.dart';

class RecordingNavigationGuard extends ConsumerWidget {
  const RecordingNavigationGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inProgress = ref.watch(
      recordingSessionNotifierProvider.select((s) => s.isInProgress),
    );
    return PopScope<Object?>(
      canPop: !inProgress,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirmed = await showBlockNavigationDialog(context);
        if (!confirmed) return;
        if (!context.mounted) return;
        await ref
            .read(recordingSessionNotifierProvider.notifier)
            .discardRecording();
        if (!context.mounted) return;
        Navigator.of(context).pop();
      },
      child: child,
    );
  }
}

Future<bool> confirmRecordingNavigationFromTab(
  BuildContext context,
  WidgetRef ref,
) async {
  final inProgress = ref.read(
    recordingSessionNotifierProvider.select((s) => s.isInProgress),
  );
  if (!inProgress) return true;
  final confirmed = await showBlockNavigationDialog(context);
  if (!confirmed) return false;
  await ref.read(recordingSessionNotifierProvider.notifier).discardRecording();
  return true;
}
