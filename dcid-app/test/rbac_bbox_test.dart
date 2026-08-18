import 'package:dcid_app/data/models/page_info.dart';
import 'package:dcid_app/data/models/user_role.dart';
import 'package:dcid_app/state/role_filter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for RBAC UI-layer category filter (FRONTEND.md §3).
///
/// Backend enforces real access control via @PreAuthorize; these tests cover
/// the Flutter-side filter that hides irrelevant document categories in the UI.
void main() {
  group('RBAC — visibleCategoriesForRole', () {
    test('OPERATOR sees SOP and SAFETY only', () {
      final cats = visibleCategoriesForRole(UserRole.operatorRole);
      expect(cats, containsAll(['SOP', 'SAFETY']));
      // Technical docs are NOT visible to operators.
      expect(cats, isNot(contains('DRAWING')));
      expect(cats, isNot(contains('CIRCUIT')));
      expect(cats, isNot(contains('MAINTENANCE_LOG')));
    });

    test('ENGINEER sees all 6 categories', () {
      final cats = visibleCategoriesForRole(UserRole.engineer);
      expect(cats, containsAll(
          ['SOP', 'SAFETY', 'DRAWING', 'CIRCUIT', 'MAINTENANCE_LOG', 'OTHER']));
    });

    test('QA_ADMIN sees all 6 categories', () {
      final cats = visibleCategoriesForRole(UserRole.qaAdmin);
      expect(cats, containsAll(
          ['SOP', 'SAFETY', 'DRAWING', 'CIRCUIT', 'MAINTENANCE_LOG', 'OTHER']));
    });

    test('ADMIN sees all 6 categories', () {
      final cats = visibleCategoriesForRole(UserRole.admin);
      expect(cats, containsAll(
          ['SOP', 'SAFETY', 'DRAWING', 'CIRCUIT', 'MAINTENANCE_LOG', 'OTHER']));
    });

    test('OPERATOR set is a strict subset of ENGINEER set', () {
      final opCats = visibleCategoriesForRole(UserRole.operatorRole);
      final engCats = visibleCategoriesForRole(UserRole.engineer);
      expect(engCats.containsAll(opCats), isTrue);
      expect(opCats.containsAll(engCats), isFalse); // operator set is smaller
    });
  });

  group('BoundingBox model', () {
    test('fromJson parses normalized coords correctly', () {
      final bbox = BoundingBox.fromJson({
        'x': 0.1,
        'y': 0.2,
        'width': 0.5,
        'height': 0.15,
        'label': 'Dien ap vao',
      });
      expect(bbox.x, closeTo(0.1, 1e-9));
      expect(bbox.y, closeTo(0.2, 1e-9));
      expect(bbox.width, closeTo(0.5, 1e-9));
      expect(bbox.height, closeTo(0.15, 1e-9));
      expect(bbox.label, 'Dien ap vao');
    });

    test('fromJson handles missing fields with zero defaults', () {
      final bbox = BoundingBox.fromJson({});
      expect(bbox.x, 0.0);
      expect(bbox.y, 0.0);
      expect(bbox.width, 0.0);
      expect(bbox.height, 0.0);
      expect(bbox.label, isNull);
    });
  });

  group('UserRole', () {
    test('maps backend wire values', () {
      expect(UserRole.fromWire('ENGINEER'), UserRole.engineer);
      expect(UserRole.fromWire('QA_ADMIN'), UserRole.qaAdmin);
      expect(UserRole.fromWire('OPERATOR'), UserRole.operatorRole);
      expect(UserRole.fromWire('ADMIN'), UserRole.admin);
      // Unknown wire value falls back to lowest privilege.
      expect(UserRole.fromWire('UNKNOWN'), UserRole.operatorRole);
    });

    test('isAdminLevel is true for QA_ADMIN and ADMIN only', () {
      expect(UserRole.operatorRole.isAdminLevel, isFalse);
      expect(UserRole.engineer.isAdminLevel, isFalse);
      expect(UserRole.qaAdmin.isAdminLevel, isTrue);
      expect(UserRole.admin.isAdminLevel, isTrue);
    });
  });

  // -- RBAC: Upload & Delete permission gate --
  group('RBAC - canUpload / canDelete (isAdminLevel)', () {
    test('OPERATOR cannot upload or delete', () {
      expect(UserRole.operatorRole.isAdminLevel, isFalse,
          reason: 'OPERATOR must not have admin-level document permissions');
    });

    test('ENGINEER cannot upload or delete', () {
      expect(UserRole.engineer.isAdminLevel, isFalse,
          reason: 'ENGINEER must not have admin-level document permissions');
    });

    test('QA_ADMIN can upload and delete', () {
      expect(UserRole.qaAdmin.isAdminLevel, isTrue,
          reason: 'QA_ADMIN should have upload and delete permissions');
    });

    test('ADMIN can upload and delete', () {
      expect(UserRole.admin.isAdminLevel, isTrue,
          reason: 'ADMIN should have upload and delete permissions');
    });
  });

  // -- RBAC: Admin tab visibility --
  group('RBAC - Admin tab visibility logic', () {
    bool isTabVisible({required bool adminOnly, required bool isAdmin}) {
      return !(adminOnly && !isAdmin);
    }

    test('Non-admin tabs are always visible to all roles', () {
      for (final role in UserRole.values) {
        expect(
          isTabVisible(adminOnly: false, isAdmin: role.isAdminLevel),
          isTrue,
          reason: 'Tab with adminOnly=false should be visible to ${role.label}',
        );
      }
    });

    test('Admin tab is visible to QA_ADMIN and ADMIN', () {
      expect(isTabVisible(adminOnly: true, isAdmin: UserRole.qaAdmin.isAdminLevel), isTrue);
      expect(isTabVisible(adminOnly: true, isAdmin: UserRole.admin.isAdminLevel), isTrue);
    });

    test('Admin tab is hidden from OPERATOR and ENGINEER', () {
      expect(
        isTabVisible(adminOnly: true, isAdmin: UserRole.operatorRole.isAdminLevel),
        isFalse,
        reason: 'OPERATOR should not see Admin tab',
      );
      expect(
        isTabVisible(adminOnly: true, isAdmin: UserRole.engineer.isAdminLevel),
        isFalse,
        reason: 'ENGINEER should not see Admin tab',
      );
    });

    test('Non-admin has 3 visible nav tabs (DocuMind, Snap, Documents)', () {
      final allAdminOnly = [false, false, false, true];
      for (final role in [UserRole.operatorRole, UserRole.engineer]) {
        final visibleCount = allAdminOnly
            .where((adminOnly) => isTabVisible(adminOnly: adminOnly, isAdmin: role.isAdminLevel))
            .length;
        expect(visibleCount, 3, reason: '${role.label} should see exactly 3 tabs');
      }
    });

    test('Admin-level user has 4 visible nav tabs including Admin', () {
      final allAdminOnly = [false, false, false, true];
      for (final role in [UserRole.qaAdmin, UserRole.admin]) {
        final visibleCount = allAdminOnly
            .where((adminOnly) => isTabVisible(adminOnly: adminOnly, isAdmin: role.isAdminLevel))
            .length;
        expect(visibleCount, 4, reason: '${role.label} should see all 4 tabs');
      }
    });

    test('branchIndices mapping: non-admin has indices [0,1,2]', () {
      final allAdminOnly = [false, false, false, true];
      final branchIndices = <int>[];
      for (var i = 0; i < allAdminOnly.length; i++) {
        if (isTabVisible(adminOnly: allAdminOnly[i], isAdmin: false)) {
          branchIndices.add(i);
        }
      }
      expect(branchIndices, [0, 1, 2]);
    });

    test('branchIndices mapping: admin has indices [0,1,2,3]', () {
      final allAdminOnly = [false, false, false, true];
      final branchIndices = <int>[];
      for (var i = 0; i < allAdminOnly.length; i++) {
        if (isTabVisible(adminOnly: allAdminOnly[i], isAdmin: true)) {
          branchIndices.add(i);
        }
      }
      expect(branchIndices, [0, 1, 2, 3]);
    });
  });

  // -- RBAC: Router guard logic --
  group('RBAC - /admin route guard logic', () {
    String? routeGuard({required String path, required UserRole role}) {
      if (path.startsWith('/admin') && !role.isAdminLevel) return '/403';
      return null;
    }

    test('OPERATOR is blocked from /admin -> /403', () {
      expect(routeGuard(path: '/admin', role: UserRole.operatorRole), '/403');
    });

    test('ENGINEER is blocked from /admin -> /403', () {
      expect(routeGuard(path: '/admin', role: UserRole.engineer), '/403');
    });

    test('QA_ADMIN is allowed on /admin', () {
      expect(routeGuard(path: '/admin', role: UserRole.qaAdmin), isNull);
    });

    test('ADMIN is allowed on /admin', () {
      expect(routeGuard(path: '/admin', role: UserRole.admin), isNull);
    });

    test('Non-admin routes are allowed for all roles', () {
      for (final role in UserRole.values) {
        expect(routeGuard(path: '/search', role: role), isNull);
        expect(routeGuard(path: '/documents', role: role), isNull);
        expect(routeGuard(path: '/snap', role: role), isNull);
      }
    });
  });
}
