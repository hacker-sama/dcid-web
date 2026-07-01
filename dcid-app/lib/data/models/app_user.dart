import 'user_role.dart';

/// Authenticated user, from `GET /api/auth/me`.
class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.role,
    this.fullName,
    this.email,
  });

  final String id;
  final String username;
  final UserRole role;
  final String? fullName;
  final String? email;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        username: json['username'] as String,
        role: UserRole.fromWire(json['role'] as String),
        fullName: json['fullName'] as String?,
        email: json['email'] as String?,
      );
}
