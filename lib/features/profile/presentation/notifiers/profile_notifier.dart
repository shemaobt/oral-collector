import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/auth/auth_notifier.dart';
import '../../../sync/presentation/notifiers/sync_notifier.dart';
import 'profile_state.dart';

final profileNotifierProvider = NotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    return const ProfileState();
  }

  Future<void> loadStorageUsed() async {
    final bytes = await ref
        .read(syncNotifierProvider.notifier)
        .getLocalStorageUsed();
    state = state.copyWith(storageUsedBytes: bytes);
  }

  Future<bool> pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image == null) return false;

    state = state.copyWith(isUploadingAvatar: true);
    try {
      await ref.read(authNotifierProvider.notifier).uploadAvatar(image.path);
      return true;
    } finally {
      state = state.copyWith(isUploadingAvatar: false);
    }
  }

  Future<void> updateDisplayName(String name) async {
    await ref
        .read(authNotifierProvider.notifier)
        .updateProfile(displayName: name);
  }

  Future<void> clearCacheAndRefresh() async {
    await ref.read(syncNotifierProvider.notifier).clearLocalCache();
    await loadStorageUsed();
  }
}
