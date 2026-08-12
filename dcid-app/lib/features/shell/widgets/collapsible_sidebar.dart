import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/responsive.dart';
import '../../../state/auth_controller.dart';
import '../../../state/chat_sessions_provider.dart';

class ShellDestination {
  final IconData icon;
  final String label;

  const ShellDestination(this.icon, this.label);
}

class CollapsibleSidebar extends ConsumerWidget {
  const CollapsibleSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.themeToggleButton,
    required this.onLogout,
    this.forceExpanded,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<ShellDestination> destinations;
  final Widget themeToggleButton;
  final VoidCallback onLogout;
  final bool? forceExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isExpanded = forceExpanded ?? ref.watch(isSidebarExpandedProvider);
    final colorScheme = Theme.of(context).colorScheme;
    // Narrowly watch only the user's role — avoids rebuilds on token refresh
    final role = ref.watch(authControllerProvider.select((a) => a.user?.role));
    final sessions = ref.watch(chatSessionsProvider);
    final activeSessionId = ref.watch(activeChatSessionIdProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: isExpanded ? 260.0 : 68.0,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          InkWell(
            onTap: () {
              if (!Responsive.isWide(context)) {
                // On mobile, just navigate to new chat and close drawer
                ref.read(activeChatSessionIdProvider.notifier).setId(null);
                if (selectedIndex != 0) {
                  onDestinationSelected(0);
                } else {
                  Navigator.of(context).pop();
                }
                return;
              }

              if (isExpanded) {
                ref.read(isSidebarExpandedProvider.notifier).toggle();
              } else {
                ref.read(activeChatSessionIdProvider.notifier).setId(null);
                if (selectedIndex != 0) {
                  onDestinationSelected(0);
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.precision_manufacturing_rounded,
                    size: 28,
                    color: colorScheme.primary,
                  ),
                  if (isExpanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart KCN',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              height: 1.1,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Docs',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // New Chat Button
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: FilledButton.icon(
                onPressed: () {
                  ref.read(activeChatSessionIdProvider.notifier).setId(null);
                  // Navigate to search if not already there (index 0)
                  if (selectedIndex != 0) {
                    onDestinationSelected(0);
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('New Chat', style: TextStyle(fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            )
          else
            IconButton(
              onPressed: () {
                ref.read(activeChatSessionIdProvider.notifier).setId(null);
                if (selectedIndex != 0) {
                  onDestinationSelected(0);
                }
              },
              icon: const Icon(Icons.add_rounded),
              tooltip: 'New Chat',
            ),

          // Recents List (Expanded only)
          if (isExpanded && sessions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Recents',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            RepaintBoundary(
              child: Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  // itemExtent enables O(1) scroll position calc
                  itemExtent: 44.0,
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final isActive = session.id == activeSessionId;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      dense: true,
                      title: Text(
                        session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive ? colorScheme.primary : colorScheme.onSurface,
                        ),
                      ),
                      selected: isActive,
                      selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
                      onTap: () {
                        ref.read(activeChatSessionIdProvider.notifier).setId(session.id);
                        if (selectedIndex != 0) {
                          onDestinationSelected(0);
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ] else if (isExpanded)
            const Expanded(child: SizedBox())
          else
            const Spacer(),

          // Navigation Items (Middle-bottom)
          RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: List.generate(destinations.length, (index) {
                  final dest = destinations[index];
                  final isSelected = selectedIndex == index;
                  if (!isExpanded) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: IconButton(
                        onPressed: () => onDestinationSelected(index),
                        icon: Icon(dest.icon),
                        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        tooltip: dest.label,
                      ),
                    );
                  }
                  return ListTile(
                    leading: Icon(
                      dest.icon,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      dest.label,
                      style: TextStyle(
                        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    onTap: () => onDestinationSelected(index),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    horizontalTitleGap: 8,
                  );
                }),
              ),
            ),
          ),

          const Divider(height: 1),

          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                if (isExpanded)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      themeToggleButton,
                      if (role != null)
                        Chip(
                          label: Text(
                            role.label,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      IconButton(
                        tooltip: 'Logout',
                        icon: const Icon(Icons.logout_rounded),
                        onPressed: onLogout,
                      ),
                      IconButton(
                        tooltip: 'Collapse sidebar',
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () {
                          if (!Responsive.isWide(context)) {
                            Navigator.of(context).pop();
                          } else {
                            ref.read(isSidebarExpandedProvider.notifier).toggle();
                          }
                        },
                      ),
                    ],
                  )
                else ...[
                  themeToggleButton,
                  IconButton(
                    tooltip: 'Logout',
                    icon: const Icon(Icons.logout_rounded),
                    onPressed: onLogout,
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    tooltip: 'Expand sidebar',
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () {
                      ref.read(isSidebarExpandedProvider.notifier).toggle();
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
