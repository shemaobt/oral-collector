import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const appSentence =
    'Oral Collector is a mobile and web app for collecting monolingual audio data.';

void main() {
  final indexHtml = File('web/index.html').readAsStringSync();

  test('the browser tab reads Oral Collector, not the package name', () {
    expect(indexHtml, contains('<title>Oral Collector</title>'));
  });

  test('the iOS home screen names the app Oral Collector, not the package', () {
    expect(
      indexHtml,
      contains(
        '<meta name="apple-mobile-web-app-title" content="Oral Collector">',
      ),
    );
  });

  test('the page describes Oral Collector, not a new Flutter project', () {
    expect(
      indexHtml,
      contains('<meta name="description" content="$appSentence">'),
    );
  });
}
