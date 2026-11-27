import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_question.dart';

Future<bool> showBlockNavigationDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final result = await showAppQuestion<bool>(
    context: context,
    isDismissible: false,
    title: l10n.recording_blockNavTitle,
    message: l10n.recording_blockNavMessage,
    actionsBuilder: (ctx) => [
      TextButton(
        onPressed: () => Navigator.of(ctx).pop(false),
        child: Text(l10n.common_cancel),
      ),
      TextButton(
        onPressed: () => Navigator.of(ctx).pop(true),
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(ctx).colorScheme.error,
        ),
        child: Text(l10n.recording_blockNavDiscardAndLeave),
      ),
    ],
  );
  return result ?? false;
}
