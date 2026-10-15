import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../trim_edit_decision.dart';

Future<TrimSaveMode?> showTrimSaveChoiceDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final options = {
    TrimSaveMode.split: l10n.trim_keepSegmentsSeparate,
    TrimSaveMode.saveAsNew: l10n.trim_saveAsNewRecording,
    TrimSaveMode.removeStretch: l10n.trim_removeStretch,
  };
  return showDialog<TrimSaveMode>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.trim_saveConfirmTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.trim_saveChoiceBody),
          for (final MapEntry(key: mode, value: label) in options.entries)
            Padding(
              padding: const EdgeInsets.only(top: SpacingScale.s12),
              child: FilledButton.tonal(
                onPressed: () => Navigator.of(ctx).pop(mode),
                child: Text(label, textAlign: TextAlign.center),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.common_cancel),
        ),
      ],
    ),
  );
}
