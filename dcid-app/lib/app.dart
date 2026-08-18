import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/localization/locale_controller.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'state/theme_controller.dart';

/// Root widget. Wires the go_router instance (which reacts to auth state)
/// into a Material 3 app with the DCID Industrial dual theme.
class DcidApp extends ConsumerWidget {
  const DcidApp({super.key});

  static final _lightTheme = buildAppTheme();
  static final _darkTheme = buildDarkAppTheme();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'DCID: Digital Cognitive InDustrial System',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: themeMode,
      locale: currentLocale.flutterLocale,
      // Instant theme toggle to eliminate GPU lag
      themeAnimationDuration: Duration.zero,
      routerConfig: router,
    );
  }
}
