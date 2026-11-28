import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import 'brush_sign.dart';
import 'hand_cut_button_style.dart';

export 'hand_cut_button_style.dart' show HandCutButtonTone;

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.sign,
    this.tone = HandCutButtonTone.ink,
  });

  final String label;
  final VoidCallback? onPressed;
  final Sign? sign;
  final HandCutButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final sign = this.sign;
    return FilledButton(
      onPressed: onPressed,
      style: handCutButtonStyle(
        AppColors.of(context),
        PrintedShadows.of(context),
        tone,
        Theme.of(context).textTheme.labelLarge,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sign != null) ...[
            BrushSign(sign, size: 18),
            const SizedBox(width: 10),
          ],
          Flexible(child: Text(label)),
        ],
      ),
    );
  }
}
