import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';
import 'auth_repository_interface.dart';
import 'models/app_user.dart';

/// Login / session against the backend self-JWT endpoints.
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
}
