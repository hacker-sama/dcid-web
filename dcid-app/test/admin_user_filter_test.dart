import 'package:dcid_app/data/models/app_user.dart';
import 'package:dcid_app/data/models/user_role.dart';
import 'package:dcid_app/features/admin/admin_user_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const users = [
    AppUser(
      id: '1',
      username: 'operator.one',
      fullName: 'Operator One',
      role: UserRole.operatorRole,
    ),
    AppUser(
      id: '2',
      username: 'engineer.one',
      email: 'engineer@dcid.local',
      role: UserRole.engineer,
    ),
    AppUser(id: '3', username: 'qa.one', role: UserRole.qaAdmin),
    AppUser(id: '4', username: 'admin.one', role: UserRole.admin),
  ];

  test('Admins & QA shortcut includes both admin-level roles', () {
    final result = filterAdminUsers(users, filter: AdminUserFilter.adminsAndQa);

    expect(result.map((user) => user.username), ['qa.one', 'admin.one']);
  });

  test('role shortcut and search are applied together', () {
    final result = filterAdminUsers(
      users,
      filter: AdminUserFilter.engineer,
      search: 'ENGINEER@DCID',
    );

    expect(result.single.username, 'engineer.one');
  });

  test('all shortcut clears the role restriction', () {
    final result = filterAdminUsers(users, filter: AdminUserFilter.all);

    expect(result, hasLength(4));
  });
}
