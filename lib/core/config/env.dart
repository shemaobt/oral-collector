import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class Env {
  static const _productionUrl = 'https://tripod-backend.shemaywam.com';

  static String get backendUrl {
    if (kReleaseMode) return _productionUrl;
    final envUrl = dotenv.env['BACKEND_URL']?.trim() ?? '';
    if (envUrl.isNotEmpty) return envUrl;
    return _productionUrl;
  }
}
