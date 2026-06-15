import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/web/url_query.dart';

void main() {
  group('cleanedLocationWithout', () {
    test('removes the only query param, leaving the bare path', () {
      final result = cleanedLocationWithout(
        'https://app.example.com/reset-password?token=abc123',
        'token',
      );

      expect(result, '/reset-password');
    });

    test('removes the named param but keeps the others', () {
      final result = cleanedLocationWithout(
        'https://app.example.com/reset-password?token=abc123&lang=pt',
        'token',
      );

      expect(result, '/reset-password?lang=pt');
    });

    test('returns null when the param is absent so nothing is rewritten', () {
      final result = cleanedLocationWithout(
        'https://app.example.com/reset-password?lang=pt',
        'token',
      );

      expect(result, isNull);
    });

    test('strips a present-but-empty param value', () {
      final result = cleanedLocationWithout(
        'https://app.example.com/reset-password?token=',
        'token',
      );

      expect(result, '/reset-password');
    });

    test('removes every occurrence of a repeated param', () {
      final result = cleanedLocationWithout(
        'https://app.example.com/reset-password?token=a&token=b&lang=pt',
        'token',
      );

      expect(result, '/reset-password?lang=pt');
    });

    test('preserves the URL fragment while stripping the param', () {
      final result = cleanedLocationWithout(
        'https://app.example.com/reset-password?token=abc123#form',
        'token',
      );

      expect(result, '/reset-password#form');
    });

    test('keeps a surviving param and the fragment together', () {
      final result = cleanedLocationWithout(
        'https://app.example.com/reset-password?token=abc123&lang=pt#form',
        'token',
      );

      expect(result, '/reset-password?lang=pt#form');
    });
  });
}
