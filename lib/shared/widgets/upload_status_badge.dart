import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'app_disc.dart';
import 'brush_sign.dart';

const double _signSize = 18;

enum _SendState { sent, sending, onDevice, needsYou }

_SendState _stateOf(String status) => switch (status) {
  'uploaded' || 'verified' => _SendState.sent,
  'uploading' || 'web_uploading' => _SendState.sending,
  _ when status.startsWith('failed') => _SendState.needsYou,
  _ => _SendState.onDevice,
};

class UploadStatusBadge extends StatelessWidget {
  const UploadStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return switch (_stateOf(status)) {
      _SendState.sent => BrushSign(
        Sign.check,
        size: _signSize,
        color: colors.info,
        label: l10n.sendState_sent,
      ),
      _SendState.sending => _word(context, l10n.sendState_sending, colors.deep),
      _SendState.onDevice => _word(
        context,
        l10n.sendState_onDevice,
        colors.secondary,
      ),
      _SendState.needsYou => _needsYouDisc(colors, l10n.sendState_needsYou),
    };
  }

  Widget _needsYouDisc(AppColorSet colors, String label) => AppDisc(
    size: DiscSize.small,
    tone: DiscTone.failed,
    child: BrushSign(
      Sign.info,
      size: _signSize,
      color: colors.onSoft,
      label: label,
    ),
  );

  Widget _word(BuildContext context, String word, Color color) => Text(
    word,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      fontSize: 13,
      color: color,
      fontWeight: FontWeight.w600,
    ),
  );
}
