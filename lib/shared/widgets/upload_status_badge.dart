import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import 'app_disc.dart';
import 'brush_sign.dart';

const double _signSize = 18;
const double _rowWord = 13;
const double _pageWord = 15;

enum _SendState { sent, sending, onDevice, needsYou }

_SendState _stateOf(String status) => switch (status) {
  'uploaded' || 'verified' => _SendState.sent,
  'uploading' || 'web_uploading' => _SendState.sending,
  _ when status.startsWith('failed') => _SendState.needsYou,
  _ => _SendState.onDevice,
};

class UploadStatusBadge extends StatelessWidget {
  const UploadStatusBadge({
    super.key,
    required this.status,
    this.percent,
    this.compact = false,
  });

  final String status;
  final int? percent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final state = _stateOf(status);
    final (sign, color, word) = switch (state) {
      _SendState.sent => (Sign.check, colors.info, l10n.sendState_sent),
      _SendState.sending => (
        Sign.up,
        colors.deep,
        percent == null
            ? l10n.sendState_sending
            : l10n.sendState_sendingPercent(percent!),
      ),
      _SendState.onDevice => (
        Sign.device,
        colors.secondary,
        l10n.sendState_onDevice,
      ),
      _SendState.needsYou => (Sign.info, colors.error, l10n.sendState_needsYou),
    };

    if (compact) {
      return switch (state) {
        _SendState.sent => BrushSign(
          sign,
          size: _signSize,
          color: color,
          label: word,
        ),
        _SendState.needsYou => _needsYouDisc(colors, label: word),
        _ => _word(context, word, color, _rowWord),
      };
    }

    final mark = state == _SendState.needsYou
        ? _needsYouDisc(colors)
        : BrushSign(sign, size: _signSize, color: color);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: SpacingScale.s8),
        Flexible(child: _word(context, word, color, _pageWord)),
      ],
    );
  }

  Widget _needsYouDisc(AppColorSet colors, {String? label}) => AppDisc(
    size: DiscSize.small,
    tone: DiscTone.failed,
    child: BrushSign(
      Sign.info,
      size: _signSize,
      color: colors.onSoft,
      label: label,
    ),
  );

  Widget _word(
    BuildContext context,
    String word,
    Color color,
    double fontSize,
  ) => Text(
    word,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w600,
    ),
  );
}
