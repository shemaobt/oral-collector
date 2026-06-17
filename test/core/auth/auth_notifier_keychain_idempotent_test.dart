import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/auth/auth_notifier.dart';
import 'package:oral_collector/core/auth/auth_repository.dart';
import 'package:oral_collector/core/auth/providers.dart';
import 'package:oral_collector/core/providers/secure_storage_provider.dart';
import 'package:oral_collector/features/auth/domain/entities/user.dart';
import 'package:oral_collector/features/sync/data/providers.dart';
import 'package:oral_collector/features/sync/domain/repositories/connectivity_service.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

class _MockConnectivity extends Mock implements ConnectivityService {}

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockStorage storage;
  late _MockConnectivity connectivity;
  late _MockAuthRepository repo;

  const user = User(id: 'u1', email: 'a@b.com', isPlatformAdmin: false);

  // Backend de secure-storage que emite errSecDuplicateItem (-25299) ao gravar
  // numa key já existente — o modo de falha observado no iOS (ENG-188). O fix
  // precisa tolerá-lo regravando.
  setUp(() {
    storage = _MockStorage();
    connectivity = _MockConnectivity();
    repo = _MockAuthRepository();

    final store = <String, String>{};
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((inv) async {
      final key = inv.namedArguments[#key] as String;
      if (store.containsKey(key)) {
        throw PlatformException(
          code: 'Unexpected security result code',
          message:
              'Code: -25299, Message: '
              'The specified item already exists in the keychain.',
          details: -25299,
        );
      }
      store[key] = inv.namedArguments[#value] as String;
    });
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer(
      (inv) async => store.remove(inv.namedArguments[#key] as String),
    );
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((inv) async => store[inv.namedArguments[#key] as String]);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(repo),
        connectivityServiceProvider.overrideWithValue(connectivity),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    're-login rotaciona os tokens no Keychain sem errSecDuplicateItem',
    () async {
      // O 2º login devolve tokens rotacionados: o fix precisa SUBSTITUIR os
      // valores no Keychain, não apenas engolir o duplicado.
      var logins = 0;
      when(() => repo.login('a@b.com', 'pw')).thenAnswer((_) async {
        logins++;
        return logins == 1
            ? (user: user, accessToken: 'a0', refreshToken: 'r0')
            : (user: user, accessToken: 'a1', refreshToken: 'r1');
      });
      final container = makeContainer();
      final notifier = container.read(authNotifierProvider.notifier);

      // 1ª sessão grava access_token, refresh_token e cached_user.
      await notifier.login('a@b.com', 'pw');
      // 2ª: as keys já existem no Keychain — o bug colide no write.
      await notifier.login('a@b.com', 'pw');

      final state = container.read(authNotifierProvider);
      expect(
        state.error,
        isNull,
        reason: 're-login não pode falhar por item duplicado no Keychain',
      );
      expect(state.currentUser?.id, 'u1');
      expect(
        await storage.read(key: 'access_token'),
        'a1',
        reason:
            'o token rotacionado deve substituir o anterior, '
            'não ser descartado',
      );
      expect(await storage.read(key: 'refresh_token'), 'r1');
      expect(
        await storage.read(key: 'cached_user'),
        isNotNull,
        reason:
            'o usuário em cache deve sobreviver ao re-login, não ser dropado',
      );
    },
  );

  test(
    'PlatformException não-duplicada na escrita propaga como erro (não engole)',
    () async {
      when(() => repo.login('a@b.com', 'pw')).thenAnswer(
        (_) async => (user: user, accessToken: 'a0', refreshToken: 'r0'),
      );
      // Falha de Keychain não relacionada ao duplicado: o helper deve relançar,
      // não mascarar como sucesso.
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenThrow(
        PlatformException(
          code: 'Unexpected security result code',
          message: 'Code: -34018, Message: missing entitlement.',
          details: -34018,
        ),
      );
      final container = makeContainer();

      await container
          .read(authNotifierProvider.notifier)
          .login('a@b.com', 'pw');

      final state = container.read(authNotifierProvider);
      expect(state.error, isA<PlatformException>());
      expect(state.currentUser, isNull);
    },
  );
}
