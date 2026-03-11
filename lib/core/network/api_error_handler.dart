import 'package:http/http.dart' as http;

import '../errors/api_exception.dart';

void guardResponse(http.Response response) {
  if (response.statusCode == 401) {
    throw const UnauthorizedException();
  }
  if (response.statusCode == 403) {
    throw const ForbiddenException();
  }
}
