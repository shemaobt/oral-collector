// ENG-179: the active-filter chips row must survive a large system font; chips
// ellipsize and wrap, so it should adapt.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recordings_list_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recordings_list_state.dart';
import 'package:oral_collector/features/recording/presentation/widgets/active_filter_chips.dart';

import '../../../../support/text_scale.dart';

class _FakeRecordingsListNotifier extends RecordingsListNotifier {
  @override
  RecordingsListState build() =>
      const RecordingsListState(selectedFilter: StatusFilter.needsCleaning);
}

Future<void> _pump(WidgetTester tester, double scale) async {
  await pumpAtTextScale(
    tester,
    scale: scale,
    overrides: [
      recordingsListNotifierProvider.overrideWith(
        _FakeRecordingsListNotifier.new,
      ),
    ],
    child: const Align(
      alignment: Alignment.topCenter,
      child: ActiveFilterChips(),
    ),
  );
  await tester.pump();
}

void main() {
  for (final scale in const [1.0, 1.3, 2.0]) {
    testWidgets('active filter chips have no overflow at ${scale}x', (
      tester,
    ) async {
      await _pump(tester, scale);
      expectNoOverflow(tester);
    });
  }
}
