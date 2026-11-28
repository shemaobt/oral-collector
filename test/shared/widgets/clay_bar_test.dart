import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/shared/widgets/clay_bar.dart';

void main() {
  testWidgets('without a width it fills the space in a Column', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(width: 200, child: Column(children: [ClayBar()])),
        ),
      ),
    );
    expect(tester.getSize(find.byType(ClayBar)), const Size(200, 14));
  });
}
