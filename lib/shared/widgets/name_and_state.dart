import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../core/theme/app_spacing.dart';

const double _minName = SpacingScale.s48;
const double _gap = SpacingScale.s16;

class NameAndState extends StatelessWidget {
  const NameAndState({super.key, required this.name, this.state});

  final Widget name;
  final Widget? state;

  @override
  Widget build(BuildContext context) => _Slots({
    _Slot.name: DefaultTextStyle.merge(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      child: name,
    ),
    if (state case final state?)
      _Slot.state: DefaultTextStyle.merge(
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        child: state,
      ),
  });
}

enum _Slot { name, state }

class _Slots extends SlottedMultiChildRenderObjectWidget<_Slot, RenderBox> {
  const _Slots(this.children);

  final Map<_Slot, Widget> children;

  @override
  Iterable<_Slot> get slots => _Slot.values;

  @override
  Widget? childForSlot(_Slot slot) => children[slot];

  @override
  _RenderSlots createRenderObject(BuildContext context) =>
      _RenderSlots(Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, _RenderSlots render) =>
      render.direction = Directionality.of(context);
}

class _RenderSlots extends RenderBox
    with SlottedContainerRenderObjectMixin<_Slot, RenderBox> {
  _RenderSlots(this._direction);

  TextDirection _direction;

  set direction(TextDirection value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsLayout();
  }

  RenderBox get _name => childForSlot(_Slot.name)!;
  RenderBox? get _state => childForSlot(_Slot.state);

  double _stateWidth(double width) => _state == null
      ? 0
      : math.min(
          _state!.getMaxIntrinsicWidth(double.infinity),
          math.max(0, width - _minName - _gap),
        );

  double _nameWidth(double width) =>
      _state == null ? width : math.max(0, width - _stateWidth(width) - _gap);

  @override
  double computeMinIntrinsicWidth(double height) =>
      _state == null ? _name.getMinIntrinsicWidth(height) : _minName + _gap;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.max(_name.getMaxIntrinsicWidth(height), _minName) +
      (_state == null ? 0 : _gap + _state!.getMaxIntrinsicWidth(height));

  @override
  double computeMinIntrinsicHeight(double width) =>
      computeMaxIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) => math.max(
    _name.getMaxIntrinsicHeight(_nameWidth(width)),
    _state?.getMaxIntrinsicHeight(_stateWidth(width)) ?? 0,
  );

  Size _measure(BoxConstraints c, ChildLayouter layout) {
    final width = c.hasBoundedWidth
        ? c.maxWidth
        : c.constrainWidth(getMaxIntrinsicWidth(double.infinity));
    final state = _state == null
        ? Size.zero
        : layout(_state!, BoxConstraints(maxWidth: _stateWidth(width)));
    final name = layout(
      _name,
      BoxConstraints.tightFor(width: _nameWidth(width)),
    );
    return c.constrain(Size(width, math.max(name.height, state.height)));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _measure(constraints, ChildLayoutHelper.dryLayoutChild);

  Offset _offset(RenderBox box) => (box.parentData! as BoxParentData).offset;

  @override
  void performLayout() {
    size = _measure(constraints, ChildLayoutHelper.layoutChild);
    for (final box in children) {
      final atStart = (box == _name) == (_direction == TextDirection.ltr);
      (box.parentData! as BoxParentData).offset = Offset(
        atStart ? 0 : size.width - box.size.width,
        (size.height - box.size.height) / 2,
      );
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final box in children) {
      context.paintChild(box, _offset(box) + offset);
    }
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      children.any(
        (box) => result.addWithPaintOffset(
          offset: _offset(box),
          position: position,
          hitTest: (result, position) =>
              box.hitTest(result, position: position),
        ),
      );
}
