import 'dart:io';
import 'dart:typed_data';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:oral_collector/features/sync/data/services/upload_downloader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('inline_uploader_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('HttpInlineUploader.putChunk', () {
    test('sends Content-Range and the requested byte slice over PUT', () async {
      final file = File('${tempDir.path}/sample.m4a');
      // 0..15 contiguous bytes; we'll PUT [8..16).
      file.writeAsBytesSync(Uint8List.fromList(List.generate(16, (i) => i)));

      Uint8List? sentBody;
      String? sentRangeHeader;
      String? sentMethod;
      final client = MockClient((request) async {
        sentMethod = request.method;
        sentBody = request.bodyBytes;
        sentRangeHeader = request.headers['Content-Range'];
        return http.Response('', 308);
      });

      final uploader = HttpInlineUploader(client);
      final result = await uploader.putChunk(
        taskId: 'task-1',
        url: 'https://storage.googleapis.com/upload/session-x',
        filePath: file.path,
        offset: 8,
        end: 16,
        headers: {'Content-Range': 'bytes 8-15/16'},
      );

      expect(result.statusCode, 308);
      expect(sentMethod, 'PUT');
      expect(sentRangeHeader, 'bytes 8-15/16');
      expect(
        sentBody,
        equals(Uint8List.fromList([8, 9, 10, 11, 12, 13, 14, 15])),
      );
    });

    test('returns cancelled=true when cancelAll fired before PUT', () async {
      final file = File('${tempDir.path}/cancel.m4a');
      file.writeAsBytesSync(Uint8List.fromList([0, 1, 2, 3]));

      var requestSent = false;
      final client = MockClient((request) async {
        requestSent = true;
        return http.Response('', 200);
      });

      final uploader = HttpInlineUploader(client);
      await uploader.cancelAll();

      final result = await uploader.putChunk(
        taskId: 'task-x',
        url: 'https://example.test/upload',
        filePath: file.path,
        offset: 0,
        end: 4,
        headers: const {},
      );

      expect(result.cancelled, isTrue);
      expect(result.statusCode, 0);
      expect(requestSent, isFalse, reason: 'no HTTP request when cancelled');
    });

    test('resumeAfterCancel re-arms the uploader for new PUTs', () async {
      final file = File('${tempDir.path}/resume.m4a');
      file.writeAsBytesSync(Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7]));

      var requestsSent = 0;
      final client = MockClient((request) async {
        requestsSent++;
        return http.Response('', 308);
      });

      final uploader = HttpInlineUploader(client);
      await uploader.cancelAll();

      // First putChunk after cancelAll: cancelled.
      final cancelled = await uploader.putChunk(
        taskId: 'a',
        url: 'https://example.test/upload',
        filePath: file.path,
        offset: 0,
        end: 8,
        headers: const {},
      );
      expect(cancelled.cancelled, isTrue);
      expect(requestsSent, 0);

      // Coordinator releases the mutex → uploader is re-armed.
      await uploader.resumeAfterCancel();

      final live = await uploader.putChunk(
        taskId: 'b',
        url: 'https://example.test/upload',
        filePath: file.path,
        offset: 0,
        end: 8,
        headers: const {},
      );
      expect(live.cancelled, isFalse);
      expect(live.statusCode, 308);
      expect(requestsSent, 1);
    });

    test('returns file_not_found error when the file is missing', () async {
      final uploader = HttpInlineUploader(
        MockClient((_) async {
          throw StateError('should not reach HTTP');
        }),
      );

      final result = await uploader.putChunk(
        taskId: 'missing',
        url: 'https://example.test/upload',
        filePath: '${tempDir.path}/does_not_exist.m4a',
        offset: 0,
        end: 1024,
        headers: const {},
      );

      expect(result.statusCode, 0);
      expect(result.errorReason, 'file_not_found');
    });

    test('200 from final chunk is surfaced verbatim', () async {
      final file = File('${tempDir.path}/final.m4a');
      file.writeAsBytesSync(Uint8List.fromList([1, 2, 3]));

      final client = MockClient((request) async {
        return http.Response('{"ok": true}', 200);
      });

      final result = await HttpInlineUploader(client).putChunk(
        taskId: 't',
        url: 'https://example.test/upload',
        filePath: file.path,
        offset: 0,
        end: 3,
        headers: const {'Content-Range': 'bytes 0-2/3'},
      );

      expect(result.statusCode, 200);
      expect(result.responseBody, '{"ok": true}');
      expect(result.cancelled, isFalse);
    });

    test('surfaces GCS response headers on success', () async {
      final file = File('${tempDir.path}/headers.m4a');
      file.writeAsBytesSync(Uint8List.fromList([1, 2, 3]));

      final client = MockClient((request) async {
        return http.Response(
          '',
          200,
          headers: {'x-goog-hash': 'crc32c=Nks/tw=='},
        );
      });

      final result = await HttpInlineUploader(client).putChunk(
        taskId: 't',
        url: 'https://example.test/upload',
        filePath: file.path,
        offset: 0,
        end: 3,
        headers: const {'Content-Range': 'bytes 0-2/3'},
      );

      expect(result.statusCode, 200);
      expect(result.responseHeaders['x-goog-hash'], 'crc32c=Nks/tw==');
    });
  });

  group('BackgroundDownloaderUploader.uploadResultFromTaskStatus', () {
    test('complete forwards statusCode, body and responseHeaders', () {
      final result = BackgroundDownloaderUploader.uploadResultFromTaskStatus(
        status: TaskStatus.complete,
        responseStatusCode: 200,
        responseBody: 'ok',
        responseHeaders: {'x-goog-hash': 'crc32c=AAAA=='},
      );

      expect(result.statusCode, 200);
      expect(result.responseBody, 'ok');
      expect(result.responseHeaders['x-goog-hash'], 'crc32c=AAAA==');
      expect(result.cancelled, isFalse);
      expect(result.errorReason, isNull);
    });

    test('complete without a response code defaults to 200', () {
      final result = BackgroundDownloaderUploader.uploadResultFromTaskStatus(
        status: TaskStatus.complete,
      );

      expect(result.statusCode, 200);
      expect(result.responseHeaders, isEmpty);
    });

    test('canceled maps to cancelled and still forwards headers', () {
      final result = BackgroundDownloaderUploader.uploadResultFromTaskStatus(
        status: TaskStatus.canceled,
        responseHeaders: {'x-goog-hash': 'crc32c=BBBB=='},
      );

      expect(result.cancelled, isTrue);
      expect(result.responseHeaders['x-goog-hash'], 'crc32c=BBBB==');
    });

    test('failed surfaces the status name as errorReason', () {
      final result = BackgroundDownloaderUploader.uploadResultFromTaskStatus(
        status: TaskStatus.failed,
        responseStatusCode: 500,
      );

      expect(result.statusCode, 500);
      expect(result.errorReason, 'failed');
    });

    test('TaskHttpException response code becomes the effective status', () {
      final result = BackgroundDownloaderUploader.uploadResultFromTaskStatus(
        status: TaskStatus.failed,
        exception: TaskHttpException('boom', 410),
      );

      expect(result.statusCode, 410);
      expect(result.errorReason, contains('boom'));
    });
  });
}
