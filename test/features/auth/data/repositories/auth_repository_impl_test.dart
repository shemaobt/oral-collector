import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/features/auth/data/repositories/auth_repository_impl.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  late _MockHttpClient client;
  late AuthRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    client = _MockHttpClient();
    repo = AuthRepositoryImpl(client: client);
  });

  void stubPost(Object body, int status) {
    when(
      () => client.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => http.Response(jsonEncode(body), status));
  }

  const user = {'id': 'u-1', 'email': 'a@b.com'};
  const tokens = {'access_token': 'at', 'refresh_token': 'rt'};

  group('login', () {
    test('throws a catchable ParseException when the access token is the '
        'wrong type', () async {
      stubPost({
        'user': user,
        'tokens': {'access_token': 123, 'refresh_token': 'rt'},
      }, 200);

      await expectLater(
        repo.login('a@b.com', 'pw'),
        throwsA(
          isA<ParseException>().having((e) => e.field, 'field', 'access_token'),
        ),
      );
    });

    test('throws a catchable ParseException when the tokens object is '
        'missing', () async {
      stubPost({'user': user}, 200);

      await expectLater(
        repo.login('a@b.com', 'pw'),
        throwsA(
          isA<ParseException>().having((e) => e.field, 'field', 'tokens'),
        ),
      );
    });

    test('returns the user and tokens on success', () async {
      stubPost({'user': user, 'tokens': tokens}, 200);

      final result = await repo.login('a@b.com', 'pw');

      expect(result.accessToken, 'at');
      expect(result.refreshToken, 'rt');
      expect(result.user.id, 'u-1');
    });
  });

  group('signup', () {
    test('throws a catchable ParseException when the tokens object is '
        'missing', () async {
      stubPost({'user': user}, 201);

      await expectLater(
        repo.signup('a@b.com', 'pw', null),
        throwsA(
          isA<ParseException>().having((e) => e.field, 'field', 'tokens'),
        ),
      );
    });

    test('returns the user and tokens on success', () async {
      stubPost({'user': user, 'tokens': tokens}, 201);

      final result = await repo.signup('a@b.com', 'pw', null);

      expect(result.accessToken, 'at');
      expect(result.refreshToken, 'rt');
    });
  });
}
