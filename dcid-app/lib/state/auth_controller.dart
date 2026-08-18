import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_user.dart';
import 'providers.dart';

enum AuthStatus { unknown, loading, authenticated, unauthenticated, error }

class AuthState {
  const AuthState({required this.status, this.user, this.error});

  final AuthStatus status;
  final AppUser? user;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

/// Holds the session. On startup it tries to restore a stored token; the
/// router listens to this to gate protected routes.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final subscription = ref.read(apiClientProvider).unauthorizedEvents.listen((
      _,
    ) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    });
    ref.onDispose(subscription.cancel);
    _restore();
    return const AuthState(status: AuthStatus.unknown);
  }

  Future<void> _restore() async {
    final repo = ref.read(authRepositoryProvider);
    final token = await repo.token();
    if (token == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await repo.me();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await repo.logout();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String username, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .login(username, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.error,
        error: 'Đăng nhập thất bại. Kiểm tra tài khoản/mật khẩu hoặc kết nối.',
      );
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
