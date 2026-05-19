import 'dart:io' show HttpClient;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

final httpClientProvider = Provider<http.Client>((_) {
  if (kIsWeb) {
    return http.Client();
  }
  final inner = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  return IOClient(inner);
});
