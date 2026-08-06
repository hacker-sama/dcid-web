import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../state/auth_controller.dart';

class _Dest {
  const _Dest(this.icon, this.label, {this.adminOnly = false});
  final IconData icon;
  final String label;
  final bool adminOnly;
}

/// Branch ordering must stay in sync with [routerProvider] in router.dart:
///   index 0 = /search, 1 = /snap, 2 = /documents, 3 = /admin
const _allDestinations = <_Dest>[
  _Dest(Icons.search, 'Lookup'),
  _Dest(Icons.camera_alt, 'Snap & Ask'),
  _Dest(Icons.folder, 'Documents'),
  _Dest(Icons.admin_panel_settings, 'Admin', adminOnly: true),
];

/// Adaptive shell: NavigationRail on wide (kiosk/desktop), NavigationBar on
/// narrow (mobile). Destinations are filtered by role.
///
/// Uses [StatefulNavigationShell] from [StatefulShellRoute.indexedStack] —
/// each branch is kept alive in an IndexedStack so tab state is preserved.
class HomeShell extends ConsumerWidget {
  const HomeShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final role = auth.user?.role;
    final isAdmin = role?.isAdminLevel ?? false;
    final isWide = Responsive.isWide(context);

    // Filter destinations by role. Indices stay aligned with branch indices
    // because admin is always the last entry in _allDestinations.
    final dests = _allDestinations
        .where((d) => !(d.adminOnly && !isAdmin))
        .toList();

    // Branch index (navigationShell.currentIndex) equals nav item index
    // because the filtered list preserves order and admin is last.
    final navIndex =
        navigationShell.currentIndex.clamp(0, dests.length - 1);

    // Tapping the active tab again resets to the branch root; tapping a
    // different tab resumes where the user left off.
    void onSelect(int i) => navigationShell.goBranch(
          i,
          initialLocation: navigationShell.currentIndex == i,
        );

    void logout() =>
        ref.read(authControllerProvider.notifier).logout();

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navIndex,
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
                          tooltip: 'Logout',
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
            // navigationShell IS the IndexedStack body — all branches alive.
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navIndex,
        onDestinationSelected: onSelect,
        destinations: [
          for (final d in dests)
            NavigationDestination(icon: Icon(d.icon), label: d.label),
        ],
      ),
    );
  }
}
