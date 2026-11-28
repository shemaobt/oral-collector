import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import 'hand_cut_rect.dart';
import 'printed_shadow_scope.dart';

const int _maxParts = 3;
const double _minHeight = 48;
const double _trackPad = 4;
const double _trackRadius = 14;
const double _partRadius = 10;
const double _partPadX = 8;

class AppSelector extends StatelessWidget {
  AppSelector({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  }) : assert(
         labels.isNotEmpty && labels.length <= _maxParts,
         'The selector takes one to three parts.',
       ),
       assert(selectedIndex >= 0 && selectedIndex < labels.length);

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final shadow = PrintedShadows.of(context).paper;
    final text = Theme.of(context).textTheme.bodyMedium!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.tint,
        borderRadius: BorderRadius.circular(_trackRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_trackPad),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: _minHeight - 2 * _trackPad,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    child: _Part(
                      label: labels[i],
                      selected: i == selectedIndex,
                      fill: dark ? colors.pale : colors.card,
                      shadow: shadow,
                      style: text.copyWith(
                        fontSize: 15,
                        fontWeight: i == selectedIndex
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: i == selectedIndex
                            ? colors.foreground
                            : colors.secondary,
                      ),
                      onTap: () => onChanged(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Part extends StatelessWidget {
  const _Part({
    required this.label,
    required this.selected,
    required this.fill,
    required this.shadow,
    required this.style,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color fill;
  final Color shadow;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final part = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_partRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _partPadX),
          child: Center(
            child: Text(label, style: style, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
    return Semantics(
      checked: selected,
      inMutuallyExclusiveGroup: true,
      onTap: onTap,
      excludeSemantics: true,
      label: label,
      child: selected
          ? PrintedShadowScope(
              child: CustomPaint(
                painter: HandCutRectPainter(
                  fill: fill,
                  radius: _partRadius,
                  shadow: shadow,
                  shadowOffset: markShadowOffset,
                ),
                child: part,
              ),
            )
          : part,
    );
  }
}
