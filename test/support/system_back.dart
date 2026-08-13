/// Test-side stand-ins for the two things only the platform can do: press the
/// device's back button, and leave the app.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simulates a system back, like the Android back button or back gesture.
///
/// Sends the same platform channel message the engine sends when it receives a
/// system back. Copied from the Flutter SDK's own
/// `packages/flutter/test/widgets/navigator_utils.dart`, which is what the
/// framework's navigator tests use; it is not exported by `flutter_test`.
///
/// Tapping the AppBar's arrow is NOT a substitute: the arrow calls
/// `Navigator.maybePop` directly, while a system back travels the channel and
/// can end at `SystemNavigator.pop` — leaving the app — when nothing claims it.
Future<void> simulateSystemBack() {
  return TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        'flutter/navigation',
        const JSONMessageCodec().encodeMessage(<String, dynamic>{
          'method': 'popRoute',
        }),
        (ByteData? _) {},
      );
}

/// Simulates a completed predictive back gesture, the way Android sends one.
///
/// This is the path a device takes, not [simulateSystemBack]: predictive back
/// is on by default for apps targeting Android 15+ and this app targets 36, so
/// the engine drives the gesture channel and only falls back to `popRoute` when
/// the framework declines the gesture.
Future<void> simulatePredictiveBack() async {
  await _backGesture('startBackGesture', <String, Object?>{
    'touchOffset': <Object?>[0.0, 100.0],
    'progress': 0.0,
    'swipeEdge': 0,
  });
  await _backGesture('commitBackGesture');
}

Future<void> _backGesture(String method, [Object? arguments]) {
  return TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        'flutter/backgesture',
        const StandardMethodCodec().encodeMethodCall(
          MethodCall(method, arguments),
        ),
        (ByteData? _) {},
      );
}

/// Records what the app asks the platform to do, so a test can tell whether the
/// app left. Returns the list of method names, in call order.
///
/// `SystemNavigator.pop` on this channel is how a Flutter app closes itself on
/// Android; in a widget test nothing is listening, so without a recorder the
/// app "exiting" is invisible and every back looks harmless.
List<String> recordPlatformCalls(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      calls.add(call.method);
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}
