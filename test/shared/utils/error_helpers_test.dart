import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';
import 'package:oral_collector/shared/utils/error_helpers.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('friendlyErrorFor mapeia AppException por tipo', () {
    test('NetworkException -> error_network', () {
      expect(
        friendlyErrorFor(const NetworkException(), l10n),
        l10n.error_network,
      );
    });

    test('TimeoutException -> error_timeout', () {
      expect(
        friendlyErrorFor(const TimeoutException(), l10n),
        l10n.error_timeout,
      );
    });

    test('UnauthorizedException -> error_notAuthenticated', () {
      expect(
        friendlyErrorFor(const UnauthorizedException(), l10n),
        l10n.error_notAuthenticated,
      );
    });

    test('ForbiddenException -> error_noPermission', () {
      expect(
        friendlyErrorFor(const ForbiddenException(), l10n),
        l10n.error_noPermission,
      );
    });

    test('ServerException -> error_serverFailure', () {
      expect(
        friendlyErrorFor(const ServerException(statusCode: 500), l10n),
        l10n.error_serverFailure,
      );
    });

    test('ConflictException -> error_serverFailure', () {
      expect(
        friendlyErrorFor(const ConflictException(), l10n),
        l10n.error_serverFailure,
      );
    });

    test('ValidationException -> error_generic', () {
      expect(
        friendlyErrorFor(const ValidationException(), l10n),
        l10n.error_generic,
      );
    });

    test('ParseException -> error_generic', () {
      expect(
        friendlyErrorFor(
          const ParseException(field: 'x', expected: 'String'),
          l10n,
        ),
        l10n.error_generic,
      );
    });
  });

  group('friendlyErrorFor preserva o fallback por string', () {
    test('texto de SocketException -> error_network', () {
      expect(
        friendlyErrorFor('SocketException: Failed host lookup', l10n),
        l10n.error_network,
      );
    });

    test('texto de timeout -> error_timeout', () {
      expect(friendlyErrorFor('Operation timed out', l10n), l10n.error_timeout);
    });

    test('exceção arbitrária não-AppException cai no fallback', () {
      expect(
        friendlyErrorFor(const FormatException('bad'), l10n),
        l10n.error_generic,
      );
    });
  });

  group('não-regressão: toString diagnóstico ainda mapeia via fallback', () {
    test('UnauthorizedException().toString() -> error_notAuthenticated', () {
      expect(
        friendlyErrorMessage(const UnauthorizedException().toString(), l10n),
        l10n.error_notAuthenticated,
      );
    });

    test('ForbiddenException().toString() -> error_noPermission', () {
      expect(
        friendlyErrorMessage(const ForbiddenException().toString(), l10n),
        l10n.error_noPermission,
      );
    });
  });
}
