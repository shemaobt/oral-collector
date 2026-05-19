@Tags(['slow'])
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/providers/http_client_provider.dart';

void main() {
  test(
    'GET against unroutable IP fails within 18 s (proves connect timeout is set)',
    () async {
      if (kIsWeb) return;

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final client = container.read(httpClientProvider);
      // 192.0.2.1 is in TEST-NET-1 (RFC 5737) — reserved, never routable.
      // The OS will keep retrying the SYN until our connectionTimeout fires.
      final uri = Uri.parse('http://192.0.2.1:81/');

      final stopwatch = Stopwatch()..start();
      var threw = false;
      try {
        await client.get(uri);
      } on Exception {
        threw = true;
      } finally {
        stopwatch.stop();
      }

      expect(threw, isTrue, reason: 'request should error, not succeed');
      expect(
        stopwatch.elapsed.inSeconds,
        lessThan(18),
        reason:
            'connect timeout should fire well below the OS default (~30 s); '
            'elapsed=${stopwatch.elapsed.inSeconds}s',
      );
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );
}
