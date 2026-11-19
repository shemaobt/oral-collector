import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const appSentence =
    'Oral Collector is a mobile and web app for collecting monolingual audio data.';

void main() {
  final indexHtml = File('web/index.html').readAsStringSync();
  final manifest =
      jsonDecode(File('web/manifest.json').readAsStringSync())
          as Map<String, dynamic>;

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

  test('the install manifest names the app Oral Collector in full', () {
    expect(manifest['name'], 'Oral Collector');
    expect(manifest['short_name'], 'Oral Collector');
  });

  test(
    'the install manifest describes Oral Collector, not a Flutter project',
    () {
      expect(manifest['description'], appSentence);
    },
  );

  test('the install manifest uses the app palette, not Flutter blue', () {
    expect(manifest['background_color'], '#F6F5EB');
    expect(manifest['theme_color'], '#BE4A01');
  });
}
