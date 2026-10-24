enum UserRole {
  user('user', 'Warga'),
  admin('admin', 'Petugas / Admin');

  const UserRole(this.value, this.label);
  final String value;
  final String label;

  static UserRole fromString(String? val) {
    if (val == 'admin') return UserRole.admin;
    return UserRole.user;
  }
}

/// Model profil pengguna sesuai PRD.md Bagian 3.2 & 7.1
class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.username = '',
    this.avatarUrl,
    this.role = UserRole.user,
    this.assignedAreaIds = const [],
    this.createdAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String username;
  final String? avatarUrl;
  final UserRole role;
  final List<String> assignedAreaIds;
  final DateTime? createdAt;

  bool get isAdmin => role == UserRole.admin;

  UserProfileModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? username,
    String? avatarUrl,
    bool resetAvatar = false,
    UserRole? role,
    List<String>? assignedAreaIds,
    DateTime? createdAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      avatarUrl: resetAvatar ? null : (avatarUrl ?? this.avatarUrl),
      role: role ?? this.role,
      assignedAreaIds: assignedAreaIds ?? this.assignedAreaIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'username': username,
      'avatar_url': avatarUrl,
      'role': role.value,
      'assigned_area_ids': assignedAreaIds,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Warga Laporin',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      role: UserRole.fromString(json['role'] as String?),
      assignedAreaIds:
          (json['assigned_area_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}
