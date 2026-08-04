import 'models/app_user.dart';

/// Contract for authentication operations (login, me, logout, token).
///
/// Both [AuthRepository] (real backend) and [MockAuthRepository]
/// implement this so they can be swapped via Riverpod overrides.
abstract class IAuthRepository {
  Future<AppUser> login(String username, String password);
  Future<AppUser> me();
  Future<void> logout();
  Future<String?> token();
}
