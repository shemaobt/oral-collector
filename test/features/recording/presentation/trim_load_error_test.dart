import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/features/recording/presentation/trim_load_error.dart';

void main() {
  group('isRecordingNotFound (ENG-140 F21)', () {
    // The API error boundary maps every 4xx (404 included) to a
    // ValidationException carrying the status, so a real "recording missing"
    // 404 arrives as ValidationException(statusCode: 404).
    test('a 404 is a genuine not-found', () {
      expect(
        isRecordingNotFound(const ValidationException(statusCode: 404)),
        isTrue,
      );
    });

    test('a non-404 client error of the same type is NOT a not-found', () {
      expect(
        isRecordingNotFound(const ValidationException(statusCode: 422)),
        isFalse,
      );
    });

    test('a transport error (no status) is NOT a not-found', () {
      expect(isRecordingNotFound(const NetworkException()), isFalse);
    });

    test('a server error is NOT a not-found', () {
      expect(
        isRecordingNotFound(const ServerException(statusCode: 500)),
        isFalse,
      );
    });

    test('an arbitrary non-AppException is NOT a not-found', () {
      expect(isRecordingNotFound(Exception('boom')), isFalse);
    });
  });
}
