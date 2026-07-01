/// RBAC roles, mirroring the backend `vn.dcid.domain.enums.UserRole`.
enum UserRole {
  operatorRole('OPERATOR', 'Operator'),
  engineer('ENGINEER', 'Engineer'),
  qaAdmin('QA_ADMIN', 'QA/Admin'),
  admin('ADMIN', 'Admin');

  const UserRole(this.wire, this.label);

  /// Value as sent by the backend JWT / API (e.g. `OPERATOR`).
  final String wire;

  /// Human-friendly label for the UI.
  final String label;

  static UserRole fromWire(String value) =>
      values.firstWhere((r) => r.wire == value, orElse: () => operatorRole);

  /// Roles allowed into the admin/QA area.
  bool get isAdminLevel => this == admin || this == qaAdmin;
}
