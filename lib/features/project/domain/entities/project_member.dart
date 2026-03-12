class ProjectMember {
  final String id;
  final String projectId;
  final String userId;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final DateTime? grantedAt;

  const ProjectMember({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.grantedAt,
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    return ProjectMember(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      userId: json['user_id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      grantedAt: json['granted_at'] != null
          ? DateTime.parse(json['granted_at'] as String)
          : null,
    );
  }
}
