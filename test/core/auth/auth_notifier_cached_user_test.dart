import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/auth/auth_notifier.dart';
import 'package:oral_collector/core/providers/secure_storage_provider.dart';
import 'package:oral_collector/features/sync/data/providers.dart';
import 'package:oral_collector/features/sync/domain/repositories/connectivity_service.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

class _MockConnectivity extends Mock implements ConnectivityService {}

void main() {
  late _MockStorage storage;
  late _MockConnectivity connectivity;

  setUp(() {
    storage = _MockStorage();
    connectivity = _MockConnectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => false);
  });

  test('tryAutoLogin degrades to unauthenticated (no crash) when the cached '
      'user is corrupt', () async {
    // A valid token is stored, but the cached user has a wrong-typed `id`, so
    // User.fromJson throws a TypeError (an Error). Reading the cache must not
    // crash auto-login.
    when(
      () => storage.read(key: 'access_token'),
    ).thenAnswer((_) async => 'tok');
    when(
      () => storage.read(key: 'cached_user'),
    ).thenAnswer((_) async => '{"id": 123, "email": "a@b.com"}');

    final container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        connectivityServiceProvider.overrideWithValue(connectivity),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(authNotifierProvider.notifier);

    await expectLater(notifier.tryAutoLogin(), completes);
    expect(container.read(authNotifierProvider).currentUser, isNull);
  });
}
