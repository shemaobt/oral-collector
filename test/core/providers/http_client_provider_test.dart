import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/io_client.dart';
import 'package:oral_collector/core/providers/http_client_provider.dart';

void main() {
  test('httpClientProvider returns IOClient on native (sentinel)', () {
    if (kIsWeb) return;

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final client = container.read(httpClientProvider);
    expect(
      client,
      isA<IOClient>(),
      reason:
          'bare http.Client() has no connectionTimeout — must wrap with IOClient '
          'so the 15 s connect timeout actually applies.',
    );
  });

  test(
    'GET against unroutable IP fails inside the 15 s connect-timeout window',
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
        inInclusiveRange(13, 18),
        reason:
            'should fire because of the 15 s connect timeout, NOT an immediate '
            'firewall RST. elapsed=${stopwatch.elapsed.inSeconds}s. If this fails '
            'at the low end (<13s), the CI network is rejecting fast and this '
            'test no longer exercises the timeout — investigate before relaxing.',
      );
    },
    tags: ['slow'],
    timeout: const Timeout(Duration(seconds: 25)),
  );
}
