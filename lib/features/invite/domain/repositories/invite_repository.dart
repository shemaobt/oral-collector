import '../entities/invite.dart';

abstract class InviteRepository {
  Future<List<Invite>> fetchMyInvites();
  Future<void> acceptInvite(String inviteId);
  Future<void> declineInvite(String inviteId);
}
