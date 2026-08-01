import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../state/auth_controller.dart';

class _Dest {
  const _Dest(this.path, this.icon, this.label, {this.adminOnly = false});
  final String path;
  final IconData icon;
  final String label;
  final bool adminOnly;
}


const _allDestinations = <_Dest>[
  _Dest('/search', Icons.search, 'Tra cứu'),
  _Dest('/snap', Icons.camera_alt, 'Snap & Ask'),
  _Dest('/documents', Icons.folder, 'Tài liệu'),
  _Dest('/admin', Icons.admin_panel_settings, 'Quản trị', adminOnly: true),
];

/// Adaptive shell: NavigationRail on wide (kiosk/desktop), NavigationBar on
/// narrow (mobile). Destinations are filtered by role.
///
/// **Role-based filtering (FRONTEND.md §3):**
/// - OPERATOR: Tra cứu + Snap & Ask (mobile) + Tài liệu (SOP/Safety filtered in list)
/// - ENGINEER: All non-admin screens
/// - QA_ADMIN / ADMIN: All screens including admin panel
class HomeShell extends ConsumerWidget {
  const HomeShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final role = auth.user?.role;
    final isAdmin = role?.isAdminLevel ?? false;
    final isWide = Responsive.isWide(context);

    // Filter destinations based on role.
    final dests = _allDestinations.where((d) {
      // Admin-only screens need admin role.
      if (d.adminOnly && !isAdmin) return false;
      return true;
    }).toList();

    final location = GoRouterState.of(context).matchedLocation;
    var index = dests.indexWhere((d) => location.startsWith(d.path));
    if (index < 0) index = 0;

    void onSelect(int i) => context.go(dests[i].path);
    void logout() => ref.read(authControllerProvider.notifier).logout();

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: onSelect,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in dests)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    label: Text(d.label),
                  ),
              ],
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (role != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Chip(
                              label: Text(role.label),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        IconButton(
                          tooltip: 'Đăng xuất',
                          icon: const Icon(Icons.logout),
                          onPressed: logout,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onSelect,
        destinations: [
          for (final d in dests)
            NavigationDestination(icon: Icon(d.icon), label: d.label),
        ],
      ),
    );
  }
}
