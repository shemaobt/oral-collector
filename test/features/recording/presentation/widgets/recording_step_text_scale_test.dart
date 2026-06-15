// ENG-171: the Quick Recording "ready" state must survive large system fonts
// (MediaQuery textScaler) without overflowing or hiding controls. Rendered on a
// REALISTIC phone viewport (via pumpAtTextScale) so overflow actually surfaces.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/input_device_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_step.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/text_scale.dart';

// Always renders the "ready" (not recording) state; build() bypasses the real
// notifier's native setup.
class _ReadyRecordingNotifier extends RecordingSessionNotifier {
  @override
  RecordingState build() => const RecordingState();
}

class _FakeInputDeviceNotifier extends InputDeviceNotifier {
  @override
  InputDeviceState build() => const InputDeviceState();

  @override
  Future<void> refresh() async {}
}

List<Override> _overrides() => [
  recordingSessionNotifierProvider.overrideWith(_ReadyRecordingNotifier.new),
  inputDeviceNotifierProvider.overrideWith(_FakeInputDeviceNotifier.new),
];

Future<void> _pumpReady(WidgetTester tester, double scale) async {
  await pumpAtTextScale(
    tester,
    scale: scale,
    overrides: _overrides(),
    child: RecordingStep(
      genreId: 'g1',
      subcategoryId: 's1',
      genreName: 'Genre',
      subcategoryName: 'Sub',
      onRecordingComplete: (_) {},
    ),
  );
  await tester.pump();
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final scale in const [1.0, 1.3, 2.0]) {
    testWidgets('ready state has no overflow at ${scale}x', (tester) async {
      await _pumpReady(tester, scale);
      expectNoOverflow(tester);
      await _unmount(tester);
    });
  }

  testWidgets('all three sensitivity chips reachable at 2.0x', (tester) async {
    await _pumpReady(tester, 2.0);
    expect(find.text('Low'), findsOneWidget);
    expect(find.text('Med'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    // Trailing chip must be scroll-reachable: ensureVisible needs a Scrollable.
    await tester.ensureVisible(find.text('High'));
    expectNoOverflow(tester);
    await _unmount(tester);
  });

  testWidgets('input source label and device name both shown at 2.0x', (
    tester,
  ) async {
    await _pumpReady(tester, 2.0);
    expect(find.text('Input'), findsOneWidget);
    expect(find.text('System default'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('timer stays present at 2.0x', (tester) async {
    await _pumpReady(tester, 2.0);
    expect(find.text('00:00:00'), findsOneWidget);
    await _unmount(tester);
  });
}
