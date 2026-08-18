import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_locale.dart';
import 'locale_controller.dart';

/// Interactive button with a Dropdown Menu for selecting language between:
/// - 🇻🇳 Tiếng Việt (VI)
/// - 🇺🇸 English (EN)
/// - 🇮🇳 हिन्दी (HI)
/// - 🇯🇵 日本語 (JA)
///
/// Supports both compact icon badge mode and expanded pill mode.
class LanguageToggleButton extends ConsumerWidget {
  const LanguageToggleButton({
    super.key,
    this.compact = true,
    this.foregroundColor,
  });

  /// If true, renders a compact badge with globe icon and shortCode (e.g. `[ 🌐 VI ]`).
  /// If false, renders a pill button showing current language name with a dropdown arrow.
  final bool compact;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final strings = ref.watch(appStringsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    final primaryColor = foregroundColor ?? colorScheme.primary;

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark
                  ? Colors.white12
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          elevation: 8,
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
        ),
      ),
      child: PopupMenuButton<AppLocale>(
        tooltip: strings.switchLanguage,
        initialValue: currentLocale,
        onSelected: (AppLocale selected) {
          ref.read(localeProvider.notifier).setLocale(selected);
        },
        offset: const Offset(0, 42),
        itemBuilder: (BuildContext context) {
          return AppLocale.values.map((AppLocale locale) {
            final isSelected = locale == currentLocale;
            return PopupMenuItem<AppLocale>(
              value: locale,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Text(
                    locale.flag,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          locale.displayName,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? primaryColor : colorScheme.onSurface,
                          ),
                        ),
                        if (locale.englishName != locale.displayName)
                          Text(
                            locale.englishName,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: primaryColor,
                    )
                  else
                    SizedBox.square(
                      dimension: 18,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList();
        },
        child: compact
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentLocale.flag,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          currentLocale.shortCode,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: foregroundColor ?? colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 16,
                          color: primaryColor.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                  color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.35),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentLocale.flag,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currentLocale.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
