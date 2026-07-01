import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/kiosk.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // On Windows (kiosk) this will configure fullscreen; no-op elsewhere.
  await configureKioskIfDesktop();
  runApp(const ProviderScope(child: DcidApp()));
}
