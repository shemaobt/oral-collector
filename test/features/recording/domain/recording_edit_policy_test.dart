import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/auth/domain/entities/user.dart';
import 'package:oral_collector/features/recording/domain/recording_edit_policy.dart';

void main() {
  const owner = User(id: 'owner-1', email: 'o@x.com', isPlatformAdmin: false);
  const admin = User(id: 'admin-1', email: 'a@x.com', isPlatformAdmin: true);
  const other = User(id: 'other-1', email: 'b@x.com', isPlatformAdmin: false);

  group('canEditRecording', () {
    test('platform admin can edit any recording', () {
      expect(
        canEditRecording(
          user: admin,
          canManageProject: false,
          recordingUserId: 'someone-else',
        ),
        isTrue,
      );
    });

    test('project manager can edit', () {
      expect(
        canEditRecording(
          user: other,
          canManageProject: true,
          recordingUserId: 'someone-else',
        ),
        isTrue,
      );
    });

    test('owner can edit their own recording', () {
      expect(
        canEditRecording(
          user: owner,
          canManageProject: false,
          recordingUserId: 'owner-1',
        ),
        isTrue,
      );
    });

    test('ordinary non-owner cannot edit', () {
      expect(
        canEditRecording(
          user: other,
          canManageProject: false,
          recordingUserId: 'owner-1',
        ),
        isFalse,
      );
    });

    test('null user cannot edit', () {
      expect(
        canEditRecording(
          user: null,
          canManageProject: true,
          recordingUserId: 'other-1',
        ),
        isFalse,
      );
    });

    test('null recordingUserId is not ownership', () {
      expect(
        canEditRecording(
          user: other,
          canManageProject: false,
          recordingUserId: null,
        ),
        isFalse,
      );
    });
  });
}
