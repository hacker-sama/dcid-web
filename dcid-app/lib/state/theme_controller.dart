import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod provider that holds and toggles the app [ThemeMode].
///
/// Defaults to [ThemeMode.system] so the app follows OS preference on first
/// launch. Tapping the theme toggle button calls [toggle] to switch between
/// explicit [ThemeMode.light] and [ThemeMode.dark].
class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  /// Cycle accurately from System -> Light/Dark based on current platform brightness
  void toggle() {
    final isPlatformDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    
    state = (state == ThemeMode.dark ||
            (state == ThemeMode.system && isPlatformDark))
        ? ThemeMode.light
        : ThemeMode.dark;
  }

  /// Force a specific mode.
  void setMode(ThemeMode mode) => state = mode;
}

/// Global theme mode provider. Watch this in [DcidApp] and any widget that
/// needs to know the current mode (e.g., to render the correct toggle icon).
final themeModeProvider =
    NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);
