/// The splash must not rewrite the browser's address bar.
///
/// On web the splash is on screen while the session restores, before the router
/// exists. Anything it reports over the navigation channel lands in the address
/// bar, and the router later reads the address bar as the page to open. A splash
/// that reports `/` turns every opened link — the password-reset link from the
/// email first of all — into `/`, and the redirect then sends a logged-out user
/// to the login screen instead of the page the link names.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/startup/app_startup.dart';

void main() {
  testWidgets('the splash reports nothing to the address bar', (tester) async {
    final reported = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.navigation,
      (call) async {
        reported.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.navigation,
        null,
      ),
    );

    await tester.pumpWidget(const StartupSplash());

    expect(reported, isEmpty);
  });
}
