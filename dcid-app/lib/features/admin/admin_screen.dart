import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_user.dart';
import '../../data/models/user_role.dart';
import '../../state/auth_controller.dart';
import '../../state/providers.dart';
import 'analytics_view.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final _searchController = TextEditingController();
  UserRole? _selectedRoleFilter;
  bool _isLoading = false;
  String? _errorMessage;
  List<AppUser> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      final list = await repo.listUsers(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        role: _selectedRoleFilter?.wire,
      );
      setState(() {
        _users = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load users: $e';
        _isLoading = false;
      });
    }
  }

  void _showCreateUserDialog() {
    final formKey = GlobalKey<FormState>();
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final fullNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    UserRole selectedRole = UserRole.operatorRole;

    showDialog(
      context: context,
      builder: (ctx) {
        final nav = Navigator.of(ctx);
        final messenger = ScaffoldMessenger.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Create New User Account'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: usernameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Username *',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password *',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      validator: (v) =>
                          v == null || v.length < 4 ? 'Min 4 chars' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: fullNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.badge),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<UserRole>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role *',
                        prefixIcon: Icon(Icons.admin_panel_settings),
                      ),
                      items: UserRole.values
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r.label),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) selectedRole = v;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => nav.pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final repo = ref.read(authRepositoryProvider);
                  await repo.createUser(
                    username: usernameCtrl.text.trim(),
                    password: passwordCtrl.text,
                    fullName: fullNameCtrl.text.trim().isEmpty
                        ? null
                        : fullNameCtrl.text.trim(),
                    email: emailCtrl.text.trim().isEmpty
                        ? null
                        : emailCtrl.text.trim(),
                    role: selectedRole.wire,
                  );
                  nav.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Account "${usernameCtrl.text.trim()}" created successfully!',
                      ),
                    ),
                  );
                  _fetchUsers();
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Create Account'),
            ),
          ],
        );
      },
    );
  }

  void _showResetPasswordDialog(AppUser user) {
    final formKey = GlobalKey<FormState>();
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final nav = Navigator.of(ctx);
        final messenger = ScaffoldMessenger.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Reset Password (${user.username})'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 350,
              child: TextFormField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password *',
                  prefixIcon: Icon(Icons.key),
                ),
                validator: (v) =>
                    v == null || v.length < 4 ? 'Min 4 chars' : null,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => nav.pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final repo = ref.read(authRepositoryProvider);
                  await repo.resetPassword(
                      id: user.id, newPassword: passwordCtrl.text);
                  nav.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                        content: Text('Password reset successfully!')),
                  );
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save Password'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleUserStatus(AppUser user, bool newStatus) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.updateUserStatus(id: user.id, isActive: newStatus);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Account ${user.username} is now ${newStatus ? "Active" : "Inactive"}!',
          ),
        ),
      );
      _fetchUsers();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showDeleteUserDialog(AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) {
        final nav = Navigator.of(ctx);
        final messenger = ScaffoldMessenger.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Account'),
          content: Text("Are you sure you want to delete account '${user.username}'? This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => nav.pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () async {
                nav.pop();
                try {
                  final repo = ref.read(authRepositoryProvider);
                  await repo.deleteUser(user.id);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Account ${user.username} deleted successfully'),
                    ),
                  );
                  _fetchUsers();
                  // Re-fetch analytics stat cards using invalidation
                  ref.invalidate(analyticsFutureProvider);
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red.shade700;
      case UserRole.qaAdmin:
        return Colors.purple.shade700;
      case UserRole.engineer:
        return Colors.blue.shade700;
      case UserRole.operatorRole:
        return Colors.teal.shade700;
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ColorScheme scheme,
  }) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final totalUsers = _users.length;
    final operators = _users.where((u) => u.role == UserRole.operatorRole).length;
    final engineers = _users.where((u) => u.role == UserRole.engineer).length;
    final admins = _users
        .where((u) => u.role == UserRole.admin || u.role == UserRole.qaAdmin)
        .length;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Management & Analytics'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people_alt_rounded), text: 'User Accounts'),
              Tab(icon: Icon(Icons.analytics_rounded), text: 'System Analytics'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _fetchUsers();
                ref.invalidate(analyticsFutureProvider);
              },
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: TabBarView(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
            // ── 1. Overview Stat Cards Row ──────────────────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 700;
                final cards = [
                  _buildStatCard(
                    title: 'Total Users',
                    value: '$totalUsers',
                    icon: Icons.people_alt_rounded,
                    color: scheme.primary,
                    scheme: scheme,
                  ),
                  _buildStatCard(
                    title: 'Operators',
                    value: '$operators',
                    icon: Icons.precision_manufacturing_rounded,
                    color: Colors.teal.shade700,
                    scheme: scheme,
                  ),
                  _buildStatCard(
                    title: 'Engineers',
                    value: '$engineers',
                    icon: Icons.engineering_rounded,
                    color: Colors.blue.shade700,
                    scheme: scheme,
                  ),
                  _buildStatCard(
                    title: 'Admins & QA',
                    value: '$admins',
                    icon: Icons.admin_panel_settings_rounded,
                    color: Colors.purple.shade700,
                    scheme: scheme,
                  ),
                ];

                if (isWide) {
                  return Row(
                    children: [
                      for (int i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(child: cards[i]),
                      ],
                    ],
                  );
                }

                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: cards,
                );
              },
            ),
            const SizedBox(height: 16),

            // ── 2. Toolbar Row (Equalized 1/3 widths for all 3 controls) ──
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;

                    final searchInput = SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(fontSize: 13, color: scheme.onSurface),
                        textAlignVertical: TextAlignVertical.center,
                        onChanged: (_) => _fetchUsers(),
                        onSubmitted: (_) => _fetchUsers(),
                        decoration: InputDecoration(
                          hintText: 'Search by name, username, email...',
                          hintStyle: TextStyle(fontSize: 13, color: scheme.outline),
                          prefixIcon: Icon(Icons.search, size: 18, color: scheme.outline),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: scheme.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: scheme.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: scheme.primary, width: 1.5),
                          ),
                        ),
                      ),
                    );

                    final roleDropdown = SizedBox(
                      width: isMobile ? double.infinity : 190,
                      height: 44,
                      child: DropdownButtonFormField<UserRole?>(
                        initialValue: _selectedRoleFilter,
                        borderRadius: BorderRadius.circular(10),
                        menuMaxHeight: 300,
                        isExpanded: true,
                        style: TextStyle(fontSize: 13, color: scheme.onSurface),
                        icon: Icon(Icons.arrow_drop_down, color: scheme.outline),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: 'Filter Role',
                          labelStyle: TextStyle(fontSize: 13, color: scheme.outline),
                          floatingLabelStyle: TextStyle(
                            fontSize: 12,
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: scheme.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: scheme.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: scheme.primary, width: 1.5),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Roles', style: TextStyle(fontSize: 13)),
                          ),
                          ...UserRole.values.map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.label, style: const TextStyle(fontSize: 13)),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _selectedRoleFilter = v);
                          _fetchUsers();
                        },
                      ),
                    );

                    final createBtn = SizedBox(
                      height: 44,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _showCreateUserDialog,
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                        label: const Text(
                          'Create New Account',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    );

                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          searchInput,
                          const SizedBox(height: 10),
                          roleDropdown,
                          const SizedBox(height: 10),
                          createBtn,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: searchInput),
                        const SizedBox(width: 12),
                        roleDropdown,
                        const SizedBox(width: 12),
                        createBtn,
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── 3. Data Table Area (Shrink-wrap height + Pagination) ────
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: scheme.error),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: scheme.error),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _fetchUsers,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_users.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 48, color: scheme.outline),
                      const SizedBox(height: 12),
                      Text(
                        'No accounts found',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                              ),
                              child: DataTable(
                                headingRowHeight: 48,
                                dataRowMinHeight: 52,
                                dataRowMaxHeight: 56,
                                headingRowColor: WidgetStateProperty.all(
                                  scheme.surfaceContainerHighest
                                      .withValues(alpha: 0.4),
                                ),
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'Username',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Full Name',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Email',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        'Role',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        'Status',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        'Actions',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                                rows: _users.map((user) {
                                  return DataRow(cells: [
                                    // Username (Left-aligned)
                                    DataCell(
                                      Text(
                                        user.username,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    // Full Name (Left-aligned)
                                    DataCell(Text(user.fullName ?? '—')),
                                    // Email (Left-aligned)
                                    DataCell(Text(user.email ?? '—')),
                                    // Role Badge (Center-aligned)
                                    DataCell(
                                      Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getRoleColor(user.role),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            user.role.label,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Status Switch & Label (Center-aligned)
                                    DataCell(
                                      Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Transform.scale(
                                              scale: 0.8,
                                              child: Switch(
                                                value: user.isActive,
                                                onChanged: (val) =>
                                                    _toggleUserStatus(
                                                        user, val),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              user.isActive ? 'Active' : 'Inactive',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: user.isActive
                                                    ? Colors.green.shade700
                                                    : scheme.outline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Actions (Center-aligned)
                                    DataCell(
                                      Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.key_rounded,
                                                  size: 18, color: scheme.primary),
                                              tooltip: 'Reset Password',
                                              onPressed: () =>
                                                  _showResetPasswordDialog(user),
                                            ),
                                            if (ref.read(authControllerProvider).user?.id != user.id && user.username != 'admin')
                                              IconButton(
                                                icon: Icon(Icons.delete_outline_rounded,
                                                    size: 18, color: scheme.error),
                                                tooltip: 'Delete Account',
                                                onPressed: () =>
                                                    _showDeleteUserDialog(user),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),

                      // ── Pagination Footer ──────────────────────────────────
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Showing ${_users.length} account${_users.length == 1 ? "" : "s"}',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(Icons.verified_outlined,
                                    size: 14, color: scheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Page 1 of 1',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const AnalyticsView(),
    ],
  ),
),
);
}
}


