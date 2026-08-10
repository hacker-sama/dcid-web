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
///
/// Uses [StatefulShellRoute.indexedStack] so every tab widget is kept alive
/// in an IndexedStack — navigating away and back NEVER destroys the tab's
/// widget or local scroll state.
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
      if (auth.status == AuthStatus.unknown ||
          auth.status == AuthStatus.loading) {
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

      // Viewer is outside the shell — shows full-screen without nav rail/bar.
      GoRoute(
        path: '/viewer/:versionId',
        builder: (_, state) {
          final pageNo = int.tryParse(
            state.uri.queryParameters['page'] ?? '',
          );
          return DocumentViewerScreen(
            versionId: state.pathParameters['versionId']!,
            pageNo: pageNo,
          );
        },
      ),

      // ── Persistent tab shell ───────────────────────────────────────────────
      // IndexedStack keeps each branch widget alive; tab switches only
      // toggle visibility — the widget is NEVER rebuilt from scratch.
      // Branch order matches _allDestinations in home_shell.dart:
      //   0 = /search, 1 = /snap, 2 = /documents, 3 = /admin
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          // Branch 0 — Lookup
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (_, _) => const SearchScreen(),
              ),
            ],
          ),

          // Branch 1 — Snap & Ask
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/snap',
                builder: (_, _) => const SnapAskScreen(),
              ),
            ],
          ),

          // Branch 2 — Documents (with nested detail route)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/documents',
                builder: (_, _) => const DocumentsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => DocumentDetailScreen(
                      documentId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Branch 3 — Admin (admin only; router redirect blocks access)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin',
                builder: (_, _) => const AdminScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
