import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/core/theme/color_hex.dart';

void main() {
  group('parseHexColor', () {
    test('parses a #RRGGBB string into an opaque color', () {
      expect(parseHexColor('#3D8E80').toARGB32(), 0xFF3D8E80);
      expect(parseHexColor('#FF8000').toARGB32(), 0xFFFF8000);
    });

    test('is case-insensitive on the hex digits', () {
      expect(parseHexColor('#ff8000').toARGB32(), 0xFFFF8000);
    });

    test('returns the default fallback (AppColors.primary) for null', () {
      expect(parseHexColor(null).toARGB32(), AppColors.primary.toARGB32());
    });

    test('returns the fallback for a too-short string', () {
      expect(parseHexColor('#abc').toARGB32(), AppColors.primary.toARGB32());
    });

    test('returns the fallback for a malformed hex string', () {
      expect(parseHexColor('#ZZZZZZ').toARGB32(), AppColors.primary.toARGB32());
    });

    test('honors a custom fallback', () {
      const fallback = Color(0xFF010203);
      expect(parseHexColor(null, fallback).toARGB32(), 0xFF010203);
    });
  });
}
