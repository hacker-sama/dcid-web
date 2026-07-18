import '../models/app_user.dart';
import '../models/user_role.dart';

/// Mock auth repository for Week 1 development (no backend needed).
///
/// Accepts any credentials and returns a fake user. The username
/// determines the role:
///
/// | Username       | Role      |
/// |----------------|-----------|
/// | `admin`        | ADMIN     |
/// | `qa`           | QA_ADMIN  |
/// | `engineer`     | ENGINEER  |
/// | anything else  | OPERATOR  |
class MockAuthRepository {
  String? _fakeToken;

  Future<AppUser> login(String username, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _fakeToken = 'mock-jwt-$username';
    return _userForUsername(username);
  }

  Future<AppUser> me() async {
    // Return a default user if no login happened yet.
    return _userForUsername('admin');
  }

  Future<void> logout() async {
    _fakeToken = null;
  }

  Future<String?> token() async => _fakeToken;

  static AppUser _userForUsername(String username) {
    final UserRole role;
    switch (username.toLowerCase()) {
      case 'admin':
        role = UserRole.admin;
      case 'qa':
        role = UserRole.qaAdmin;
      case 'engineer':
        role = UserRole.engineer;
      default:
        role = UserRole.operatorRole;
    }
    return AppUser(
      id: 'mock-user-001',
      username: username,
      role: role,
      fullName: 'Mock ${role.label}',
      email: '$username@factory.local',
    );
  }
}
