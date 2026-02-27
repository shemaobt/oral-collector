import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class Env {
  static String get backendUrl =>
      dotenv.env['BACKEND_URL']?.trim() ?? '';
}
