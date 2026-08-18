import '../auth_repository_interface.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';

/// Mock auth repository for development.
class MockAuthRepository implements IAuthRepository {
  String? _fakeToken;

  final List<AppUser> _users = [
    const AppUser(id: '1', username: 'admin', role: UserRole.admin, fullName: 'System Admin', email: 'admin@kcn.vn'),
    const AppUser(id: '2', username: 'engineer1', role: UserRole.engineer, fullName: 'Nguyễn Văn A', email: 'nva@kcn.vn'),
    const AppUser(id: '3', username: 'operator1', role: UserRole.operatorRole, fullName: 'Trần Văn B', email: 'tvb@kcn.vn'),
  ];

  @override
  Future<AppUser> login(String username, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _fakeToken = 'mock-jwt-$username';
    return _userForUsername(username);
  }

  @override
  Future<AppUser> me() async {
    return _userForUsername('admin');
  }

  @override
  Future<void> logout() async {
    _fakeToken = null;
  }

  @override
  Future<String?> token() async => _fakeToken;

  @override
  Future<List<AppUser>> listUsers({int page = 0, int size = 20, String? role, String? search}) async {
    return _users.where((u) {
      if (role != null && role.isNotEmpty && u.role.name.toUpperCase() != role.toUpperCase()) {
        return false;
      }
      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        final matchUser = u.username.toLowerCase().contains(q);
        final matchName = (u.fullName ?? '').toLowerCase().contains(q);
        return matchUser || matchName;
      }
      return true;
    }).toList();
  }

  @override
  Future<AppUser> createUser({
    required String username,
    required String password,
    String? fullName,
    String? email,
    required String role,
  }) async {
    final user = AppUser(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      username: username,
      role: UserRole.fromWire(role),
      fullName: fullName,
      email: email,
      isActive: true,
    );
    _users.add(user);
    return user;
  }

  @override
  Future<AppUser> updateUser({
    required String id,
    String? fullName,
    String? email,
    required String role,
  }) async {
    final index = _users.indexWhere((u) => u.id == id);
    if (index == -1) throw Exception('User not found');
    final updated = AppUser(
      id: id,
      username: _users[index].username,
      role: UserRole.fromWire(role),
      fullName: fullName ?? _users[index].fullName,
      email: email ?? _users[index].email,
      isActive: _users[index].isActive,
    );
    _users[index] = updated;
    return updated;
  }

  @override
  Future<void> resetPassword({required String id, required String newPassword}) async {
    // Mock success
  }

  @override
  Future<AppUser> updateUserStatus({required String id, required bool isActive}) async {
    final index = _users.indexWhere((u) => u.id == id);
    if (index == -1) throw Exception('User not found');
    final u = _users[index];
    final updated = AppUser(
      id: id,
      username: u.username,
      role: u.role,
      fullName: u.fullName,
      email: u.email,
      isActive: isActive,
    );
    _users[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteUser(String id) async {
    _users.removeWhere((u) => u.id == id);
  }

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

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    // Mock: accept any password change
  }
}
