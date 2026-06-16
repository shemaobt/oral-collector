import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/core/observability/error_reporter.dart';
import 'package:oral_collector/features/genre/data/repositories/genre_repository.dart';

class _MockClient extends Mock implements AuthenticatedClient {}

class _RecordingReporter implements ErrorReporter {
  final errors = <Object>[];

  @override
  void reportError(
    Object error,
    StackTrace? stackTrace, {
    Map<String, String>? tags,
    Map<String, Object?>? context,
    ErrorLevel level = ErrorLevel.error,
  }) {
    errors.add(error);
  }

  @override
  void addBreadcrumb(
    String message, {
    String? category,
    ErrorLevel level = ErrorLevel.info,
    Map<String, Object?>? data,
  }) {}

  @override
  void setUser({
    String? id,
    String? username,
    String? email,
    Map<String, Object?>? data,
  }) {}

  @override
  void clearUser() {}

  @override
  void setTag(String key, String value) {}
}

void main() {
  late _MockClient client;
  late _RecordingReporter reporter;
  late GenreRepositoryImpl repo;

  setUp(() {
    client = _MockClient();
    reporter = _RecordingReporter();
    repo = GenreRepositoryImpl(client: client, reporter: reporter);
  });

  test('listGenres pula um genre malformado e retorna os válidos', () async {
    when(() => client.get('/api/oc/genres')).thenAnswer(
      (_) async => http.Response(
        '[{"id":"g-1","name":"Folktale"},{"name":"sem id"}]',
        200,
      ),
    );

    final result = await repo.listGenres();

    expect(result.map((g) => g.id).toList(), <String>['g-1']);
  });

  test('listGenres reporta o genre malformado ao ErrorReporter', () async {
    when(() => client.get('/api/oc/genres')).thenAnswer(
      (_) async => http.Response(
        '[{"id":"g-1","name":"Folktale"},{"name":"sem id"}]',
        200,
      ),
    );

    await repo.listGenres();

    expect(reporter.errors, hasLength(1));
  });
}
