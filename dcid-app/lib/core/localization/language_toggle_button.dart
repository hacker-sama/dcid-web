import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_locale.dart';
import 'locale_controller.dart';

/// Interactive button for switching language between Vietnamese (VI) and English (EN).
/// Supports both icon-only (compact) mode and label mode with smooth micro-animations.
class LanguageToggleButton extends ConsumerWidget {
  const LanguageToggleButton({
    super.key,
    this.compact = true,
    this.foregroundColor,
  });

  /// If true, renders a compact icon button with a mini language badge.
  /// If false, renders a pill button showing the full current language name.
  final bool compact;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isVi = locale == AppLocale.vi;

    final targetLanguage = isVi ? 'English' : 'Tiếng Việt';
    final tooltip = isVi
        ? 'Chuyển sang $targetLanguage'
        : 'Switch to $targetLanguage';

    if (compact) {
      return IconButton(
        tooltip: tooltip,
        onPressed: () => ref.read(localeProvider.notifier).toggle(),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: anim,
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Container(
            key: ValueKey(locale),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: (foregroundColor ?? colorScheme.onSurfaceVariant)
                    .withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.translate_rounded,
                  size: 14,
                  color: foregroundColor ?? colorScheme.primary,
                ),
                const SizedBox(width: 3),
                Text(
                  locale.shortCode,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: foregroundColor ?? colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Expanded / pill style
    return InkWell(
      onTap: () => ref.read(localeProvider.notifier).toggle(),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
          color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language_rounded,
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              locale.displayName,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.swap_horiz_rounded,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
