import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_opacity.dart';
import 'brush_sign.dart';
import 'hand_cut_disc.dart';

const double _size = 26;
const double _ringSize = 30;
const double _centre = 14;
const double _minHeight = 44;
const double _gap = 12;
const double _units = 100;

const String _ringOutline =
    'M45.9 9.2L48.7 7.1L51.7 6.2L54.8 5.7L57.8 5.9L60.9 6.2L64.0 6.7L67.1 7.4L70.2 8.4L73.2 9.5L76.1 10.9L78.9 12.6L81.6 14.6L84.0 16.8L86.2 19.2L88.1 21.8L89.8 24.6L91.3 27.5L92.5 30.5L93.6 33.6L94.4 36.7L95.0 39.9L95.4 43.0L95.6 46.2L95.7 49.3L95.5 52.5L95.2 55.6L94.7 58.7L93.9 61.7L93.0 64.7L91.8 67.6L90.3 70.4L88.7 73.0L86.9 75.6L84.9 78.0L82.8 80.2L80.6 82.3L78.2 84.3L75.8 86.2L73.3 87.9L70.7 89.5L68.0 91.0L65.2 92.4L62.3 93.6L59.3 94.6L56.2 95.3L53.1 95.9L50.0 96.1L46.8 96.1L43.6 95.8L40.5 95.1L37.4 94.2L34.5 93.1L31.6 91.7L28.9 90.2L26.3 88.5L23.8 86.6L21.4 84.6L19.1 82.5L17.0 80.3L14.9 78.0L13.0 75.5L11.2 73.0L9.6 70.3L8.2 67.5L7.1 64.6L6.2 61.6L5.5 58.6L5.1 55.5L5.0 52.3L5.2 49.2L5.6 46.2L6.2 43.2L7.1 40.2L8.1 37.4L9.3 34.6L10.6 31.9L12.1 29.3L13.7 26.8L15.5 24.4L17.4 22.1L19.4 20.0L21.6 18.0L23.9 16.2L26.4 14.5L28.9 13.1L31.6 11.8L34.3 10.8L37.1 10.0L39.9 9.3L42.8 8.8L45.6 8.5L48.5 8.6L51.4 9.0L54.1 9.5L56.9 10.3L59.3 11.8L59.3 11.8L56.5 12.6L53.8 13.0L51.2 13.5L48.7 14.1L46.3 14.8L43.9 15.4L41.6 16.1L39.3 16.9L37.1 17.8L34.9 18.8L32.8 19.8L30.7 21.0L28.6 22.3L26.6 23.6L24.6 25.1L22.8 26.7L21.0 28.5L19.4 30.4L17.9 32.5L16.7 34.7L15.6 37.0L14.8 39.4L14.2 41.8L13.8 44.3L13.7 46.9L13.7 49.4L13.9 51.9L14.2 54.4L14.7 56.8L15.2 59.2L15.9 61.6L16.7 63.9L17.7 66.3L18.8 68.5L20.0 70.7L21.4 72.8L22.9 74.8L24.7 76.6L26.6 78.3L28.6 79.9L30.8 81.2L33.0 82.3L35.3 83.3L37.7 84.1L40.1 84.7L42.6 85.2L45.0 85.5L47.5 85.7L50.0 85.8L52.4 85.8L54.9 85.6L57.4 85.2L59.8 84.7L62.2 84.0L64.5 83.0L66.7 81.9L68.8 80.6L70.8 79.1L72.7 77.5L74.4 75.8L76.0 73.9L77.4 71.9L78.8 69.9L80.0 67.9L81.2 65.8L82.4 63.6L83.4 61.4L84.4 59.2L85.3 56.9L86.1 54.5L86.8 52.0L87.2 49.4L87.5 46.8L87.6 44.2L87.4 41.6L86.9 38.9L86.2 36.4L85.2 33.9L84.1 31.5L82.7 29.2L81.1 27.0L79.4 25.0L77.6 23.1L75.6 21.3L73.5 19.6L71.4 18.1L69.1 16.7L66.8 15.4L64.4 14.3L61.9 13.4L59.3 12.7L56.7 12.2L54.1 11.9L51.5 11.3L48.8 10.7L45.9 9.2Z';

final Path _ring = parseOutline(_ringOutline);

class _RingPainter extends CustomPainter {
  const _RingPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _units);
    canvas.drawPath(_ring, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.color != color;
}

class AppChoice extends StatelessWidget {
  const AppChoice({
    super.key,
    required this.chosen,
    required this.onChosen,
    this.label,
  });

  final bool chosen;
  final VoidCallback? onChosen;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final ring = chosen ? colors.primary : colors.secondary;
    final mark = SizedBox.square(
      dimension: _size,
      child: OverflowBox(
        maxWidth: _ringSize,
        maxHeight: _ringSize,
        child: CustomPaint(
          size: const Size.square(_ringSize),
          painter: _RingPainter(ring),
          child: chosen
              ? Center(
                  child: CustomPaint(
                    size: const Size.square(_centre),
                    painter: HandCutDiscPainter(fill: colors.primary),
                  ),
                )
              : null,
        ),
      ),
    );
    final text = label;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minHeight),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: _gap,
        children: [
          mark,
          if (text != null)
            Expanded(
              child: Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: colors.foreground),
              ),
            ),
        ],
      ),
    );
    final enabled = onChosen != null;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: Semantics(
        checked: chosen,
        inMutuallyExclusiveGroup: true,
        enabled: enabled,
        label: text,
        onTap: onChosen,
        excludeSemantics: true,
        child: Opacity(
          opacity: enabled ? 1 : OpacityScale.o40,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(onTap: onChosen, child: row),
          ),
        ),
      ),
    );
  }
}
