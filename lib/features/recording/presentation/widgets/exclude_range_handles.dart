import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/format.dart';
import '../exclude_range_draft.dart';
import '../trim_edit_decision.dart';

const Key kExcludeRangeStartHandleKey = Key('exclude_range_start_handle');
const Key kExcludeRangeEndHandleKey = Key('exclude_range_end_handle');
const Key kExcludeRangeConfirmKey = Key('exclude_range_confirm');
const Key kExcludeRangeCancelKey = Key('exclude_range_cancel');

const double kExcludeRangeHandleWidth = 48.0;

class ExcludeRangeEditing {
  const ExcludeRangeEditing({
    required this.draft,
    required this.onChanged,
    required this.onConfirm,
    required this.onCancel,
  });

  final ExcludeRangeDraft draft;
  final ValueChanged<ExcludeRangeDraft> onChanged;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
}

class ExcludeRangeHandles extends StatefulWidget {
  const ExcludeRangeHandles({
    super.key,
    required this.draft,
    required this.totalDuration,
    required this.snapPoints,
    required this.zoom,
    required this.panFraction,
    required this.onChanged,
  });

  final ExcludeRangeDraft draft;
  final Duration totalDuration;
  final List<double> snapPoints;
  final double zoom;
  final double panFraction;
  final ValueChanged<ExcludeRangeDraft> onChanged;

  @override
  State<ExcludeRangeHandles> createState() => _ExcludeRangeHandlesState();
}

class _ExcludeRangeHandlesState extends State<ExcludeRangeHandles> {
  double _grabOffset = 0;

  double _xOf(double fraction, double width) =>
      (fraction - widget.panFraction) * widget.zoom * width;

  double _fractionAt(double x, double width) {
    final fraction = (widget.panFraction + (x / width) / widget.zoom).clamp(
      0.0,
      1.0,
    );
    return snapToBoundary(
      fraction,
      widget.snapPoints,
      minSplitGapFraction(widget.totalDuration),
    );
  }

  double _localX(Offset global) =>
      (context.findRenderObject()! as RenderBox).globalToLocal(global).dx;

  void _grab(Offset global, double handleX) {
    HapticFeedback.selectionClick();
    _grabOffset = _localX(global) - handleX;
  }

  void _moveStart(Offset global, double width) {
    final latest = widget.draft.end - minSplitGapFraction(widget.totalDuration);
    final at = _fractionAt(_localX(global) - _grabOffset, width);
    final start = at > latest ? (latest < 0 ? 0.0 : latest) : at;
    widget.onChanged((start: start, end: widget.draft.end));
  }

  void _moveEnd(Offset global, double width) {
    final earliest =
        widget.draft.start + minSplitGapFraction(widget.totalDuration);
    final at = _fractionAt(_localX(global) - _grabOffset, width);
    final end = at < earliest ? (earliest > 1 ? 1.0 : earliest) : at;
    widget.onChanged((start: widget.draft.start, end: end));
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final startX = _xOf(widget.draft.start, width);
        final endX = _xOf(widget.draft.end, width);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: startX,
              width: (endX - startX).clamp(0.0, double.infinity),
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: ColoredBox(color: colors.error.withValues(alpha: 0.18)),
              ),
            ),
            _Handle(
              handleKey: kExcludeRangeStartHandleKey,
              x: startX,
              fraction: widget.draft.start,
              totalDuration: widget.totalDuration,
              onGrab: (g) => _grab(g, startX),
              onMove: (g) => _moveStart(g, width),
            ),
            _Handle(
              handleKey: kExcludeRangeEndHandleKey,
              x: endX,
              fraction: widget.draft.end,
              totalDuration: widget.totalDuration,
              onGrab: (g) => _grab(g, endX),
              onMove: (g) => _moveEnd(g, width),
            ),
          ],
        );
      },
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle({
    required this.handleKey,
    required this.x,
    required this.fraction,
    required this.totalDuration,
    required this.onGrab,
    required this.onMove,
  });

  final Key handleKey;
  final double x;
  final double fraction;
  final Duration totalDuration;
  final ValueChanged<Offset> onGrab;
  final ValueChanged<Offset> onMove;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Positioned(
      left: x - kExcludeRangeHandleWidth / 2,
      width: kExcludeRangeHandleWidth,
      top: 0,
      bottom: 0,
      child: GestureDetector(
        key: handleKey,
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onHorizontalDragStart: (d) => onGrab(d.globalPosition),
        onHorizontalDragUpdate: (d) => onMove(d.globalPosition),
        child: Column(
          children: [
            Text(
              formatPositionCentis(
                Duration(
                  milliseconds: (fraction * totalDuration.inMilliseconds)
                      .round(),
                ),
              ),
              maxLines: 1,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.error,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: colors.error,
                    borderRadius: BorderRadius.circular(RadiusScale.r8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExcludeRangeActions extends StatelessWidget {
  const ExcludeRangeActions({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          key: kExcludeRangeCancelKey,
          onPressed: onCancel,
          child: Text(l10n.common_cancel),
        ),
        const SizedBox(width: SpacingScale.s8),
        FilledButton(
          key: kExcludeRangeConfirmKey,
          onPressed: onConfirm,
          child: Text(l10n.trim_excludeRangeConfirm),
        ),
      ],
    );
  }
}
