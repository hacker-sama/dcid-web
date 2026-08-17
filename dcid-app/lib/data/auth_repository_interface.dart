import 'models/app_user.dart';

/// Contract for authentication and admin user management operations.
abstract class IAuthRepository {
  Future<AppUser> login(String username, String password);
  Future<AppUser> me();
  Future<void> logout();
  Future<String?> token();

  // Admin User Management
  Future<List<AppUser>> listUsers({int page = 0, int size = 20, String? role, String? search});
  Future<AppUser> createUser({
    required String username,
    required String password,
    String? fullName,
    String? email,
    required String role,
  });
  Future<AppUser> updateUser({
    required String id,
    String? fullName,
    String? email,
    required String role,
  });
  Future<void> resetPassword({required String id, required String newPassword});
  Future<AppUser> updateUserStatus({required String id, required bool isActive});

  /// Tự đổi mật khẩu (yêu cầu mật khẩu hiện tại).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
