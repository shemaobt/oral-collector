import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/authenticated_client.dart';
import '../../../core/network/response_decoder.dart';
import '../../../core/serialization/parse_list.dart';
import 'user_lookup_provider.dart';

class UserSearchRepository {
  final AuthenticatedClient _client;

  UserSearchRepository({required AuthenticatedClient client})
    : _client = client;

  Future<List<UserLookup>> search(String query) async {
    final response = await _client.get(
      '/api/users/search?q=${Uri.encodeQueryComponent(query)}',
    );
    return parseList(
      decodeList(response),
      UserLookup.fromJson,
      context: 'userSearch',
    );
  }
}

final userSearchRepositoryProvider = Provider<UserSearchRepository>(
  (ref) => UserSearchRepository(client: ref.watch(authenticatedClientProvider)),
);
