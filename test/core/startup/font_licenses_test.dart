import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/startup/font_licenses.dart';

Future<Map<String, String>> _registeredByPackage() async {
  final byPackage = <String, String>{};
  await for (final entry in LicenseRegistry.licenses) {
    final text = entry.paragraphs.map((p) => p.text).join('\n');
    for (final package in entry.packages) {
      byPackage[package] = text;
    }
  }
  return byPackage;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registers the OFL text of Montserrat and Caveat Brush', () async {
    registerFontLicenses();

    final byPackage = await _registeredByPackage();

    for (final family in ['Montserrat', 'Caveat Brush']) {
      expect(byPackage[family], contains('SIL OPEN FONT LICENSE Version 1.1'));
    }
  });
}
