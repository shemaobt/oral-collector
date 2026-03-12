import '../../domain/entities/project_member.dart';

class MemberState {
  final List<ProjectMember> members;
  final bool isLoading;
  final String? error;

  const MemberState({
    this.members = const [],
    this.isLoading = false,
    this.error,
  });

  MemberState copyWith({
    List<ProjectMember>? members,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MemberState(
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
