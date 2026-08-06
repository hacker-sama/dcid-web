import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/env.dart';

/// Wraps Dio and injects the self-issued JWT (`Authorization: Bearer <jwt>`)
/// from secure storage on every request.
class ApiClient {
  ApiClient(this._storage) {
    dio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 180),
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (DioException err, handler) async {
        final status = err.response?.statusCode;
        final isSessionProbe = err.requestOptions.path == '/api/auth/me';
        if (status == 401 || (status == 403 && isSessionProbe)) {
          await _storage.delete(key: tokenKey);
        }
        handler.next(err);
      },
    ));
  }

  static const String tokenKey = 'jwt';

  final FlutterSecureStorage _storage;
  late final Dio dio;
}
