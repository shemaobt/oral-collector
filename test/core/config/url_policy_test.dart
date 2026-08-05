import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/config/url_policy.dart';

void main() {
  group('isHttpsUrl', () {
    test('https é aceito', () {
      expect(isHttpsUrl('https://tripod-backend.shemaywam.com'), isTrue);
      expect(isHttpsUrl('https://storage.googleapis.com/x?sig=abc'), isTrue);
    });

    test('http em loopback ou rede privada (dev) é aceito', () {
      expect(isHttpsUrl('http://localhost'), isTrue);
      expect(isHttpsUrl('http://localhost:8080/api'), isTrue);
      expect(isHttpsUrl('http://127.0.0.1:4443/upload'), isTrue);
      expect(
        isHttpsUrl('http://10.0.2.2:8000'),
        isTrue,
      ); // host do emulador Android
      expect(
        isHttpsUrl('http://192.168.0.6:8000'),
        isTrue,
      ); // LAN dev (.env real)
      expect(isHttpsUrl('http://172.16.5.4'), isTrue);
      expect(isHttpsUrl('http://10.1.2.3'), isTrue);
    });

    test('http público (host roteável ou IP não-privado) é recusado', () {
      expect(isHttpsUrl('http://example.com'), isFalse);
      expect(isHttpsUrl('http://tripod-backend.shemaywam.com'), isFalse);
      expect(isHttpsUrl('http://8.8.8.8'), isFalse);
      expect(isHttpsUrl('http://172.32.0.1'), isFalse); // fora de 172.16/12
      expect(isHttpsUrl('http://192.169.0.1'), isFalse); // fora de 192.168/16
    });

    test('host que apenas contém "localhost" não conta como loopback', () {
      expect(isHttpsUrl('http://localhost.evil.com/x'), isFalse);
      expect(isHttpsUrl('http://notlocalhost/x'), isFalse);
    });

    test('schemes não-http são recusados', () {
      expect(isHttpsUrl('ftp://localhost/x'), isFalse);
      expect(isHttpsUrl('ws://example.com'), isFalse);
    });

    test('URL inválida ou não-parseável é recusada sem lançar', () {
      expect(isHttpsUrl(':::'), isFalse);
      expect(isHttpsUrl('not even close'), isFalse);
    });
  });

  group('assertHttpsUrl', () {
    test('não lança para URL permitida', () {
      expect(() => assertHttpsUrl('https://example.com/x'), returnsNormally);
      expect(() => assertHttpsUrl('http://localhost:8080'), returnsNormally);
    });

    test('lança ArgumentError para http não-loopback', () {
      expect(() => assertHttpsUrl('http://example.com/x'), throwsArgumentError);
    });

    test('o erro redige path/query (não vaza a assinatura)', () {
      expect(
        () => assertHttpsUrl('http://evil.com/upload?signature=SECRET'),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.invalidValue, 'invalidValue', 'http://evil.com')
              .having(
                (e) => e.toString(),
                'toString',
                isNot(contains('SECRET')),
              ),
        ),
      );
    });
  });
}
