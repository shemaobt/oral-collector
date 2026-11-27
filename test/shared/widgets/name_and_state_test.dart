import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/shared/widgets/name_and_state.dart';

import '../../support/text_scale.dart';

const _long = 'Gravação da história do rio contada pela avó na aldeia';
const _sending = 'Enviando 42%';
final _name = find.byKey(const Key('name'));
final _state = find.byKey(const Key('state'));
const _ltr = TextDirection.ltr;
const _rtl = TextDirection.rtl;

Widget _slot(String name, [String? state]) => NameAndState(
  name: Text(name, key: const Key('name')),
  state: state == null ? null : Text(state, key: const Key('state')),
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 200,
  double scale = 1,
  TextDirection direction = _ltr,
}) => pumpAtTextScale(
  tester,
  scale: scale,
  child: Directionality(
    textDirection: direction,
    child: DefaultTextStyle(
      style: const TextStyle(fontSize: 10),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: child),
      ),
    ),
  ),
);

bool _cut(WidgetTester tester, Finder text) => tester
    .renderObject<RenderParagraph>(
      find.descendant(of: text, matching: find.byType(RichText)),
    )
    .didExceedMaxLines;

void _stateOnOneLineAtEnd(
  WidgetTester tester,
  double width,
  TextDirection direction,
) {
  expectNoOverflow(tester);
  expect(tester.getSize(_state).height, tester.getSize(_name).height);
  final state = tester.getRect(_state);
  expect(
    direction == _ltr ? state.right : state.left,
    direction == _ltr ? width : 0,
  );
}

void main() {
  for (final direction in [_ltr, _rtl]) {
    testWidgets(
      '$direction: at 360 «Enviada» shows whole and a tap on name, gap or state reaches the row',
      (tester) async {
        var taps = 0;
        await _pump(
          tester,
          GestureDetector(onTap: () => taps++, child: _slot('Rio', 'Enviada')),
          width: 360,
          direction: direction,
        );

        _stateOnOneLineAtEnd(tester, 360, direction);
        expect(_cut(tester, _name) || _cut(tester, _state), isFalse);
        final name = tester.getRect(_name);
        final state = tester.getRect(_state);
        final gap = direction == _ltr
            ? state.left - name.right
            : name.left - state.right;
        expect(gap, 16);
        final gapX = direction == _ltr ? name.right + 8 : state.right + 8;
        await tester.tapAt(Offset(gapX, name.center.dy));
        await tester.tap(_name);
        await tester.tap(_state);
        expect(taps, 3);
      },
    );
  }

  for (final (state, width, scale, direction, cut) in [
    (_sending, 200.0, 1.0, _ltr, false),
    (_sending, 200.0, 1.0, _rtl, false),
    (_sending, 200.0, 2.0, _ltr, true),
    ('Enviado', 80.0, 1.0, _ltr, true),
  ]) {
    testWidgets(
      'at $width, scale $scale, $direction ${state.length} letters: cut $cut, read whole',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await _pump(
          tester,
          _slot(_long, state),
          width: width,
          scale: scale,
          direction: direction,
        );

        _stateOnOneLineAtEnd(tester, width, direction);
        expect(_cut(tester, _state), cut);
        expect(_cut(tester, _name), isTrue);
        if (cut) expect(tester.getSize(_name).width, 48);
        expect(find.bySemanticsLabel(state), findsOneWidget);
        expect(find.bySemanticsLabel(_long), findsOneWidget);
        semantics.dispose();
      },
    );
  }

  testWidgets(
    'in an IntrinsicWidth and IntrinsicHeight a short name keeps 48 and the state shows whole',
    (tester) async {
      await _pump(
        tester,
        Align(
          child: IntrinsicWidth(
            child: IntrinsicHeight(child: _slot('Ab', _sending)),
          ),
        ),
        width: 400,
      );

      expectNoOverflow(tester);
      expect(_cut(tester, _state), isFalse);
      final row = tester.renderObject<RenderBox>(find.byType(NameAndState));
      expect(row.size.width, 48 + 16 + tester.getSize(_state).width);
      expect(row.size.height, tester.getSize(_state).height);
      expect(row.getMinIntrinsicWidth(0), 48 + 16);
    },
  );
}
