import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../state/auth_controller.dart';
import '../../state/theme_controller.dart';

class _Dest {
  const _Dest(this.icon, this.label, {this.adminOnly = false});
  final IconData icon;
  final String label;
  final bool adminOnly;
}

/// Branch ordering must stay in sync with [routerProvider] in router.dart:
///   index 0 = /search, 1 = /snap, 2 = /documents, 3 = /admin
const _allDestinations = <_Dest>[
  _Dest(Icons.search_rounded, 'Search'),
  _Dest(Icons.camera_alt_rounded, 'Snap & Ask'),
  _Dest(Icons.folder_rounded, 'Documents'),
  _Dest(Icons.admin_panel_settings_rounded, 'Admin', adminOnly: true),
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

    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    // Build parallel lists: visible destinations and their true branch indices.
    final dests = <_Dest>[];
    final branchIndices = <int>[];
    for (var i = 0; i < _allDestinations.length; i++) {
      final d = _allDestinations[i];
      if (!(d.adminOnly && !isAdmin)) {
        dests.add(d);
        branchIndices.add(i);
      }
    }

    final currentBranch = navigationShell.currentIndex;
    final navIndex = branchIndices.contains(currentBranch)
        ? branchIndices.indexOf(currentBranch)
        : 0;

    void onSelect(int i) => navigationShell.goBranch(
          branchIndices[i],
          initialLocation: currentBranch == branchIndices[i],
        );

    void logout() => ref.read(authControllerProvider.notifier).logout();

    void toggleTheme() =>
        ref.read(themeModeProvider.notifier).toggle();

    final themeToggleButton = IconButton(
      tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) => RotationTransition(
          turns: anim,
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          key: ValueKey(isDark),
        ),
      ),
      onPressed: toggleTheme,
    );

    // ── Wide layout: NavigationRail + content ─────────────────────────────
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
                        themeToggleButton,
                        const SizedBox(height: 4),
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
                          icon: const Icon(Icons.logout_rounded),
                          onPressed: logout,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    // ── Narrow layout: AppBar + BottomNavigationBar ───────────────────────
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.precision_manufacturing_rounded,
                size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            const Text(
              'Smart KCN Docs',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ],
        ),
        actions: [
          themeToggleButton,
          if (role != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Chip(
                  label: Text(role.label, style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: logout,
          ),
        ],
      ),
      body: SafeArea(
        child: navigationShell,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navIndex,
        onDestinationSelected: onSelect,
        destinations: [
          for (final d in dests)
            NavigationDestination(
              icon: Icon(d.icon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
