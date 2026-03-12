class ProfileState {
  final int storageUsedBytes;
  final bool isUploadingAvatar;

  const ProfileState({
    this.storageUsedBytes = 0,
    this.isUploadingAvatar = false,
  });

  ProfileState copyWith({int? storageUsedBytes, bool? isUploadingAvatar}) {
    return ProfileState(
      storageUsedBytes: storageUsedBytes ?? this.storageUsedBytes,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
    );
  }
}
