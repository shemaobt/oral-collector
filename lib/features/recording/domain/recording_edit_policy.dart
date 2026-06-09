import '../../auth/domain/entities/user.dart';

/// Whether [user] may edit a recording: platform admins, managers of the
/// recording's project, and the recording's own creator. A null user cannot.
bool canEditRecording({
  required User? user,
  required bool canManageProject,
  required String? recordingUserId,
}) {
  if (user == null) return false;
  return user.isPlatformAdmin || canManageProject || recordingUserId == user.id;
}
