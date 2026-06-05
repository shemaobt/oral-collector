import 'dart:async' as async;
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import '../errors/app_exception.dart';

// needs-api (ENG-81): correlation id header is not standardized yet.
const _traceHeaderKeys = ['x-request-id', 'x-trace-id', 'x-correlation-id'];

String? _traceIdFrom(Map<String, String> headers) {
  for (final key in _traceHeaderKeys) {
    final value = headers[key];
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

/// Maps an HTTP status to a domain exception and throws it.
///
/// needs-api (ENG-81): `code` is derived from the status until the backend
/// returns a stable envelope code.
Never throwForStatus(int statusCode, {String? traceId, Object? cause}) {
  switch (statusCode) {
    case 401:
      throw UnauthorizedException(traceId: traceId, cause: cause);
    case 403:
      throw ForbiddenException(traceId: traceId, cause: cause);
    case 409:
      throw ConflictException(traceId: traceId, cause: cause);
    case >= 500:
      throw ServerException(
        statusCode: statusCode,
        code: 'server_$statusCode',
        traceId: traceId,
        cause: cause,
      );
    case >= 400:
      // 404 included here on purpose: no dedicated NotFoundException in scope.
      throw ValidationException(
        code: 'client_$statusCode',
        statusCode: statusCode,
        traceId: traceId,
        cause: cause,
      );
    default:
      throw ServerException(
        statusCode: statusCode,
        code: 'unexpected_$statusCode',
        traceId: traceId,
        cause: cause,
      );
  }
}

Never throwForResponse(http.Response response) {
  throwForStatus(response.statusCode, traceId: _traceIdFrom(response.headers));
}

/// Wraps transport failures in domain exceptions, preserving the original
/// stack trace via [Error.throwWithStackTrace].
Future<T> guard<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on AppException {
    rethrow;
  } on SocketException catch (e, st) {
    Error.throwWithStackTrace(NetworkException(cause: e.runtimeType), st);
  } on async.TimeoutException catch (e, st) {
    Error.throwWithStackTrace(TimeoutException(cause: e.runtimeType), st);
  }
}
