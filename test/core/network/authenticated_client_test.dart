import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
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
}
