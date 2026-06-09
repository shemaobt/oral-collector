import 'dart:convert';

import '../../../../core/network/authenticated_client.dart';
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
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch invites: ${response.body}');
    }
    return parseList(
      jsonDecode(response.body),
      Invite.fromJson,
      context: 'fetchMyInvites',
    );
  }

  @override
  Future<void> acceptInvite(String inviteId) async {
    final response = await _client.post('/api/oc/invites/$inviteId/accept');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to accept invite: ${response.body}');
    }
  }

  @override
  Future<void> declineInvite(String inviteId) async {
    final response = await _client.post('/api/oc/invites/$inviteId/decline');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to decline invite: ${response.body}');
    }
  }
}
