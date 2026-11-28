import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brush_sign.dart';
import '../../../../shared/widgets/round_button.dart';
import '../../../../shared/widgets/sound_strokes.dart';

class ControlButton extends StatelessWidget {
  const ControlButton({
    super.key,
    required this.sign,
    required this.label,
    required this.onTap,
  }) : stop = false,
       sounding = false,
       semanticLabel = null;

  const ControlButton.stop({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
    required this.sounding,
  }) : sign = Sign.stop,
       stop = true;

  final Sign sign;
  final String label;
  final String? semanticLabel;
  final VoidCallback onTap;
  final bool stop;
  final bool sounding;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final size = stop ? RoundButtonSize.huge : RoundButtonSize.medium;
    final button = RoundButton.sign(
      sign: sign,
      semanticLabel: semanticLabel ?? label,
      size: size,
      tone: stop ? RoundButtonTone.record : RoundButtonTone.resting,
      signSize: size.diameter * 0.46,
      onPressed: () {
        stop ? HapticFeedback.heavyImpact() : HapticFeedback.lightImpact();
        onTap();
      },
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        sounding
            ? SoundStrokes(
                diameter: size.diameter,
                color: colors.mic,
                child: button,
              )
            : button,
        const SizedBox(height: 14),
        ExcludeSemantics(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 13,
              color: colors.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
