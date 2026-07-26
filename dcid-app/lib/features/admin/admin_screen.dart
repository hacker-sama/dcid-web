import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_user.dart';
import '../../data/models/user_role.dart';
import '../../state/providers.dart';

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
        role: _selectedRoleFilter?.wire,
        search: _searchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _users = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showCreateUserDialog() {
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    UserRole selectedRole = UserRole.operatorRole;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        final nav = Navigator.of(ctx);
        final messenger = ScaffoldMessenger.of(context);
        return AlertDialog(
          title: const Text('Tạo tài khoản người dùng mới'),
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
                      decoration: const InputDecoration(labelText: 'Tên đăng nhập *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên đăng nhập' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Mật khẩu *'),
                      validator: (v) => (v == null || v.length < 6) ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Họ và tên'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<UserRole>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(labelText: 'Vai trò (Role)'),
                      items: UserRole.values
                          .map((r) => DropdownMenuItem(value: r, child: Text('${r.label} (${r.wire})')))
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
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final repo = ref.read(authRepositoryProvider);
                  await repo.createUser(
                    username: usernameCtrl.text.trim(),
                    password: passwordCtrl.text,
                    fullName: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                    email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                    role: selectedRole.wire,
                  );

                  nav.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Tạo tài khoản thành công!')),
                  );
                  _fetchUsers();
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              },
              child: const Text('Tạo mới'),
            ),
          ],
        );
      },
    );
  }

  void _showResetPasswordDialog(AppUser user) {
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        final nav = Navigator.of(ctx);
        final messenger = ScaffoldMessenger.of(context);
        return AlertDialog(
          title: Text('Reset mật khẩu: ${user.username}'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 350,
              child: TextFormField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới *'),
                validator: (v) => (v == null || v.length < 6) ? 'Mật khẩu tối thiểu 6 ký tự' : null,
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => nav.pop(), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final repo = ref.read(authRepositoryProvider);
                  await repo.resetPassword(id: user.id, newPassword: passwordCtrl.text);
                  nav.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Đổi mật khẩu thành công!')),
                  );
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              },
              child: const Text('Lưu mật khẩu'),
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
        SnackBar(content: Text('${newStatus ? "Kích hoạt" : "Khóa"} tài khoản ${user.username} thành công!')),
      );
      _fetchUsers();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản trị hệ thống & Tài khoản'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Controls Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm theo tên, username, email...',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onSubmitted: (_) => _fetchUsers(),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<UserRole?>(
                        initialValue: _selectedRoleFilter,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: 'Lọc vai trò',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tất cả vai trò')),
                          ...UserRole.values.map(
                            (r) => DropdownMenuItem(value: r, child: Text(r.label)),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _selectedRoleFilter = v);
                          _fetchUsers();
                        },
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _fetchUsers,
                      icon: const Icon(Icons.filter_list),
                      label: const Text('Lọc'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: _showCreateUserDialog,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Tạo tài khoản mới'),
                    ),

                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Content Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                              const SizedBox(height: 8),
                              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(onPressed: _fetchUsers, child: const Text('Thử lại')),
                            ],
                          ),
                        )
                      : _users.isEmpty
                          ? const Center(child: Text('Không tìm thấy tài khoản nào'))
                          : Card(
                              elevation: 2,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Username')),
                                      DataColumn(label: Text('Họ và tên')),
                                      DataColumn(label: Text('Email')),
                                      DataColumn(label: Text('Vai trò (Role)')),
                                      DataColumn(label: Text('Trạng thái')),
                                      DataColumn(label: Text('Thao tác')),
                                    ],
                                    rows: _users.map((user) {
                                      return DataRow(cells: [
                                        DataCell(Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold))),
                                        DataCell(Text(user.fullName ?? '—')),
                                        DataCell(Text(user.email ?? '—')),
                                        DataCell(Chip(
                                          label: Text(
                                            user.role.label,
                                            style: const TextStyle(color: Colors.white, fontSize: 12),
                                          ),
                                          backgroundColor: _getRoleColor(user.role),
                                        )),
                                        DataCell(Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Switch(
                                              value: user.isActive,
                                              onChanged: (val) => _toggleUserStatus(user, val),
                                            ),
                                            Text(user.isActive ? 'Hoạt động' : 'Đã khóa'),
                                          ],
                                        )),
                                        DataCell(Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.lock_reset, color: Colors.amber),
                                              tooltip: 'Reset mật khẩu',
                                              onPressed: () => _showResetPasswordDialog(user),
                                            ),
                                          ],
                                        )),
                                      ]);
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
