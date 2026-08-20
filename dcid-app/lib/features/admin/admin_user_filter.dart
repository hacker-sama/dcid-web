import '../../data/models/app_user.dart';
import '../../data/models/user_role.dart';

/// Filters available from the user-management shortcuts and role dropdown.
enum AdminUserFilter {
  all,
  operatorRole,
  engineer,
  adminsAndQa,
  qaAdmin,
  admin,
}

extension AdminUserFilterMatching on AdminUserFilter {
  bool matches(AppUser user) {
    return switch (this) {
      AdminUserFilter.all => true,
      AdminUserFilter.operatorRole => user.role == UserRole.operatorRole,
      AdminUserFilter.engineer => user.role == UserRole.engineer,
      AdminUserFilter.adminsAndQa => user.role.isAdminLevel,
      AdminUserFilter.qaAdmin => user.role == UserRole.qaAdmin,
      AdminUserFilter.admin => user.role == UserRole.admin,
    };
  }
}

List<AppUser> filterAdminUsers(
  List<AppUser> users, {
  required AdminUserFilter filter,
  String search = '',
}) {
  final normalizedSearch = search.trim().toLowerCase();

  return users
      .where((user) {
        if (!filter.matches(user)) return false;
        if (normalizedSearch.isEmpty) return true;

        return user.username.toLowerCase().contains(normalizedSearch) ||
            (user.fullName?.toLowerCase().contains(normalizedSearch) ??
                false) ||
            (user.email?.toLowerCase().contains(normalizedSearch) ?? false);
      })
      .toList(growable: false);
}
