import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_opacity.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import 'hand_cut_rect.dart';
import 'printed_shadow_scope.dart';

const _buttonRadius = 14.0;
const _shadowOffset = Offset(3, 4);
const _clipRoom = 1.02;

class HandCutButtonBorder extends OutlinedBorder {
  const HandCutButtonBorder({
    this.radius = _buttonRadius,
    this.shadowOffset = _shadowOffset,
    super.side,
  });

  final double radius;
  final Offset shadowOffset;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      handCutRectOutline(rect.size, radius).shift(rect.topLeft);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final outline = getInnerPath(rect);
    final piece = Path.combine(
      PathOperation.union,
      outline,
      outline.shift(shadowOffset),
    );
    final c = rect.center;
    final grow = Float64List.fromList([
      _clipRoom, 0, 0, 0, //
      0, _clipRoom, 0, 0,
      0, 0, 1, 0,
      c.dx * (1 - _clipRoom), c.dy * (1 - _clipRoom), 0, 1,
    ]);
    return piece.transform(grow);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => HandCutButtonBorder(
    radius: radius * t,
    shadowOffset: shadowOffset * t,
    side: side.scale(t),
  );

  @override
  OutlinedBorder copyWith({BorderSide? side}) => HandCutButtonBorder(
    radius: radius,
    shadowOffset: shadowOffset,
    side: side ?? this.side,
  );
}

enum HandCutButtonTone { ink, quiet, quietOnCard }

ButtonStyle handCutButtonStyle(
  AppColorSet c,
  PrintedShadows shadows,
  HandCutButtonTone tone,
) {
  final (fill, label, shadow) = switch (tone) {
    HandCutButtonTone.ink => (c.primary, c.onPrimary, shadows.ink),
    HandCutButtonTone.quiet => (c.card, c.foreground, shadows.paper),
    HandCutButtonTone.quietOnCard => (c.pale, c.foreground, shadows.paper),
  };
  Color labelFor(Set<WidgetState> s) =>
      s.contains(WidgetState.disabled) ? c.secondary : label;

  return ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: SpacingScale.s20),
    ),
    shape: const WidgetStatePropertyAll(HandCutButtonBorder()),
    elevation: const WidgetStatePropertyAll(0),
    shadowColor: const WidgetStatePropertyAll(Colors.transparent),
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    foregroundColor: WidgetStateProperty.resolveWith(labelFor),
    iconSize: const WidgetStatePropertyAll(18),
    backgroundBuilder: (context, states, child) {
      final disabled = states.contains(WidgetState.disabled);
      final printed = !disabled && !PrintedShadowScope.paints(context);
      final base = disabled ? c.tint : fill;
      final tint = switch (states) {
        _ when disabled => 0.0,
        _ when states.contains(WidgetState.focused) => OpacityScale.o10,
        _ when states.contains(WidgetState.hovered) => OpacityScale.o08,
        _ => 0.0,
      };
      final painted = CustomPaint(
        painter: HandCutRectPainter(
          fill: Color.alphaBlend(label.withValues(alpha: tint), base),
          radius: _buttonRadius,
          shadow: printed ? shadow : null,
        ),
        child: child,
      );
      return printed ? PrintedShadowScope(child: painted) : painted;
    },
  );
}
