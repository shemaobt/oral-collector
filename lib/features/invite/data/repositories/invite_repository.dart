import '../../../../core/network/authenticated_client.dart';
import '../../../../core/network/error_boundary.dart';
import '../../../../core/network/response_decoder.dart';
import '../../../../core/serialization/parse_list.dart';
import '../../domain/entities/invite.dart';
import '../../domain/repositories/invite_repository.dart';

class InviteRepositoryImpl implements InviteRepository {
  final AuthenticatedClient _client;

  InviteRepositoryImpl({required AuthenticatedClient client})
    : _client = client;

  @override
  Future<List<Invite>> fetchMyInvites() async {
    final response = await _client.get('/api/oc/invites/mine');
    return parseList(
      decodeList(response),
      Invite.fromJson,
      context: 'fetchMyInvites',
    );
  }

  @override
  Future<void> acceptInvite(String inviteId) async {
    final response = await _client.post('/api/oc/invites/$inviteId/accept');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throwForResponse(response);
    }
  }

  @override
  Future<void> declineInvite(String inviteId) async {
    final response = await _client.post('/api/oc/invites/$inviteId/decline');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throwForResponse(response);
    }
  }
}
