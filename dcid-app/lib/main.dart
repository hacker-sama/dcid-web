import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/kiosk.dart';
import 'data/mock/mock_auth_repository.dart';
import 'data/mock/mock_docs_repository.dart';
import 'state/providers.dart';

/// Set to `true` during Week 1 (APIs not ready) to use mock data.
/// Flip to `false` when the real backend is available — zero other
/// code changes required.
const bool _useMockData = bool.fromEnvironment(
  'USE_MOCK_DATA',
  defaultValue: true,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
