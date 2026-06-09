import 'dart:async' show Completer;
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/auth/auth_notifier.dart';
import 'package:oral_collector/core/auth/auth_repository.dart';
import 'package:oral_collector/core/auth/providers.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
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

  setUp(() {
    storage = _MockStorage();
    connectivity = _MockConnectivity();
    repo = _MockAuthRepository();
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
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

  // Estabelece uma sessão autenticada via login, para que deslogar/preservar
  // seja observável no estado (currentUser != null antes da ação sob teste).
  Future<AuthNotifier> signIn(ProviderContainer container) async {
    when(() => repo.login('a@b.com', 'pw')).thenAnswer(
      (_) async => (user: user, accessToken: 'a0', refreshToken: 'r0'),
    );
    final notifier = container.read(authNotifierProvider.notifier);
    await notifier.login('a@b.com', 'pw');
    return notifier;
  }

  group('handleUnauthorized', () {
    test('refresh bem-sucedido retorna true, renova o usuário e mantém a '
        'sessão', () async {
      when(
        () => storage.read(key: 'refresh_token'),
      ).thenAnswer((_) async => 'r0');
      when(
        () => repo.refreshToken('r0'),
      ).thenAnswer((_) async => (accessToken: 'a1', refreshToken: 'r1'));
      when(() => repo.getMe('a1')).thenAnswer((_) async => user);

      final container = makeContainer();
      final notifier = container.read(authNotifierProvider.notifier);

      final result = await notifier.handleUnauthorized();

      expect(result, isTrue);
      expect(container.read(authNotifierProvider).currentUser?.id, 'u1');
      verify(() => storage.write(key: 'access_token', value: 'a1')).called(1);
      verify(() => storage.write(key: 'refresh_token', value: 'r1')).called(1);
      verifyNever(() => storage.delete(key: any(named: 'key')));
    });

    test('refresh rejeitado com 401 retorna false e desloga', () async {
      when(
        () => storage.read(key: 'refresh_token'),
      ).thenAnswer((_) async => 'r0');
      when(
        () => repo.refreshToken('r0'),
      ).thenThrow(const UnauthorizedException());

      final container = makeContainer();
      final notifier = await signIn(container);
      expect(container.read(authNotifierProvider).isAuthenticated, isTrue);

      final result = await notifier.handleUnauthorized();

      expect(result, isFalse);
      expect(
        container.read(authNotifierProvider).isAuthenticated,
        isFalse,
        reason: 'refresh 401 deve deslogar',
      );
      verify(() => storage.delete(key: 'refresh_token')).called(1);
    });

    // Regressão ENG-141: refresh com falha transitória (não-401) não pode fingir
    // sucesso — deve propagar o erro e preservar a sessão. Com o bug
    // (`on Exception { return true }`) este teste falha: handleUnauthorized
    // completa com `true` em vez de lançar.
    test('falha transitória (timeout) propaga a exceção e preserva a '
        'sessão', () async {
      when(
        () => storage.read(key: 'refresh_token'),
      ).thenAnswer((_) async => 'r0');
      when(() => repo.refreshToken('r0')).thenThrow(const TimeoutException());

      final container = makeContainer();
      final notifier = await signIn(container);
      expect(container.read(authNotifierProvider).isAuthenticated, isTrue);

      await expectLater(
        notifier.handleUnauthorized(),
        throwsA(isA<TimeoutException>()),
      );

      expect(
        container.read(authNotifierProvider).currentUser?.id,
        'u1',
        reason: 'falha transitória não pode limpar a sessão',
      );
      verifyNever(() => storage.delete(key: any(named: 'key')));
    });

    test('sem refresh token retorna false e não autentica', () async {
      when(
        () => storage.read(key: 'refresh_token'),
      ).thenAnswer((_) async => null);

      final container = makeContainer();
      final notifier = container.read(authNotifierProvider.notifier);

      final result = await notifier.handleUnauthorized();

      expect(result, isFalse);
      expect(container.read(authNotifierProvider).isAuthenticated, isFalse);
    });
  });

  group('tryAutoLogin', () {
    test('access token expirado com refresh OK autentica com o usuário '
        'renovado', () async {
      when(
        () => storage.read(key: 'access_token'),
      ).thenAnswer((_) async => 'a0');
      when(
        () => storage.read(key: 'cached_user'),
      ).thenAnswer((_) async => null);
      when(
        () => storage.read(key: 'refresh_token'),
      ).thenAnswer((_) async => 'r0');
      when(() => repo.getMe('a0')).thenThrow(const UnauthorizedException());
      when(
        () => repo.refreshToken('r0'),
      ).thenAnswer((_) async => (accessToken: 'a1', refreshToken: 'r1'));
      when(() => repo.getMe('a1')).thenAnswer((_) async => user);

      final container = makeContainer();

      await container.read(authNotifierProvider.notifier).tryAutoLogin();

      final state = container.read(authNotifierProvider);
      expect(state.currentUser?.id, 'u1');
      expect(state.isLoading, isFalse);
    });

    test('access token e refresh ambos rejeitados desloga e limpa os '
        'tokens', () async {
      when(
        () => storage.read(key: 'access_token'),
      ).thenAnswer((_) async => 'a0');
      when(
        () => storage.read(key: 'cached_user'),
      ).thenAnswer((_) async => null);
      when(
        () => storage.read(key: 'refresh_token'),
      ).thenAnswer((_) async => 'r0');
      when(() => repo.getMe('a0')).thenThrow(const UnauthorizedException());
      when(
        () => repo.refreshToken('r0'),
      ).thenThrow(const UnauthorizedException());

      final container = makeContainer();

      await container.read(authNotifierProvider.notifier).tryAutoLogin();

      final state = container.read(authNotifierProvider);
      expect(state.isAuthenticated, isFalse);
      verify(() => storage.delete(key: 'access_token')).called(1);
    });

    // Documenta o contrato de boot offline: a sessão em cache sobrevive a um
    // refresh transiente. Não é a rede de segurança da regressão (essa é o teste
    // de propagação em handleUnauthorized); aqui o sinal forte é o verifyNever.
    test('refresh transitório no boot preserva a sessão em cache e não '
        'desloga', () async {
      when(
        () => storage.read(key: 'access_token'),
      ).thenAnswer((_) async => 'a0');
      when(
        () => storage.read(key: 'cached_user'),
      ).thenAnswer((_) async => jsonEncode(user.toJson()));
      when(
        () => storage.read(key: 'refresh_token'),
      ).thenAnswer((_) async => 'r0');
      when(() => repo.getMe('a0')).thenThrow(const UnauthorizedException());
      when(() => repo.refreshToken('r0')).thenThrow(const NetworkException());

      final container = makeContainer();

      await expectLater(
        container.read(authNotifierProvider.notifier).tryAutoLogin(),
        completes,
      );

      final state = container.read(authNotifierProvider);
      expect(
        state.currentUser?.id,
        'u1',
        reason: 'sessão em cache preservada no boot offline',
      );
      expect(state.isLoading, isFalse);
      verifyNever(() => storage.delete(key: any(named: 'key')));
    });
  });

  group('coalescing (ENG-136)', () {
    // Gate repo.refreshToken on a Completer to hold ONE refresh in-flight while
    // we fire concurrent calls — without it the "concurrent" calls serialize
    // and the test passes vacuously.
    test('N handleUnauthorized concorrentes coalescem num único refresh — '
        'impede a corrida de rotação que deslogaria', () async {
      when(
        () => storage.read(key: 'refresh_token'),
      ).thenAnswer((_) async => 'r0');
      final gate = Completer<void>();
      when(() => repo.refreshToken('r0')).thenAnswer((_) async {
        await gate.future;
        return (accessToken: 'a1', refreshToken: 'r1');
      });
      when(() => repo.getMe('a1')).thenAnswer((_) async => user);

      final container = makeContainer();
      final notifier = await signIn(container);

      final inflight = [
        for (var i = 0; i < 5; i++) notifier.handleUnauthorized(),
      ];
      await pumpEventQueue();

      // While in-flight, only ONE call reaches the refresh endpoint.
      verify(() => repo.refreshToken('r0')).called(1);

      gate.complete();
      final results = await Future.wait(inflight);

      expect(results, everyElement(isTrue));
      expect(
        container.read(authNotifierProvider).currentUser?.id,
        'u1',
        reason: 'sessão sobrevive: um único refresh, sem rotação concorrente',
      );
      verifyNever(() => storage.delete(key: any(named: 'key')));
    });

    test('o slot em voo reseta ao completar — uma nova onda concorrente '
        'dispara um novo refresh', () async {
      when(
        () => storage.read(key: 'refresh_token'),
      ).thenAnswer((_) async => 'r0');
      when(
        () => repo.refreshToken('r0'),
      ).thenAnswer((_) async => (accessToken: 'a1', refreshToken: 'r1'));
      when(() => repo.getMe('a1')).thenAnswer((_) async => user);

      final container = makeContainer();
      final notifier = container.read(authNotifierProvider.notifier);

      // Wave 1, concurrent → a single refresh.
      await Future.wait([
        for (var i = 0; i < 3; i++) notifier.handleUnauthorized(),
      ]);
      verify(() => repo.refreshToken('r0')).called(1);

      // Wave 2, concurrent, after wave 1 completes: if the slot weren't
      // cleared this would return the already-completed Future and refreshToken
      // would NOT be called again (called(0) → fail).
      await Future.wait([
        for (var i = 0; i < 3; i++) notifier.handleUnauthorized(),
      ]);
      verify(() => repo.refreshToken('r0')).called(1);
    });

    test('falha transitória concorrente propaga o mesmo erro a todos e '
        'preserva a sessão', () async {
      when(
        () => storage.read(key: 'refresh_token'),
      ).thenAnswer((_) async => 'r0');
      final gate = Completer<void>();
      when(() => repo.refreshToken('r0')).thenAnswer((_) async {
        await gate.future;
        throw const TimeoutException();
      });

      final container = makeContainer();
      final notifier = await signIn(container);

      final inflight = [
        for (var i = 0; i < 4; i++) notifier.handleUnauthorized(),
      ];
      // Attach error handlers BEFORE releasing the gate, or the rejections
      // become unhandled async errors and break the test.
      final outcomes = [
        for (final f in inflight)
          f.then<Object?>((_) => null, onError: (e) => e),
      ];
      await pumpEventQueue();

      verify(() => repo.refreshToken('r0')).called(1);

      gate.complete();
      final errors = await Future.wait(outcomes);

      expect(errors, everyElement(isA<TimeoutException>()));
      expect(
        container.read(authNotifierProvider).currentUser?.id,
        'u1',
        reason: 'transitório preserva a sessão (ENG-141)',
      );
      verifyNever(() => storage.delete(key: any(named: 'key')));
    });

    test('tryAutoLogin e handleUnauthorized concorrentes compartilham um '
        'único refresh (fixa o seam em _tryRefresh)', () async {
      when(
        () => storage.read(key: 'access_token'),
      ).thenAnswer((_) async => 'a0');
      when(
        () => storage.read(key: 'cached_user'),
      ).thenAnswer((_) async => null);
      when(
        () => storage.read(key: 'refresh_token'),
      ).thenAnswer((_) async => 'r0');
      when(() => repo.getMe('a0')).thenThrow(const UnauthorizedException());
      final gate = Completer<void>();
      when(() => repo.refreshToken('r0')).thenAnswer((_) async {
        await gate.future;
        return (accessToken: 'a1', refreshToken: 'r1');
      });
      when(() => repo.getMe('a1')).thenAnswer((_) async => user);

      final container = makeContainer();
      final notifier = container.read(authNotifierProvider.notifier);

      final auto = notifier.tryAutoLogin();
      final manual = notifier.handleUnauthorized();
      await pumpEventQueue();

      verify(() => repo.refreshToken('r0')).called(1);

      gate.complete();
      await auto;
      final refreshed = await manual;

      // Both paths observed the single refresh succeed.
      expect(refreshed, isTrue);
      final state = container.read(authNotifierProvider);
      expect(state.currentUser?.id, 'u1');
      expect(state.isLoading, isFalse);
    });
  });
}
