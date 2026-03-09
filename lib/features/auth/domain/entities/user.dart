class User {
  final String id;
  final String email;
  final String? displayName;
  final String role;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    required this.role,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      role: json['is_platform_admin'] == true ? 'admin' : 'user',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
