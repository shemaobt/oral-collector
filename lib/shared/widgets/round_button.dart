import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_disc.dart';
import 'pressable.dart';

enum RoundButtonSize {
  small(DiscSize.medium),
  medium(DiscSize.large),
  big(DiscSize.big),
  huge(DiscSize.huge);

  const RoundButtonSize(this.disc);

  final DiscSize disc;

  double get diameter => disc.diameter;
}

enum RoundButtonTone {
  resting(DiscTone.resting),
  action(DiscTone.action),
  record(DiscTone.record),
  live(DiscTone.live),
  working(DiscTone.working);

  const RoundButtonTone(this.disc);

  final DiscTone disc;
}

class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.size = RoundButtonSize.medium,
    this.tone = RoundButtonTone.action,
  });

  static const double minTouchTarget = 48;

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final RoundButtonSize size;
  final RoundButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final target = math.max(size.diameter, minTouchTarget);

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      excludeSemantics: true,
      onTap: onPressed,
      child: SizedBox.square(
        dimension: target,
        child: Pressable(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Center(
            child: AppDisc(
              size: size.disc,
              tone: tone.disc,
              pressable: true,
              enabled: onPressed != null,
              child: Icon(icon),
            ),
          ),
        ),
      ),
    );
  }
}
