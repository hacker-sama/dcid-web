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
        'label': 'Điện áp vào',
      });
      expect(bbox.x, closeTo(0.1, 1e-9));
      expect(bbox.y, closeTo(0.2, 1e-9));
      expect(bbox.width, closeTo(0.5, 1e-9));
      expect(bbox.height, closeTo(0.15, 1e-9));
      expect(bbox.label, 'Điện áp vào');
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
}
