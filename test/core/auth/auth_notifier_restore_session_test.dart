import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/auth/auth_notifier.dart';
import 'package:oral_collector/core/providers/secure_storage_provider.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockStorage storage;

  setUp(() {
    storage = _MockStorage();
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [secureStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test(
    'restoreSession restores the cached user from local storage so the router '
    'starts authenticated (no login flash)',
    () async {
      when(
        () => storage.read(key: 'access_token'),
      ).thenAnswer((_) async => 'tok');
      when(
        () => storage.read(key: 'cached_user'),
      ).thenAnswer((_) async => jsonEncode({'id': 'u1', 'email': 'a@b.com'}));

      final container = makeContainer();
      final notifier = container.read(authNotifierProvider.notifier);

      await notifier.restoreSession();

      expect(container.read(authNotifierProvider).isAuthenticated, isTrue);
    },
  );

  test(
    'restoreSession stays unauthenticated when no token is stored',
    () async {
      when(
        () => storage.read(key: 'access_token'),
      ).thenAnswer((_) async => null);

      final container = makeContainer();
      final notifier = container.read(authNotifierProvider.notifier);

      await notifier.restoreSession();

      expect(container.read(authNotifierProvider).isAuthenticated, isFalse);
    },
  );
}
