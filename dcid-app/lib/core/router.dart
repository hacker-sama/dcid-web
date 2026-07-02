import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/admin_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/common/forbidden_screen.dart';
import '../features/documents/document_detail_screen.dart';
import '../features/documents/documents_screen.dart';
import '../features/search/search_screen.dart';
import '../features/shell/home_shell.dart';
import '../features/snap_ask/snap_ask_screen.dart';
import '../features/viewer/document_viewer_screen.dart';
import '../state/auth_controller.dart';

/// App router. Reacts to [authControllerProvider]: unauthenticated users are
/// sent to /login, and the /admin area is gated to QA/Admin roles.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);

  return GoRouter(
    initialLocation: '/search',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      // Still restoring the session — don't redirect yet.
      if (auth.status == AuthStatus.unknown || auth.status == AuthStatus.loading) {
        return null;
      }
      final loggingIn = state.matchedLocation == '/login';
      if (!auth.isAuthenticated) return loggingIn ? null : '/login';
      if (loggingIn) return '/search';
      if (state.matchedLocation.startsWith('/admin') &&
          !(auth.user?.role.isAdminLevel ?? false)) {
        return '/403';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/403', builder: (_, _) => const ForbiddenScreen()),
      ShellRoute(
        builder: (_, _, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
          GoRoute(path: '/snap', builder: (_, _) => const SnapAskScreen()),
          GoRoute(path: '/documents', builder: (_, _) => const DocumentsScreen()),
          GoRoute(
            path: '/documents/:id',
            builder: (_, state) =>
                DocumentDetailScreen(documentId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/admin', builder: (_, _) => const AdminScreen()),
          GoRoute(
            path: '/viewer/:versionId',
            builder: (_, state) =>
                DocumentViewerScreen(versionId: state.pathParameters['versionId']!),
          ),
        ],
      ),
    ],
  );
});
