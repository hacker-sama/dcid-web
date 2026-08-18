import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/language_toggle_button.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/responsive.dart';
import '../../../state/auth_controller.dart';
import '../../../state/chat_sessions_provider.dart';

class ShellDestination {
  final IconData icon;
  final String label;

  const ShellDestination(this.icon, this.label);
}

/// Sidebar that switches between two completely separate, fixed-width layouts:
///   - Collapsed (68 px): icon-only, no text, no overflow possible
///   - Expanded  (260 px): full label layout
///
/// Using [AnimatedCrossFade] instead of a single [AnimatedContainer] with
/// conditional children eliminates all intermediate-state overflow errors that
/// occurred when the width was animating but text widgets still occupied space.
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
    final bool isExpanded =
        forceExpanded ?? ref.watch(isSidebarExpandedProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final strings = ref.watch(appStringsProvider);
    final user = ref.watch(authControllerProvider).user;
    final sessions = ref.watch(chatSessionsProvider);
    final activeSessionId = ref.watch(activeChatSessionIdProvider);

    final sidebarDecoration = BoxDecoration(
      color: colorScheme.surface,
      border: Border(
        right: BorderSide(
          color: Theme.of(context).brightness == Brightness.light
              ? const Color(0xFFE5E7EB)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
    );

    // Shared callbacks
    void newChat() {
      ref.read(activeChatSessionIdProvider.notifier).setId(null);
      if (selectedIndex != 0) onDestinationSelected(0);
    }

    void expand() {
      if (!Responsive.isWide(context)) {
        Scaffold.of(context).openDrawer();
      } else {
        ref.read(isSidebarExpandedProvider.notifier).toggle();
      }
    }

    void collapse() {
      if (!Responsive.isWide(context)) {
        Navigator.of(context).pop();
      } else {
        ref.read(isSidebarExpandedProvider.notifier).toggle();
      }
    }

    void logoTap() {
      if (!Responsive.isWide(context)) {
        ref.read(activeChatSessionIdProvider.notifier).setId(null);
        if (selectedIndex != 0) {
          onDestinationSelected(0);
        } else {
          Navigator.of(context).pop();
        }
        return;
      }
      if (isExpanded) {
        collapse();
      } else {
        newChat();
      }
    }

    // COLLAPSED layout (68 px wide, icon-only, zero text)
    // Uses mainAxisAlignment: spaceBetween — no Spacer/Expanded needed,
    // so it works even when the parent provides unbounded height.
    Widget buildCollapsedChild(double totalHeight) => SizedBox(
      width: 68,
      height: totalHeight,
      child: OverflowBox(
        minWidth: 68,
        maxWidth: 68,
        minHeight: totalHeight,
        maxHeight: totalHeight,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
          // Top: logo + new-chat icon
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: logoTap,
                child: SizedBox(
                  height: 68,
                  child: Center(
                    child: Icon(
                      Icons.precision_manufacturing_rounded,
                      size: 28,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: newChat,
                icon: const Icon(Icons.add_rounded),
                tooltip: strings.newChat,
              ),
            ],
          ),
          // Bottom: nav icons + divider + footer
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(destinations.length, (index) {
                    final dest = destinations[index];
                    final isSelected = selectedIndex == index;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: IconButton(
                        onPressed: () => onDestinationSelected(index),
                        icon: Icon(dest.icon),
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        tooltip: dest.label,
                      ),
                    );
                  }),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (user != null)
                      IconButton(
                        tooltip: '${strings.profileTooltip} (${user.fullName ?? user.username})',
                        icon: CircleAvatar(
                          radius: 13,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            _initials(user.fullName ?? user.username),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        onPressed: () => context.push('/profile'),
                      ),
                    IconButton(
                      tooltip: strings.historyTooltip,
                      icon: const Icon(Icons.history_rounded),
                      onPressed: () => context.push('/history'),
                    ),
                    const LanguageToggleButton(),
                    themeToggleButton,
                    IconButton(
                      tooltip: strings.logoutTooltip,
                      icon: const Icon(Icons.logout_rounded),
                      onPressed: onLogout,
                    ),
                    IconButton(
                      tooltip: strings.expandSidebar,
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: expand,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ));

    // EXPANDED layout (260 px wide, full labels) — built with explicit height
    // so Expanded/flex children have bounded constraints.
    Widget buildExpandedChild(double totalHeight) => SizedBox(
      width: 260,
      height: totalHeight,
      child: OverflowBox(
        minWidth: 260,
        maxWidth: 260,
        minHeight: totalHeight,
        maxHeight: totalHeight,
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          InkWell(
            onTap: logoTap,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.precision_manufacturing_rounded,
                    size: 28,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.appTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            height: 1.1,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          strings.appSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FilledButton.icon(
              onPressed: newChat,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                strings.newChat,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),
          if (sessions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                strings.recents,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            Expanded(
              child: RepaintBoundary(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemExtent: 44.0,
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final isActive = session.id == activeSessionId;
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      dense: true,
                      title: Text(
                        session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isActive
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                      selected: isActive,
                      selectedTileColor: colorScheme.primaryContainer
                          .withValues(alpha: 0.5),
                      onTap: () {
                        ref
                            .read(activeChatSessionIdProvider.notifier)
                            .setId(session.id);
                        if (selectedIndex != 0) onDestinationSelected(0);
                      },
                    );
                  },
                ),
              ),
            ),
          ] else
            const Expanded(child: SizedBox()),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: List.generate(destinations.length, (index) {
                final dest = destinations[index];
                final isSelected = selectedIndex == index;
                return ListTile(
                  leading: Icon(
                    dest.icon,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    dest.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor:
                      colorScheme.primaryContainer.withValues(alpha: 0.3),
                  onTap: () => onDestinationSelected(index),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  horizontalTitleGap: 8,
                );
              }),
            ),
          ),
          if (user != null) ...[
            const Divider(height: 1),
            Tooltip(
              message: strings.profileMenuTooltip,
              child: ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    _initials(user.fullName ?? user.username),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                title: Text(
                  user.fullName ?? user.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                subtitle: Text(
                  user.role.localized(strings),
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                onTap: () => context.push('/profile'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ],
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: strings.historyTooltip,
                  icon: const Icon(Icons.history_rounded),
                  onPressed: () => context.push('/history'),
                ),
                const LanguageToggleButton(),
                themeToggleButton,
                IconButton(
                  tooltip: strings.logoutTooltip,
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: onLogout,
                ),
                IconButton(
                  tooltip: strings.collapseSidebar,
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: collapse,
                ),
              ],
            ),
          ),
        ],
      ),
    ));

    // AnimatedCrossFade between the two fixed layouts.
    // LayoutBuilder provides the finite height both children require so that
    // Spacer / Expanded / mainAxisAlignment: spaceBetween all work correctly.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: isExpanded ? 260.0 : 68.0,
      decoration: sidebarDecoration,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            return AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: ClipRect(child: buildCollapsedChild(h)),
              secondChild: ClipRect(child: buildExpandedChild(h)),
              alignment: Alignment.topCenter,
              sizeCurve: Curves.easeInOut,
              layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      key: bottomChildKey,
                      top: 0,
                      left: 0,
                      child: bottomChild,
                    ),
                    Positioned(
                      key: topChildKey,
                      top: 0,
                      left: 0,
                      child: topChild,
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
}
