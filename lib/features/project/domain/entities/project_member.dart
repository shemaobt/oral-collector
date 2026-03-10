class ProjectMember {
  final String userId;
  final String email;
  final String? displayName;
  final String role;
  final DateTime? joinedAt;

  const ProjectMember({
    required this.userId,
    required this.email,
    this.displayName,
    required this.role,
    this.joinedAt,
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    return ProjectMember(
      userId: json['user_id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      role: json['role'] as String? ?? 'user',
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'display_name': displayName,
      'role': role,
      'joined_at': joinedAt?.toIso8601String(),
    };
  }
}
