import 'dart:async' show Completer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';

class _MockHttpClient extends Mock implements http.Client {}

class _MockStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockHttpClient client;
  late _MockStorage storage;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    client = _MockHttpClient();
    storage = _MockStorage();
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
}
