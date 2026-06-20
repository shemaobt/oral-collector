// ENG-179: the input-device picker sheet must survive a large system font,
// including the mic-permission prompt button.
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/input_device_notifier.dart';
import 'package:oral_collector/features/recording/presentation/widgets/input_device_picker_sheet.dart';

import '../../../../support/text_scale.dart';

class _PermissionPromptNotifier extends InputDeviceNotifier {
  @override
  InputDeviceState build() =>
      const InputDeviceState(permissionNotYetGranted: true);

  @override
  Future<void> refresh() async {}
}

Future<void> _pump(WidgetTester tester, double scale) async {
  await pumpAtTextScale(
    tester,
    scale: scale,
    overrides: [
      inputDeviceNotifierProvider.overrideWith(_PermissionPromptNotifier.new),
    ],
    child: const InputDevicePickerSheet(),
  );
  await tester.pump();
}

void main() {
  for (final scale in const [1.0, 1.3, 2.0]) {
    testWidgets('device picker sheet has no overflow at ${scale}x', (
      tester,
    ) async {
      await _pump(tester, scale);
      expectNoOverflow(tester);
    });
  }
}
