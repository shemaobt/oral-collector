import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/authenticated_client.dart';
import '../../../core/network/response_decoder.dart';
import '../../../core/observability/error_reporter.dart';
import '../../../core/serialization/parse_list.dart';
import 'user_lookup_provider.dart';

class UserSearchRepository {
  final AuthenticatedClient _client;
  final ErrorReporter _reporter;

  UserSearchRepository({
    required AuthenticatedClient client,
    required ErrorReporter reporter,
  }) : _client = client,
       _reporter = reporter;

  Future<List<UserLookup>> search(String query) async {
    final response = await _client.get(
      '/api/users/search?q=${Uri.encodeQueryComponent(query)}',
    );
    return parseList(
      decodeList(response),
      UserLookup.fromJson,
      context: 'userSearch',
      onSkip: _reporter.parseSkipSink(context: 'userSearch'),
    );
  }
}

final userSearchRepositoryProvider = Provider<UserSearchRepository>(
  (ref) => UserSearchRepository(
    client: ref.watch(authenticatedClientProvider),
    reporter: ref.watch(errorReporterProvider),
  ),
);
