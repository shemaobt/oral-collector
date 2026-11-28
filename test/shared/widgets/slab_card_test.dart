import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_theme.dart';
import 'package:oral_collector/shared/widgets/slab_card.dart';

void main() {
  testWidgets('words start at the same place whatever the count', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: SlabCard(
            title: 'Hoje',
            rows: [
              SlabRow(count: 2, label: 'one', action: 'Ver'),
              SlabRow(count: 12, label: 'two', action: 'Ver'),
            ],
          ),
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.text('two')).dx,
      tester.getTopLeft(find.text('one')).dx,
    );
  });
}
