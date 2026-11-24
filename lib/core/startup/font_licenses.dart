import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _fontLicenseAssets = {
  'Montserrat': 'assets/fonts/OFL-Montserrat.txt',
  'Caveat Brush': 'assets/fonts/OFL-CaveatBrush.txt',
};

void registerFontLicenses() {
  _fontLicenseAssets.forEach((family, asset) {
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks([
        family,
      ], await rootBundle.loadString(asset));
    });
  });
}
