import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/kiosk.dart';
import 'data/mock/mock_auth_repository.dart';
import 'data/mock/mock_docs_repository.dart';
import 'state/providers.dart';

/// Real backend/AI is the default. Enable mock data explicitly only for
/// isolated UI development with `--dart-define=USE_MOCK_DATA=true`.
const bool _useMockData = bool.fromEnvironment(
  'USE_MOCK_DATA',
  defaultValue: false,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error boundary handling
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Global UI Error: ${details.exception}\n${details.stack}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Global Async Error: $error\n$stack');
    return true;
  };

  // On Windows (kiosk) this will configure fullscreen; no-op elsewhere.
  await configureKioskIfDesktop();

  runApp(
    ProviderScope(
      overrides: [
        if (_useMockData) ...[
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
          docsRepositoryProvider.overrideWithValue(MockDocsRepository()),
        ],
      ],
      child: const DcidApp(),
    ),
  );
}
