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

    test('ServerException com code dinâmico não expõe o código cru', () {
      final shown = friendlyErrorFor(
        const ServerException(statusCode: 500, code: 'server_500'),
        l10n,
      );
      expect(shown, l10n.error_serverFailure);
      expect(shown, isNot(contains('server_500')));
      expect(shown, isNot(contains('ServerException')));
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

  group('friendlyErrorMessage: caracterização por ramo', () {
    final cases = <String, String>{
      'Connection refused': l10n.error_network,
      'Network is unreachable': l10n.error_network,
      'OS Error: errno = 7': l10n.error_network,
      'HandshakeException: bad certificate': l10n.error_secureConnection,
      'TLS error': l10n.error_secureConnection,
      'Request timeout': l10n.error_timeout,
      'Login failed': l10n.error_invalidCredentials,
      'Signup failed': l10n.error_signupFailed,
      'Token refresh failed': l10n.error_sessionExpired,
      'Failed to get user': l10n.error_profileLoadFailed,
      'Failed to update profile': l10n.error_profileUpdateFailed,
      'Failed to upload image': l10n.error_imageUploadFailed,
      'Not authenticated': l10n.error_notAuthenticated,
      'Session expired': l10n.error_notAuthenticated,
      'Unauthorized request': l10n.error_notAuthenticated,
      'Permission denied': l10n.error_noPermission,
      'Forbidden': l10n.error_noPermission,
      'File has no bytes': l10n.error_importNoBytes,
      'File is empty': l10n.error_importNoBytes,
      'Recording not found': l10n.error_importNoBytes,
      'ffmpeg failed': l10n.error_ffmpegProcessingFailed,
      'Concatenation failed': l10n.error_ffmpegProcessingFailed,
      'Audio processing error': l10n.error_ffmpegProcessingFailed,
      'Download failed': l10n.error_downloadFailed,
      // Quirk conhecido: erro de upload genérico reusa a mensagem de imagem.
      'Upload failed': l10n.error_imageUploadFailed,
      'Failed to list projects': l10n.error_serverFailure,
      'Server error occurred': l10n.error_serverFailure,
      'Client error': l10n.error_serverFailure,
      'failed (503)': l10n.error_serverFailure,
    };

    cases.forEach((input, expected) {
      test('"$input"', () {
        expect(friendlyErrorMessage(input, l10n), expected);
      });
    });

    test('remove o prefixo "Exception:" antes de casar', () {
      expect(
        friendlyErrorMessage('Exception: Login failed', l10n),
        l10n.error_invalidCredentials,
      );
    });

    test('texto diagnóstico com uri= -> error_generic', () {
      expect(
        friendlyErrorMessage(
          'Unexpected response uri=https://api.example.com',
          l10n,
        ),
        l10n.error_generic,
      );
    });

    test('texto longo (>120 chars) -> error_generic', () {
      expect(
        friendlyErrorMessage('detalhe '.padRight(130, 'x'), l10n),
        l10n.error_generic,
      );
    });

    test('texto curto e limpo é devolvido verbatim', () {
      expect(
        friendlyErrorMessage('Just a short note', l10n),
        'Just a short note',
      );
    });
  });

  group('friendlyErrorMessage: _humanizeDetail via JSON detail', () {
    test('detail "invalid credentials" -> error_invalidCredentials', () {
      expect(
        friendlyErrorMessage(
          'Login failed: {"detail":"Invalid credentials"}',
          l10n,
        ),
        l10n.error_invalidCredentials,
      );
    });

    test('detail "user not found" -> error_userNotFound', () {
      expect(
        friendlyErrorMessage('failed: {"detail":"user not found"}', l10n),
        l10n.error_userNotFound,
      );
    });

    test('detail "already exists" -> error_accountExists', () {
      expect(
        friendlyErrorMessage('failed: {"detail":"already exists"}', l10n),
        l10n.error_accountExists,
      );
    });

    test('message "email is required" -> error_emailRequired', () {
      expect(
        friendlyErrorMessage('failed: {"message":"email is required"}', l10n),
        l10n.error_emailRequired,
      );
    });

    test('error "password is required" -> error_passwordRequired', () {
      expect(
        friendlyErrorMessage('failed: {"error":"password is required"}', l10n),
        l10n.error_passwordRequired,
      );
    });

    test('detail curto e desconhecido é devolvido verbatim', () {
      expect(
        friendlyErrorMessage('failed: {"detail":"Try later"}', l10n),
        'Try later',
      );
    });
  });

  group(
    'reroute: friendlyErrorFor usa o tipo, não o regex sobre toString()',
    () {
      test('ServerException tipada resolve via switch, não via fallback', () {
        const e = ServerException(statusCode: 503);
        final typed = friendlyErrorFor(e, l10n);
        final viaToString = friendlyErrorMessage(e.toString(), l10n);
        expect(typed, l10n.error_serverFailure);
        expect(viaToString, l10n.error_generic);
        expect(typed, isNot(equals(viaToString)));
      });
    },
  );
}
