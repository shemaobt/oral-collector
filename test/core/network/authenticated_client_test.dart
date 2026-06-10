import 'dart:async' show Completer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  group('put scheme enforcement (ENG-132)', () {
    late MockSecureStorage storage;

    setUp(() {
      storage = MockSecureStorage();
    });

    test('put recusa URL http não-loopback sem emitir requisição', () async {
      var sent = false;
      final client = MockClient((request) async {
        sent = true;
        return http.Response('', 200);
      });
      final auth = AuthenticatedClient(client: client, storage: storage);

      await expectLater(
        auth.put('http://example.com/x', headers: const {}),
        throwsArgumentError,
      );
      expect(sent, isFalse);
    });

    test('put aceita https', () async {
      final client = MockClient((request) async => http.Response('ok', 200));
      final auth = AuthenticatedClient(client: client, storage: storage);

      final res = await auth.put('https://example.com/x', headers: const {});
      expect(res.statusCode, 200);
    });

    test('put aceita http em loopback de dev', () async {
      final client = MockClient((request) async => http.Response('ok', 200));
      final auth = AuthenticatedClient(client: client, storage: storage);

      final res = await auth.put('http://localhost:8080/x', headers: const {});
      expect(res.statusCode, 200);
    });

    test('put resolve caminho relativo contra o baseUrl https', () async {
      String? seenUrl;
      final client = MockClient((request) async {
        seenUrl = request.url.toString();
        return http.Response('ok', 200);
      });
      final auth = AuthenticatedClient(client: client, storage: storage);

      final res = await auth.put('/api/oc/x', headers: const {});
      expect(res.statusCode, 200);
      expect(seenUrl, startsWith('https://'));
      expect(seenUrl, endsWith('/api/oc/x'));
    });
  });

  group('token refresh coalescing (ENG-136)', () {
    late _MockHttpClient client;
    late MockSecureStorage storage;

    setUpAll(() {
      registerFallbackValue(Uri.parse('https://example.com'));
    });

    setUp(() {
      client = _MockHttpClient();
      storage = MockSecureStorage();
      when(
        () => storage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 't');
    });

    test('401s concorrentes aguardam o refresh e TODAS fazem retry (200) — '
        'nenhuma é pulada', () async {
      var refreshed = false;
      final gate = Completer<void>();
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => refreshed
            ? http.Response('ok', 200)
            : http.Response('unauthorized', 401),
      );

      final authClient = AuthenticatedClient(
        client: client,
        storage: storage,
        refreshToken: () async {
          await gate.future;
          refreshed = true;
          return true;
        },
      );

      final inflight = [
        authClient.get('/a'),
        authClient.get('/b'),
        authClient.get('/c'),
      ];
      // Hold the refresh in-flight: with the old _isRefreshing guard, concurrent
      // requests would see "already refreshing", skip the retry, and return 401.
      await pumpEventQueue();
      gate.complete();
      final responses = await Future.wait(inflight);

      expect(responses.map((r) => r.statusCode), everyElement(200));
    });
  });
}
