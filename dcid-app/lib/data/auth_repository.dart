import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';
import 'models/app_user.dart';

/// Login / session against the backend self-JWT endpoints.
class AuthRepository {
  AuthRepository(this._api, this._storage);

  final ApiClient _api;
  final FlutterSecureStorage _storage;

  Future<AppUser> login(String username, String password) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'username': username, 'password': password},
    );
    final data = res.data!['data'] as Map<String, dynamic>;
    await _storage.write(key: ApiClient.tokenKey, value: data['token'] as String);
    return me();
  }

  Future<AppUser> me() async {
    final res = await _api.dio.get<Map<String, dynamic>>('/api/auth/me');
    return AppUser.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<void> logout() => _storage.delete(key: ApiClient.tokenKey);

  Future<String?> token() => _storage.read(key: ApiClient.tokenKey);
}
