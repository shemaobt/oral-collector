import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/shared/widgets/status_dot.dart';

import '../../support/text_scale.dart';

void main() {
  final cases = <StatusDotKind, Color Function(AppColorSet)>{
    StatusDotKind.ok: (c) => c.success,
    StatusDotKind.stopped: (c) => c.error,
    StatusDotKind.now: (c) => c.accent,
  };
  for (final entry in cases.entries) {
    testWidgets('${entry.key.name} is a 9 round dot in its colour', (
      tester,
    ) async {
      await pumpAtTextScale(
        tester,
        child: Center(child: StatusDot(kind: entry.key)),
      );
      final colors = AppColors.of(tester.element(find.byType(StatusDot)));
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(StatusDot),
          matching: find.byType(DecoratedBox),
        ),
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, entry.value(colors));
      expect(tester.getSize(find.byType(StatusDot)), const Size(9, 9));
    });
  }
}
