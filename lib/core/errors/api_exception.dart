// ENG-99: the exception types now live in the sealed hierarchy in
// app_exception.dart. Only the legacy names are re-exported here so the
// existing imports keep working; new code should import app_exception.dart.
export 'app_exception.dart' show UnauthorizedException, ForbiddenException;
