import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

Future<bool> showBlockNavigationDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.recording_blockNavTitle),
      content: Text(l10n.recording_blockNavMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.recording_blockNavDiscardAndLeave),
        ),
      ],
    ),
  );
  return result ?? false;
}
