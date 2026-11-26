import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum RoundButtonSize {
  play(44),
  playLarge(56),
  action(58),
  control(64);

  const RoundButtonSize(this.diameter);

  final double diameter;
}

enum RoundButtonTone { accent, control, soft }

class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.size = RoundButtonSize.action,
    this.tone = RoundButtonTone.accent,
  });

  static const double minTouchTarget = 48;

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final RoundButtonSize size;
  final RoundButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final (fill, foreground) = switch (tone) {
      RoundButtonTone.accent => (colors.accent, colors.onPrimary),
      RoundButtonTone.control => (colors.card, colors.primary),
      RoundButtonTone.soft => (colors.soft, colors.onSoft),
    };
    final target = math.max(size.diameter, minTouchTarget);

    return Semantics(
      label: semanticLabel,
      button: true,
      excludeSemantics: true,
      onTap: onPressed,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: target,
            child: Center(
              child: Ink(
                width: size.diameter,
                height: size.diameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fill,
                  border: tone == RoundButtonTone.control
                      ? Border.all(color: colors.border, width: 1.5)
                      : null,
                  boxShadow: tone == RoundButtonTone.accent
                      ? [
                          BoxShadow(
                            color: colors.accent.withValues(alpha: 0.6),
                            blurRadius: 24,
                            spreadRadius: -10,
                            offset: const Offset(0, 12),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  color: foreground,
                  size: tone == RoundButtonTone.soft ? 18 : 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
