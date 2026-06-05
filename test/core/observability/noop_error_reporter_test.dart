import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/observability/error_reporter.dart';

void main() {
  group('NoopErrorReporter', () {
    const reporter = NoopErrorReporter();

    test(
      'reportError não lança, com stack, sem stack, e com tags/context/level',
      () {
        expect(
          () => reporter.reportError(Exception('boom'), StackTrace.current),
          returnsNormally,
        );
        expect(
          () => reporter.reportError(Exception('boom'), null),
          returnsNormally,
        );
        expect(
          () => reporter.reportError(
            Exception('boom'),
            StackTrace.current,
            tags: {'screen': 'home'},
            context: {'retries': 2},
            level: ErrorLevel.warning,
          ),
          returnsNormally,
        );
      },
    );

    test('addBreadcrumb / setUser / clearUser / setTag não lançam', () {
      expect(
        () => reporter.addBreadcrumb('navigated', category: 'ui'),
        returnsNormally,
      );
      expect(() => reporter.setUser(id: '42'), returnsNormally);
      expect(() => reporter.clearUser(), returnsNormally);
      expect(() => reporter.setTag('flavor', 'prod'), returnsNormally);
    });
  });
}
