import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import 'brush_sign.dart';
import 'hand_cut_button_style.dart';

export 'hand_cut_button_style.dart' show HandCutButtonSize, HandCutButtonTone;

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.sign,
    this.tone = HandCutButtonTone.ink,
    this.size = HandCutButtonSize.regular,
  });

  final String label;
  final VoidCallback? onPressed;
  final Sign? sign;
  final HandCutButtonTone tone;
  final HandCutButtonSize size;

  @override
  Widget build(BuildContext context) {
    final sign = this.sign;
    final small = size == HandCutButtonSize.small;
    return FilledButton(
      onPressed: onPressed,
      style: handCutButtonStyle(
        AppColors.of(context),
        PrintedShadows.of(context),
        tone,
        Theme.of(context).textTheme.labelLarge,
        size: size,
        dark: Theme.of(context).brightness == Brightness.dark,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sign != null) ...[
            BrushSign(sign, size: small ? 14 : 18),
            SizedBox(width: small ? 7 : 10),
          ],
          Flexible(child: Text(label)),
        ],
      ),
    );
  }
}
