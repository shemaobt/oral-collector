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

class _MockReporter extends Mock implements ErrorReporter {}

void main() {
  late Map<String, String> stored;
  late _MockAuthRepository repo;
  late _MockReporter reporter;
  late ProviderContainer container;

  const user = User(id: 'u1', email: 'a@b.com', isPlatformAdmin: false);

  Future<void> signIn(FlutterSecureStorage storage) async {
    final connectivity = _MockConnectivity();
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
}
