import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/app_exception.dart';
import 'error_boundary.dart';

/// Decodes a 2xx JSON response body into a `Map<String, dynamic>`, raising a
/// catchable [AppException] instead of an uncatchable `TypeError`:
/// non-2xx -> [throwForResponse]; non-JSON -> `FormatException`; JSON that is
/// not an object -> [ParseException]. Collapses the repeated
/// `jsonDecode(response.body) as Map<String, dynamic>` site.
Map<String, dynamic> decodeObject(http.Response response) {
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throwForResponse(response);
  }
  final decoded = jsonDecode(response.body);
  if (decoded is Map<String, dynamic>) return decoded;
  throw ParseException(
    field: '<root>',
    expected: 'Map<String, dynamic>',
    cause: decoded,
  );
}

/// List counterpart of [decodeObject]; a non-`List` root throws [ParseException].
List<dynamic> decodeList(http.Response response) {
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throwForResponse(response);
  }
  final decoded = jsonDecode(response.body);
  if (decoded is List) return decoded;
  throw ParseException(field: '<root>', expected: 'List', cause: decoded);
}

/// The `code` of an error response's JSON envelope, or null when the body is
/// not a JSON object carrying a string `code`.
String? readErrorCode(http.Response response) {
  try {
    final decoded = jsonDecode(response.body);
    final code = decoded is Map<String, dynamic> ? decoded['code'] : null;
    return code is String ? code : null;
  } on FormatException {
    return null;
  }
}
