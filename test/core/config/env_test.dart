import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/config/env.dart';

// Mirrors the compile-time override so each test can self-skip depending on
// whether `flutter test` was invoked with `--dart-define=BACKEND_URL=...`.
const _override = String.fromEnvironment('BACKEND_URL');

void main() {
  test(
    'backendUrl defaults to the production backend when no override is set',
    () {
      expect(Env.backendUrl, 'https://tripod-backend.shemaywam.com');
    },
    skip: _override.isEmpty ? false : 'override set via --dart-define',
  );

  test(
    'backendUrl uses the BACKEND_URL override when one is provided',
    () {
      expect(Env.backendUrl, _override);
    },
    skip: _override.isEmpty
        ? 'run with --dart-define=BACKEND_URL=https://example.test'
        : false,
  );
}
