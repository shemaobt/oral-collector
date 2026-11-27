import 'dart:async' show Completer;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/auth/auth_notifier.dart';
import 'package:oral_collector/core/auth/auth_repository.dart';
import 'package:oral_collector/core/auth/providers.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/core/observability/error_reporter.dart';
import 'package:oral_collector/core/providers/secure_storage_provider.dart';
import 'package:oral_collector/features/auth/domain/entities/user.dart';
import 'package:oral_collector/features/sync/data/providers.dart';
import 'package:oral_collector/features/sync/domain/repositories/connectivity_service.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockConnectivity extends Mock implements ConnectivityService {}

class _UnreadableStorage extends FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => throw PlatformException(code: 'errSecInteractionNotAllowed');
}

class _HeldStorage extends FlutterSecureStorage {
  String? _op;
  late Future<void> Function() _then;

  Completer<void> hold(String op) {
    final gate = Completer<void>();
    _op = op;
    _then = () => gate.future;
    return gate;
  }

  void failOnce(String op) {
    _op = op;
    _then = () async => throw PlatformException(code: 'errSecIO');
  }

  Future<void> _at(String op) async {
    if (op != _op) return;
    _op = null;
    await _then();
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    final value = await super.read(key: key);
    await _at('read $key');
    return value;
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    await _at('write $key');
    return super.write(key: key, value: value);
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    await _at('delete $key');
    return super.delete(key: key);
  }
}

class _MockReporter extends Mock implements ErrorReporter {}

void main() {
  late Map<String, String> stored;
  late _MockAuthRepository repo;
  late _MockReporter reporter;
  late ProviderContainer container;
  late _MockConnectivity connectivity;

  const user = User(id: 'u1', email: 'a@b.com', isPlatformAdmin: false);

  Future<void> signIn(FlutterSecureStorage storage) async {
    connectivity = _MockConnectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(repo),
        errorReporterProvider.overrideWithValue(reporter),
        connectivityServiceProvider.overrideWithValue(connectivity),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authNotifierProvider.notifier).login('a@b.com', 'pw');
    expect(container.read(authNotifierProvider).isAuthenticated, isTrue);
  }

  setUp(() async {
    stored = {};
    FlutterSecureStorage.setMockInitialValues(stored);
    repo = _MockAuthRepository();
    reporter = _MockReporter();
    when(() => repo.login('a@b.com', 'pw')).thenAnswer(
      (_) async => (user: user, accessToken: 'a1', refreshToken: 'r1'),
    );
    when(() => repo.logout('r1')).thenAnswer((_) async {});
    await signIn(const FlutterSecureStorage());
  });

  AuthNotifier notifier() => container.read(authNotifierProvider.notifier);

  void expectSignedOutOnDevice() {
    expect(stored, isEmpty);
    expect(container.read(authNotifierProvider).isAuthenticated, isFalse);
    expect(container.read(authNotifierProvider).error, isNull);
    expect(container.read(authNotifierProvider).isLoading, isFalse);
  }

  test('asks the server to end the stored refresh token once and clears the '
      'device', () async {
    await notifier().logout();

    verify(() => repo.logout('r1')).called(1);
    expectSignedOutOnDevice();
  });

  test('is signed out while the server answer is still pending', () async {
    final answer = Completer<void>();
    when(() => repo.logout('r1')).thenAnswer((_) => answer.future);

    final done = notifier().logout();
    await untilCalled(() => repo.logout('r1'));

    expectSignedOutOnDevice();
    answer.complete();
    await done;
  });

  for (final offline in [const NetworkException(), const TimeoutException()]) {
    test('${offline.runtimeType}: signs out, does not throw and reports '
        'nothing', () async {
      when(() => repo.logout('r1')).thenThrow(offline);

      await notifier().logout();

      expectSignedOutOnDevice();
      verifyNever(() => reporter.reportError(any(), any()));
    });
  }

  test('a 500 still signs out and is reported once', () async {
    const failure = ServerException(statusCode: 500);
    when(() => repo.logout('r1')).thenThrow(failure);

    await notifier().logout();

    expectSignedOutOnDevice();
    verify(() => reporter.reportError(failure, any())).called(1);
  });

  final noToken = <String, Future<void> Function()>{
    'no refresh token stored': () async => stored.remove('refresh_token'),
    'an unreadable keychain': () => signIn(_UnreadableStorage()),
  };
  for (final MapEntry(key: name, value: arrange) in noToken.entries) {
    test('$name: signs out, asks nothing and does not throw', () async {
      await arrange();

      await notifier().logout();

      verifyNever(() => repo.logout(any()));
      expectSignedOutOnDevice();
    });
  }

  group('a response landing after «Sair» signs nobody in again:', () {
    late Completer<void> gate;
    setUp(() => gate = Completer<void>());
    Future<T> held<T>(T value) => gate.future.then((_) => value);

    Future<T> heldFailure<T>() =>
        gate.future.then((_) => throw const NetworkException());

    final inFlight = <String, Future<void> Function()>{
      'connectivity check at start-up': () {
        when(() => connectivity.isOnline).thenAnswer((_) => held(true));
        when(() => repo.getMe('a1')).thenAnswer((_) async => user);
        return notifier().refreshSessionIfOnline();
      },
      'user fetch after a refresh': () {
        when(
          () => repo.refreshToken('r1'),
        ).thenAnswer((_) async => (accessToken: 'a1', refreshToken: 'r1'));
        when(() => repo.getMe('a1')).thenAnswer((_) => held(user));
        return notifier().handleUnauthorized();
      },
      'failing profile update': () {
        when(
          () => repo.updateMe('a1', displayName: 'Ana'),
        ).thenAnswer((_) => heldFailure());
        return notifier().updateProfile(displayName: 'Ana');
      },
      'failing avatar upload': () {
        when(
          () => repo.uploadImage('a1', 'f'),
        ).thenAnswer((_) => heldFailure());
        return notifier().uploadAvatar('f').catchError((_) {});
      },
      'refresh': () {
        when(
          () => repo.refreshToken('r1'),
        ).thenAnswer((_) => held((accessToken: 'a1', refreshToken: 'r1')));
        when(() => repo.getMe('a1')).thenAnswer((_) async => user);
        return notifier().handleUnauthorized();
      },
      'getMe at start-up': () {
        when(() => repo.getMe('a1')).thenAnswer((_) => held(user));
        return notifier().refreshSessionIfOnline();
      },
      'profile update': () {
        when(
          () => repo.updateMe('a1', displayName: 'Ana'),
        ).thenAnswer((_) => held(user));
        return notifier().updateProfile(displayName: 'Ana');
      },
      'avatar upload': () {
        when(() => repo.uploadImage('a1', 'f')).thenAnswer((_) async => 'u');
        when(
          () => repo.updateMe('a1', avatarUrl: 'u'),
        ).thenAnswer((_) => held(user));
        return notifier().uploadAvatar('f');
      },
    };

    for (final MapEntry(key: name, value: start) in inFlight.entries) {
      test(name, () async {
        final pending = start();
        await pumpEventQueue();

        await notifier().logout();
        gate.complete();
        await pending;

        expectSignedOutOnDevice();
      });
    }
  });

  group('a refresh racing «Sair» signs nobody in again:', () {
    setUp(() {
      when(
        () => repo.refreshToken('r1'),
      ).thenAnswer((_) async => (accessToken: 'a2', refreshToken: 'r1'));
      when(() => repo.getMe('a2')).thenAnswer((_) async => user);
    });

    final races = <String, Future<void> Function()>{
      'a 401 right after «Sair»': () async {
        final signOut = notifier().logout();
        await notifier().handleUnauthorized();
        await signOut;
      },
      'a 401 right before «Sair»': () async {
        final refresh = notifier().handleUnauthorized();
        await notifier().logout();
        await refresh;
      },
    };
    for (final MapEntry(key: name, value: race) in races.entries) {
      test(name, () async {
        await race();

        expectSignedOutOnDevice();
      });
    }

    final lateReads = <String, (String, Future<void> Function())>{
      'a 401': ('refresh_token', () => notifier().handleUnauthorized()),
      'start-up': (
        'access_token',
        () {
          when(() => repo.getMe('a1')).thenAnswer((_) async => user);
          return notifier().refreshSessionIfOnline();
        },
      ),
      'a profile update': (
        'access_token',
        () {
          when(
            () => repo.updateMe('a1', displayName: 'Ana'),
          ).thenAnswer((_) async => user);
          return notifier().updateProfile(displayName: 'Ana');
        },
      ),
      'an avatar upload': (
        'access_token',
        () {
          when(() => repo.uploadImage('a1', 'f')).thenAnswer((_) async => 'u');
          when(
            () => repo.updateMe('a1', avatarUrl: 'u'),
          ).thenAnswer((_) async => user);
          return notifier().uploadAvatar('f');
        },
      ),
    };
    for (final MapEntry(key: name, value: (key, start)) in lateReads.entries) {
      test('$name whose $key read answers after «Sair»', () async {
        final storage = _HeldStorage();
        await signIn(storage);
        final gate = storage.hold('read $key');
        final pending = start();
        await notifier().logout();
        gate.complete();
        await pending;

        expectSignedOutOnDevice();
      });

      test('$name whose user write lands after «Sair» begins', () async {
        final storage = _HeldStorage();
        await signIn(storage);
        final gate = storage.hold('write cached_user');
        final pending = start();
        await pumpEventQueue();
        final signOut = notifier().logout();
        await pumpEventQueue();
        gate.complete();
        await Future.wait([pending, signOut]);

        expectSignedOutOnDevice();
      });
    }

    test('a refresh whose token write lands after «Sair» begins', () async {
      final storage = _HeldStorage();
      await signIn(storage);
      final gate = storage.hold('write access_token');
      final refresh = notifier().handleUnauthorized();
      await pumpEventQueue();
      final signOut = notifier().logout();
      await pumpEventQueue();
      gate.complete();
      await Future.wait([refresh, signOut]);

      expectSignedOutOnDevice();
    });

    test('a 401 begun while «Sair» clears and answered after', () async {
      final storage = _HeldStorage();
      await signIn(storage);
      final clearing = storage.hold('delete access_token');
      final answer = Completer<void>();
      when(() => repo.refreshToken('r1')).thenAnswer(
        (_) =>
            answer.future.then((_) => (accessToken: 'a2', refreshToken: 'r1')),
      );
      final signOut = notifier().logout();
      await pumpEventQueue();
      final refresh = notifier().handleUnauthorized();
      await pumpEventQueue();
      clearing.complete();
      await signOut;
      answer.complete();
      await refresh;

      expectSignedOutOnDevice();
    });

    test('a «Sair» that fails to clear signs out, asks the server, does not '
        'throw and lets the next session refresh', () async {
      final storage = _HeldStorage();
      await signIn(storage);
      storage.failOnce('delete access_token');
      await notifier().logout();

      expect(container.read(authNotifierProvider).isAuthenticated, isFalse);
      verify(() => repo.logout('r1')).called(1);
      verify(
        () => reporter.reportError(isA<PlatformException>(), any()),
      ).called(1);
      await notifier().login('a@b.com', 'pw');

      expect(await notifier().handleUnauthorized(), isTrue);
    });
  });

  group('a refresh left over from before «Sair» does not sign out the next '
      'session:', () {
    late Completer<void> gate;
    setUp(() {
      gate = Completer<void>();
      when(() => repo.refreshToken('r1')).thenAnswer(
        (_) => gate.future.then((_) => (accessToken: 'a1', refreshToken: 'r1')),
      );
      when(() => repo.getMe('a1')).thenAnswer((_) async => user);
    });

    Future<void> signOutAndBackIn() async {
      await pumpEventQueue();
      await notifier().logout();
      await notifier().login('a@b.com', 'pw');
    }

    void expectSignedIn() {
      expect(container.read(authNotifierProvider).isAuthenticated, isTrue);
      expect(stored['refresh_token'], 'r1');
    }

    final stale = <String, Future<void> Function()>{
      '401 of the old session': () => notifier().handleUnauthorized(),
      '401 at start-up': () {
        when(() => repo.getMe('a1')).thenThrow(const UnauthorizedException());
        return notifier().refreshSessionIfOnline();
      },
    };
    for (final MapEntry(key: name, value: start) in stale.entries) {
      test(name, () async {
        final pending = start();
        await signOutAndBackIn();
        when(() => repo.getMe('a1')).thenAnswer((_) async => user);

        gate.complete();
        await pending;

        expectSignedIn();
      });
    }

    test('a 401 of the new session refreshes on its own', () async {
      final old = notifier().handleUnauthorized();
      await signOutAndBackIn();

      final fresh = notifier().handleUnauthorized();
      gate.complete();
      await old;

      expect(await fresh, isTrue);
      expectSignedIn();
    });

    test('the old refresh ending does not start a second one for the new '
        'session', () async {
      final old = notifier().handleUnauthorized();
      await signOutAndBackIn();
      final freshGate = Completer<void>();
      when(() => repo.refreshToken('r1')).thenAnswer(
        (_) => freshGate.future.then(
          (_) => (accessToken: 'a1', refreshToken: 'r1'),
        ),
      );
      final fresh = notifier().handleUnauthorized();
      gate.complete();
      await old;

      final joined = notifier().handleUnauthorized();
      freshGate.complete();
      await Future.wait([fresh, joined]);

      verify(() => repo.refreshToken('r1')).called(2);
      expectSignedIn();
    });
  });
}
