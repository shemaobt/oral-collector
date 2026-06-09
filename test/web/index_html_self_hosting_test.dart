import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('web/index.html sql.js auto-hospedado (ENG-130)', () {
    final indexHtml = File('web/index.html').readAsStringSync();

    test('não carrega sql.js de nenhuma CDN', () {
      expect(indexHtml, isNot(contains('cdn.jsdelivr.net')));
    });

    test('nenhum <script> é carregado de origem remota', () {
      expect(indexHtml, isNot(contains('<script src="http')));
    });

    test('carrega o loader sql-wasm.js same-origin', () {
      expect(indexHtml, contains('<script src="sql-wasm.js">'));
    });

    test('locateFile resolve o .wasm same-origin (sem URL remota)', () {
      expect(indexHtml, contains('return file;'));
    });

    test('os assets vendorizados do sql.js existem', () {
      expect(File('web/sql-wasm.js').existsSync(), isTrue);
      expect(File('web/sql-wasm.wasm').existsSync(), isTrue);
    });
  });
}
