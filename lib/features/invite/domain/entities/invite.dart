class Invite {
  final String id;
  final String projectId;
  final String projectName;
  final String role;
  final String status;
  final DateTime? createdAt;

  const Invite({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.role,
    required this.status,
    this.createdAt,
  });

  factory Invite.fromJson(Map<String, dynamic> json) {
    return Invite(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      projectName: json['project_name'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'project_name': projectName,
      'role': role,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
