import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/language_toggle_button.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/responsive.dart';
import '../../state/auth_controller.dart';
import '../../state/theme_controller.dart';
import 'widgets/collapsible_sidebar.dart';

class _Dest {
  const _Dest(this.icon, this.labelKey, {this.adminOnly = false});
  final IconData icon;
  final String Function(dynamic strings) labelKey;
  final bool adminOnly;
}

/// Branch ordering must stay in sync with [routerProvider] in router.dart:
///   index 0 = /search, 1 = /snap, 2 = /documents, 3 = /admin
final _allDestinations = <_Dest>[
  _Dest(Icons.construction_rounded, (s) => s.navDocuMind as String),
  _Dest(Icons.camera_alt_rounded, (s) => s.navSnapAsk as String),
  _Dest(Icons.folder_rounded, (s) => s.navDocuments as String),
  _Dest(Icons.admin_panel_settings_rounded, (s) => s.navAdmin as String, adminOnly: true),
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
    final strings = ref.watch(appStringsProvider);
    final role = auth.user?.role;
    final isAdmin = role?.isAdminLevel ?? false;
    final isWide = Responsive.isWide(context);

    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    // Build parallel lists: visible destinations and their true branch indices.
    final dests = <ShellDestination>[];
    final branchIndices = <int>[];
    for (var i = 0; i < _allDestinations.length; i++) {
      final d = _allDestinations[i];
      if (!(d.adminOnly && !isAdmin)) {
        dests.add(ShellDestination(d.icon, d.labelKey(strings)));
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
      tooltip: isDark ? strings.switchToLight : strings.switchToDark,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
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
            RepaintBoundary(
              child: CollapsibleSidebar(
                selectedIndex: navIndex,
                onDestinationSelected: onSelect,
                destinations: dests,
                themeToggleButton: themeToggleButton,
                onLogout: logout,
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: RepaintBoundary(
                child: navigationShell,
              ),
            ),
          ],
        ),
      );
    }

    // ── Narrow layout: AppBar + BottomNavigationBar ───────────────────────
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.precision_manufacturing_rounded,
                  size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '${strings.appTitle} ${strings.appSubtitle}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ],
          ),
        ),
        actions: [
          // Lịch sử câu hỏi
          IconButton(
            tooltip: strings.historyTooltip,
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.push('/history'),
          ),
          const LanguageToggleButton(),
          themeToggleButton,
          if (role != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Chip(
                  label: Text(role.localized(strings), style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          // User avatar → Profile
          IconButton(
            tooltip: strings.profileTooltip,
            icon: _UserAvatar(name: auth.user?.fullName ?? auth.user?.username),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            tooltip: strings.logoutTooltip,
            icon: const Icon(Icons.logout_rounded),
            onPressed: logout,
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: CollapsibleSidebar(
            forceExpanded: true,
            selectedIndex: navIndex,
            onDestinationSelected: (i) {
              onSelect(i);
              Navigator.of(context).pop(); // Close drawer
            },
            destinations: dests,
            themeToggleButton: themeToggleButton,
            onLogout: logout,
          ),
        ),
      ),
      body: SafeArea(
        child: RepaintBoundary(
          child: navigationShell,
        ),
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

/// Avatar tròn hiển thị 1-2 chữ cái đầu tên user.
class _UserAvatar extends StatelessWidget {
  const _UserAvatar({this.name});
  final String? name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = _initials(name ?? '?');
    return CircleAvatar(
      radius: 13,
      backgroundColor: scheme.primaryContainer,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }
}
