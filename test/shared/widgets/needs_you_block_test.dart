import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/shared/widgets/needs_you_block.dart';

import '../../support/text_scale.dart';

const _longLabel =
    'Um rótulo bem longo que precisa quebrar em duas linhas ou mais no botão';

Widget _block() => NeedsYouBlock(
  title: 'Precisa de você',
  text: 'Algo precisa da sua atenção.',
  action: FilledButton(onPressed: () {}, child: const Text(_longLabel)),
);

void main() {
  testWidgets('sizes to its content inside a bounded-height parent', (
    tester,
  ) async {
    await pumpAtTextScale(
      tester,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: _block())],
      ),
    );
    final blockHeight = tester.getSize(find.byType(NeedsYouBlock)).height;
    expect(blockHeight, lessThan(kPhoneSize.height / 2));
  });

  testWidgets('button grows with a two-line label at 2.0x on 320dp', (
    tester,
  ) async {
    await pumpAtTextScale(
      tester,
      scale: 2.0,
      size: const Size(320, 640),
      child: SingleChildScrollView(child: _block()),
    );
    await tester.pump();
    expectNoOverflow(tester);
    final label = tester.getSize(find.text(_longLabel));
    final button = tester.getSize(find.byType(FilledButton));
    expect(button.height, greaterThanOrEqualTo(label.height));
    expect(button.height, greaterThan(44));
  });
}
