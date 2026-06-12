import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/auth/auth_notifier.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/core/observability/error_reporter.dart';
import 'package:oral_collector/features/invite/data/providers.dart';
import 'package:oral_collector/features/invite/domain/repositories/invite_repository.dart';
import 'package:oral_collector/features/invite/presentation/notifiers/invite_notifier.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';
import 'package:oral_collector/shared/utils/error_helpers.dart';

class _MockInviteRepository extends Mock implements InviteRepository {}

/// Auth notifier cujo refresh sempre falha transitoriamente, para asseverar que
/// o `handleUnauthorized()` fire-and-forget engole a falha (ENG-141) em vez de
/// vazar um erro assíncrono.
class _ThrowingAuthNotifier extends AuthNotifier {
  @override
  Future<bool> handleUnauthorized() async => throw const TimeoutException();
}

/// Sink que registra os erros reportados, para asseverar que o detalhe técnico
/// é encaminhado (5xx) ou silenciado (401) sem depender de um mock.
class _RecordingReporter implements ErrorReporter {
  final List<Object> reported = [];

  @override
  void reportError(
    Object error,
    StackTrace? stackTrace, {
    Map<String, String>? tags,
    Map<String, Object?>? context,
    ErrorLevel level = ErrorLevel.error,
  }) {
    reported.add(error);
  }

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
  final l10n = AppLocalizationsEn();
  late _MockInviteRepository repo;
  late _RecordingReporter reporter;

  setUp(() {
    repo = _MockInviteRepository();
    reporter = _RecordingReporter();
  });

  ProviderContainer makeContainer({bool throwingAuth = false}) {
    final container = ProviderContainer(
      overrides: [
        inviteRepositoryProvider.overrideWithValue(repo),
        errorReporterProvider.overrideWithValue(reporter),
        if (throwingAuth)
          authNotifierProvider.overrideWith(_ThrowingAuthNotifier.new),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('acceptInvite', () {
    test('um erro de servidor produz uma mensagem amigável (não o código '
        'cru) e o detalhe técnico vai para o reporter', () async {
      when(
        () => repo.acceptInvite(any()),
      ).thenThrow(const ServerException(statusCode: 500, code: 'server_500'));
      final container = makeContainer();
      final notifier = container.read(inviteNotifierProvider.notifier);

      final ok = await notifier.acceptInvite('i-1');

      expect(ok, isFalse);
      final error = container.read(inviteNotifierProvider).error;
      expect(error, isNotNull);
      final shown = friendlyErrorFor(error!, l10n);
      expect(shown, l10n.error_serverFailure);
      expect(shown, isNot(contains('server_500')));
      expect(reporter.reported.single, isA<ServerException>());
    });

    test(
      'um 401 não vaza erro na UI e dispara o refresh fire-and-forget',
      () async {
        when(
          () => repo.acceptInvite(any()),
        ).thenThrow(const UnauthorizedException());
        final container = makeContainer(throwingAuth: true);
        final notifier = container.read(inviteNotifierProvider.notifier);

        bool? ok;
        Object? uncaught;
        await runZonedGuarded(() async {
          ok = await notifier.acceptInvite('i-1');
          await Future<void>.delayed(Duration.zero);
        }, (error, _) => uncaught = error);

        expect(ok, isFalse);
        expect(container.read(inviteNotifierProvider).error, isNull);
        expect(
          uncaught,
          isNull,
          reason: 'a falha transitória do refresh não pode escapar',
        );
        expect(
          reporter.reported,
          isEmpty,
          reason: '401 é fluxo de refresh esperado, não erro a telemetrar',
        );
      },
    );
  });

  group('declineInvite', () {
    test('um 401 não vaza erro e retorna false', () async {
      when(
        () => repo.declineInvite(any()),
      ).thenThrow(const UnauthorizedException());
      final container = makeContainer(throwingAuth: true);
      final notifier = container.read(inviteNotifierProvider.notifier);

      bool? ok;
      Object? uncaught;
      await runZonedGuarded(() async {
        ok = await notifier.declineInvite('i-1');
        await Future<void>.delayed(Duration.zero);
      }, (error, _) => uncaught = error);

      expect(ok, isFalse);
      expect(container.read(inviteNotifierProvider).error, isNull);
      expect(uncaught, isNull);
    });
  });

  group('fetchInvites', () {
    test('um 401 não vaza erro e encerra o loading', () async {
      when(
        () => repo.fetchMyInvites(),
      ).thenThrow(const UnauthorizedException());
      final container = makeContainer(throwingAuth: true);
      final notifier = container.read(inviteNotifierProvider.notifier);

      Object? uncaught;
      await runZonedGuarded(() async {
        await notifier.fetchInvites();
        await Future<void>.delayed(Duration.zero);
      }, (error, _) => uncaught = error);

      final state = container.read(inviteNotifierProvider);
      expect(state.error, isNull);
      expect(state.isLoading, isFalse);
      expect(uncaught, isNull);
      expect(reporter.reported, isEmpty);
    });
  });
}
