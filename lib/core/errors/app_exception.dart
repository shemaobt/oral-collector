/// Typed domain error hierarchy (ENG-99, ADR-0001).
///
/// Invariants: no user-facing strings, no raw response body. `code` is a stable
/// machine string; `cause` keeps only the originating type; the UI translates
/// by type/code. `toString()` is for logs/diagnostics only.
///
/// `sealed` requires every leaf to live in THIS library: ENG-147 adds its
/// `ParseException` leaf here and a matching case in error_helpers.dart.
///
/// `code`/`traceId` are best-effort until ENG-81 lands a standardized envelope.
library;

sealed class AppException implements Exception {
  const AppException({
    required this.code,
    this.statusCode,
    this.cause,
    this.traceId,
  });

  final String code;
  final int? statusCode;
  final Object? cause;
  final String? traceId;

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType(code: $code');
    if (statusCode != null) buffer.write(', status: $statusCode');
    if (traceId != null) buffer.write(', traceId: $traceId');
    if (cause != null) buffer.write(', cause: ${cause.runtimeType}');
    return (buffer..write(')')).toString();
  }
}

final class NetworkException extends AppException {
  const NetworkException({super.code = 'network', super.cause, super.traceId});
}

final class TimeoutException extends AppException {
  const TimeoutException({super.code = 'timeout', super.cause, super.traceId});
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.code = 'unauthorized',
    super.statusCode = 401,
    super.cause,
    super.traceId,
  });
}

final class ForbiddenException extends AppException {
  const ForbiddenException({
    super.code = 'forbidden',
    super.statusCode = 403,
    super.cause,
    super.traceId,
  });
}

final class ValidationException extends AppException {
  const ValidationException({
    this.field,
    super.code = 'validation',
    super.statusCode,
    super.cause,
    super.traceId,
  });

  final String? field;
}

final class ServerException extends AppException {
  const ServerException({
    required int super.statusCode,
    super.code = 'server',
    super.cause,
    super.traceId,
  });
}

final class ConflictException extends AppException {
  const ConflictException({
    super.code = 'conflict',
    super.statusCode = 409,
    super.cause,
    super.traceId,
  });
}
