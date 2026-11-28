import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_opacity.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import 'hand_cut_rect.dart';
import 'pressable.dart';
import 'printed_shadow_scope.dart';

const _clipRoom = 1.02;

class HandCutButtonBorder extends OutlinedBorder {
  const HandCutButtonBorder({
    required this.radius,
    required this.shadowOffset,
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

enum HandCutButtonTone { ink, quiet, quietOnCard, danger }

enum HandCutButtonSize {
  regular(52, 14, Offset(3, 4), SpacingScale.s20, 17),
  small(44, RadiusScale.r12, Offset(2, 3), 14, 15);

  const HandCutButtonSize(
    this.height,
    this.radius,
    this.shadowOffset,
    this.padding,
    this.fontSize,
  );

  final double height;
  final double radius;
  final Offset shadowOffset;
  final double padding;
  final double fontSize;
}

ButtonStyle handCutButtonStyle(
  AppColorSet c,
  PrintedShadows shadows,
  HandCutButtonTone tone,
  TextStyle? labelStyle, {
  HandCutButtonSize size = HandCutButtonSize.regular,
  required bool dark,
}) {
  final (fill, label, shadow) = switch (tone) {
    HandCutButtonTone.ink => (c.primary, c.onPrimary, shadows.ink),
    HandCutButtonTone.quiet => (c.card, c.foreground, shadows.paper),
    HandCutButtonTone.quietOnCard => (c.pale, c.foreground, shadows.paper),
    HandCutButtonTone.danger => (
      c.error,
      dark ? c.background : AppColors.white,
      shadows.danger,
    ),
  };
  Color labelFor(Set<WidgetState> s) =>
      s.contains(WidgetState.disabled) ? c.secondary : label;

  return ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size(0, size.height)),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: size.padding),
    ),
    shape: WidgetStatePropertyAll(
      HandCutButtonBorder(radius: size.radius, shadowOffset: size.shadowOffset),
    ),
    elevation: const WidgetStatePropertyAll(0),
    backgroundColor: const WidgetStatePropertyAll(AppColors.transparent),
    shadowColor: const WidgetStatePropertyAll(AppColors.transparent),
    overlayColor: const WidgetStatePropertyAll(AppColors.transparent),
    textStyle: WidgetStatePropertyAll(
      (labelStyle ?? const TextStyle()).copyWith(
        fontSize: size.fontSize,
        fontWeight: FontWeight.w600,
      ),
    ),
    foregroundColor: WidgetStateProperty.resolveWith(labelFor),
    iconSize: const WidgetStatePropertyAll(18),
    backgroundBuilder: (context, states, child) => _HighlightModeBuilder(
      builder: (traditional) {
        final disabled = states.contains(WidgetState.disabled);
        final printed = !disabled && !PrintedShadowScope.paints(context);
        final base = disabled ? c.tint : fill;
        final tint = switch (states) {
          _ when disabled => 0.0,
          _ when traditional && states.contains(WidgetState.focused) =>
            OpacityScale.o10,
          _ when states.contains(WidgetState.hovered) => OpacityScale.o08,
          _ => 0.0,
        };
        final painted = CustomPaint(
          painter: HandCutRectPainter(
            fill: Color.alphaBlend(label.withValues(alpha: tint), base),
            radius: size.radius,
            shadowOffset: size.shadowOffset,
            shadow: printed ? shadow : null,
          ),
          child: child,
        );
        final pressed = PressLook(
          down: states.contains(WidgetState.pressed),
          child: painted,
        );
        return printed ? PrintedShadowScope(child: pressed) : pressed;
      },
    ),
  );
}

class _HighlightModeBuilder extends StatefulWidget {
  const _HighlightModeBuilder({required this.builder});

  final Widget Function(bool traditional) builder;

  @override
  State<_HighlightModeBuilder> createState() => _HighlightModeBuilderState();
}

class _HighlightModeBuilderState extends State<_HighlightModeBuilder> {
  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onModeChange);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onModeChange);
    super.dispose();
  }

  void _onModeChange(FocusHighlightMode mode) => setState(() {});

  @override
  Widget build(BuildContext context) => widget.builder(
    FocusManager.instance.highlightMode == FocusHighlightMode.traditional,
  );
}
