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
      'ffmpeg failed': l10n.error_ffmpegProcessingFailed,
      'Concatenation failed': l10n.error_ffmpegProcessingFailed,
      'Audio processing error': l10n.error_ffmpegProcessingFailed,
      'Download failed': l10n.error_downloadFailed,
      // ENG-184: upload genérico é falha de transporte, não a mensagem de imagem.
      // Caminho web real ("Resumable upload failed: <result.error>"): quando
      // result.error era "Recording not found", o regex casava o ramo de
      // import-vazio antes do de upload e mostrava "This file is empty".
      'Upload failed': l10n.error_serverFailure,
      'Resumable upload failed: Recording not found': l10n.error_serverFailure,
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
      // Leaves cujo toString() diagnóstico cairia em error_generic pelo regex:
      // se friendlyErrorFor stringificasse antes de despachar, estes pegariam.
      // O esperado é uma constante literal (não messageForException), para o
      // teste não usar o próprio SUT como oráculo.
      final divergent = <(AppException, String)>[
        (const NetworkException(), l10n.error_network),
        (const ConflictException(), l10n.error_serverFailure),
        (const ServerException(statusCode: 503), l10n.error_serverFailure),
      ];

      for (final (e, expected) in divergent) {
        test('${e.runtimeType} resolve via switch, não via fallback', () {
          final typed = friendlyErrorFor(e, l10n);
          final viaToString = friendlyErrorMessage(e.toString(), l10n);
          expect(typed, expected);
          expect(viaToString, l10n.error_generic);
          expect(typed, isNot(equals(viaToString)));
        });
      }
    },
  );

  // ENG-204: caracterização dos ramos/edges ainda não fixados antes do refactor
  // que troca o if-chain por uma tabela de matchers ordenada. Fixa o status quo.
  group('friendlyErrorMessage: ramos adicionais (ENG-204)', () {
    final cases = <String, String>{
      // Rede — tokens soltos e o AND `socket`+`failed`.
      'Connection reset by peer': l10n.error_network,
      'No address associated with hostname': l10n.error_network,
      'Failed host lookup: api':
          l10n.error_network, // rede antes do balde server
      'Socket operation failed': l10n.error_network, // socket && failed
      // Conexão segura — tokens soltos.
      'SSL handshake aborted': l10n.error_secureConnection,
      'bad certificate': l10n.error_secureConnection,
      // Import.
      'File not found': l10n.error_importNoBytes,
      // Balde server — cada prefixo startsWith é um ponto de decisão distinto.
      'Failed to fetch projects': l10n.error_serverFailure,
      'Failed to load data': l10n.error_serverFailure,
      'Failed to create project': l10n.error_serverFailure,
      'Failed to recreate session': l10n.error_serverFailure,
      'Failed to update settings': l10n.error_serverFailure, // não é profile
      'Failed to delete recording': l10n.error_serverFailure,
      'Failed to remove member': l10n.error_serverFailure,
      'Failed to send invite': l10n.error_serverFailure,
      'Failed to accept invite': l10n.error_serverFailure,
      'Failed to decline invite': l10n.error_serverFailure,
      'Failed to trigger cleaning': l10n.error_serverFailure,
      'Failed to clear cache': l10n.error_serverFailure,
      'password reset failed': l10n.error_serverFailure,
      'reset password failed': l10n.error_serverFailure,
      'auth error occurred': l10n.error_serverFailure,
      'Operation failed (404)': l10n.error_serverFailure, // regex failed(NNN)
    };

    cases.forEach((input, expected) {
      test('"$input"', () {
        expect(friendlyErrorMessage(input, l10n), expected);
      });
    });

    test('`socket` sozinho (sem `failed`) NÃO casa rede -> verbatim', () {
      expect(friendlyErrorMessage('socket opened', l10n), 'socket opened');
    });

    test(
      'remove o prefixo "ClientException...:" antes de devolver verbatim',
      () {
        expect(
          friendlyErrorMessage('ClientException: Some detail here', l10n),
          'Some detail here',
        );
      },
    );
  });

  group('friendlyErrorMessage: ordem JSON x ramos planos (ENG-204)', () {
    test('JSON detail intercepta antes do ramo plano "login failed"', () {
      // detail desconhecido e curto volta verbatim; se o ramo plano "login
      // failed" rodasse antes, viria error_invalidCredentials.
      expect(
        friendlyErrorMessage('Login failed: {"detail":"Account locked"}', l10n),
        'Account locked',
      );
    });

    test('regex JSON roda sobre o texto já sem o prefixo "Exception:"', () {
      expect(
        friendlyErrorMessage(
          'Exception: Login failed: {"detail":"user not found"}',
          l10n,
        ),
        l10n.error_userNotFound,
      );
    });

    test('detail não-String: JSON cai no ramo plano "login failed"', () {
      // o regex casa e o JSON decodifica, mas detail não é String: o caminho
      // JSON não resolve e o loop segue para o ramo plano "login failed".
      expect(
        friendlyErrorMessage('Login failed: {"detail": 42}', l10n),
        l10n.error_invalidCredentials,
      );
    });
  });

  group('friendlyErrorMessage: _humanizeDetail edges (ENG-204)', () {
    test('detail "duplicate" -> error_accountExists', () {
      expect(
        friendlyErrorMessage('failed: {"detail":"duplicate key"}', l10n),
        l10n.error_accountExists,
      );
    });

    test('detail >= 100 chars -> error_generic', () {
      final longDetail = 'a' * 110;
      expect(
        friendlyErrorMessage('failed: {"detail":"$longDetail"}', l10n),
        l10n.error_generic,
      );
    });

    test('detail curto contendo "{" -> error_generic', () {
      expect(
        friendlyErrorMessage('failed: {"detail":"weird {brace}"}', l10n),
        l10n.error_generic,
      );
    });
  });
}
