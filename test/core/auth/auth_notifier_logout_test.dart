import 'dart:async' show Completer;

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

class _MockStorage extends Mock implements FlutterSecureStorage {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _RecordingReporter implements ErrorReporter {
  final List<Object> reported = [];

  @override
  void reportError(
    Object error,
    StackTrace? stackTrace, {
    Map<String, String>? tags,
    Map<String, Object?>? context,
    ErrorLevel level = ErrorLevel.error,
  }) => reported.add(error);

  @override
  void addBreadcrumb(
    String message, {
    String? category,
    ErrorLevel level = ErrorLevel.info,
    Map<String, Object?>? data,
  }) {}

  @override
  void setUser({
    String? id,
    String? username,
    String? email,
    Map<String, Object?>? data,
  }) {}

  @override
  void clearUser() {}

  @override
  void setTag(String key, String value) {}
}

void main() {
  late _MockStorage storage;
  late _MockAuthRepository repo;
  late _RecordingReporter reporter;
  late ProviderContainer container;

  const user = User(id: 'u1', email: 'a@b.com', isPlatformAdmin: false);

  setUp(() async {
    storage = _MockStorage();
    repo = _MockAuthRepository();
    reporter = _RecordingReporter();
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    when(
      () => storage.read(key: 'refresh_token'),
    ).thenAnswer((_) async => 'r1');
    when(() => repo.login('a@b.com', 'pw')).thenAnswer(
      (_) async => (user: user, accessToken: 'a1', refreshToken: 'r1'),
    );

    container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(repo),
        errorReporterProvider.overrideWithValue(reporter),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authNotifierProvider.notifier).login('a@b.com', 'pw');
    expect(container.read(authNotifierProvider).isAuthenticated, isTrue);
  });

  AuthNotifier notifier() => container.read(authNotifierProvider.notifier);
  bool signedIn() => container.read(authNotifierProvider).isAuthenticated;

  void expectSignedOutOnDevice() {
    for (final key in ['access_token', 'refresh_token', 'cached_user']) {
      verify(() => storage.delete(key: key)).called(1);
    }
    expect(signedIn(), isFalse);
  }

  test('asks the server to end the stored refresh token once and clears the '
      'device', () async {
    when(() => repo.logout('r1')).thenAnswer((_) async {});

    await notifier().logout();

    verify(() => repo.logout('r1')).called(1);
    expectSignedOutOnDevice();
  });

  test('is signed out while the server answer is still pending', () async {
    final answer = Completer<void>();
    when(() => repo.logout('r1')).thenAnswer((_) => answer.future);

    final done = notifier().logout();
    await untilCalled(() => repo.logout('r1'));

    expect(signedIn(), isFalse);
    answer.complete();
    await done;
  });

  for (final offline in [const NetworkException(), const TimeoutException()]) {
    test('${offline.runtimeType}: signs out, does not throw and reports '
        'nothing', () async {
      when(() => repo.logout('r1')).thenThrow(offline);

      await notifier().logout();

      expectSignedOutOnDevice();
      expect(reporter.reported, isEmpty);
    });
  }

  test('a 500 still signs out and is reported once', () async {
    const failure = ServerException(statusCode: 500);
    when(() => repo.logout('r1')).thenThrow(failure);

    await notifier().logout();

    expectSignedOutOnDevice();
    expect(reporter.reported, [failure]);
  });

  test('without a stored refresh token nothing is asked and the person is '
      'signed out', () async {
    when(
      () => storage.read(key: 'refresh_token'),
    ).thenAnswer((_) async => null);

    await notifier().logout();

    verifyNever(() => repo.logout(any()));
    expect(signedIn(), isFalse);
  });
}
