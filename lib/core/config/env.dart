import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class Env {
  static const _productionUrl = 'https://tripod-backend.shemaywam.com';

  static String get backendUrl {
    final envUrl = dotenv.env['BACKEND_URL']?.trim() ?? '';
    if (envUrl.isNotEmpty) return envUrl;
    if (kIsWeb) return _productionUrl;
    return '';
  }
}
