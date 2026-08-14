import 'user_role.dart';

/// Authenticated user, from `GET /api/auth/me` or `/api/admin/users`.
class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.role,
    this.fullName,
    this.email,
    this.isActive = true,
  });

  final String id;
  final String username;
  final UserRole role;
  final String? fullName;
  final String? email;
  final bool isActive;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String? ?? '',
        username: json['username'] as String? ?? '',
        role: UserRole.fromWire(json['role'] as String? ?? 'OPERATOR'),
        fullName: json['fullName'] as String?,
        email: json['email'] as String?,
        isActive: json['isActive'] == true ||
            json['isActive'] == null ||
            json['isActive'] == 'true',
      );
}
