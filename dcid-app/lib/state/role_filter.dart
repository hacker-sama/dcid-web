import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/user_role.dart';
import 'auth_controller.dart';

/// Categories visible to each role (FRONTEND.md §3 — role-based filtering).
///
/// - **OPERATOR**: SOP + SAFETY only.
/// - **ENGINEER**: All categories (SOP, SAFETY, DRAWING, CIRCUIT, MAINTENANCE_LOG, OTHER).
/// - **QA_ADMIN / ADMIN**: All categories (full access).
Set<String> visibleCategoriesForRole(UserRole role) {
  switch (role) {
    case UserRole.operatorRole:
      return const {'SOP', 'SAFETY'};
    case UserRole.engineer:
    case UserRole.qaAdmin:
    case UserRole.admin:
      return const {'SOP', 'SAFETY', 'DRAWING', 'CIRCUIT', 'MAINTENANCE_LOG', 'OTHER'};
  }
}

/// Provides the set of document categories visible to the current user.
/// Empty set if not authenticated (should not happen in practice due to
/// router guards).
final visibleCategoriesProvider = Provider<Set<String>>((ref) {
  final auth = ref.watch(authControllerProvider);
  final role = auth.user?.role;
  if (role == null) return const {};
  return visibleCategoriesForRole(role);
});

/// Whether the current user can upload documents (QA_ADMIN or ADMIN).
final canUploadProvider = Provider<bool>((ref) {
  final auth = ref.watch(authControllerProvider);
  return auth.user?.role.isAdminLevel ?? false;
});

/// Whether the current user can access admin screens.
final canAccessAdminProvider = Provider<bool>((ref) {
  final auth = ref.watch(authControllerProvider);
  return auth.user?.role.isAdminLevel ?? false;
});
