import 'package:http/http.dart' as http;

import 'error_boundary.dart';

/// Throws UnauthorizedException on 401 and ForbiddenException on 403.
/// Other statuses pass through (callers handle them).
void guardResponse(http.Response response) {
  final status = response.statusCode;
  if (status == 401 || status == 403) {
    throwForResponse(response);
  }
}
