/// Exception thrown when an API returns a 403 Forbidden response.
class ForbiddenException implements Exception {
  final String message;

  const ForbiddenException([this.message = 'You do not have permission to perform this action']);

  @override
  String toString() => message;
}
