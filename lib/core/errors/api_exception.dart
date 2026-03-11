class UnauthorizedException implements Exception {
  final String message;

  const UnauthorizedException([
    this.message = 'Session expired. Please log in again.',
  ]);

  @override
  String toString() => message;
}

class ForbiddenException implements Exception {
  final String message;

  const ForbiddenException([
    this.message = 'You do not have permission to perform this action',
  ]);

  @override
  String toString() => message;
}
