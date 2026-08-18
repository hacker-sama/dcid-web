import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';
import 'auth_repository_interface.dart';
import 'models/app_user.dart';

/// Login / session / admin user management against the backend REST endpoints.
class AuthRepository implements IAuthRepository {
  AuthRepository(this._api, this._storage);

  final ApiClient _api;
  final FlutterSecureStorage _storage;

  @override
  Future<AppUser> login(String username, String password) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'username': username, 'password': password},
    );
    final data = res.data!['data'] as Map<String, dynamic>;
    await _storage.write(key: ApiClient.tokenKey, value: data['token'] as String);
    return me();
  }

  @override
  Future<AppUser> me() async {
    final res = await _api.dio.get<Map<String, dynamic>>('/api/auth/me');
    return AppUser.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> logout() => _storage.delete(key: ApiClient.tokenKey);

  @override
  Future<String?> token() => _storage.read(key: ApiClient.tokenKey);

  @override
  Future<List<AppUser>> listUsers({
    int page = 0,
    int size = 20,
    String? role,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (role != null && role.isNotEmpty) queryParams['role'] = role;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final res = await _api.dio.get<Map<String, dynamic>>(
      '/api/admin/users',
      queryParameters: queryParams,
    );
    final pagedData = res.data!['data'] as Map<String, dynamic>;
    final items = pagedData['items'] as List<dynamic>;
    return items.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<AppUser> createUser({
    required String username,
    required String password,
    String? fullName,
    String? email,
    required String role,
  }) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/api/admin/users',
      data: {
        'username': username,
        'password': password,
        'fullName': fullName,
        'email': email,
        'role': role,
      },
    );
    return AppUser.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  @override
  Future<AppUser> updateUser({
    required String id,
    String? fullName,
    String? email,
    required String role,
  }) async {
    final res = await _api.dio.put<Map<String, dynamic>>(
      '/api/admin/users/$id',
      data: {
        'fullName': fullName,
        'email': email,
        'role': role,
      },
    );
    return AppUser.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> resetPassword({required String id, required String newPassword}) async {
    await _api.dio.put<Map<String, dynamic>>(
      '/api/admin/users/$id/password',
      data: {'newPassword': newPassword},
    );
  }

  @override
  Future<AppUser> updateUserStatus({required String id, required bool isActive}) async {
    final res = await _api.dio.patch<Map<String, dynamic>>(
      '/api/admin/users/$id/status',
      data: {'isActive': isActive},
    );
    return AppUser.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.dio.put<Map<String, dynamic>>(
      '/api/auth/me/password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }
}
