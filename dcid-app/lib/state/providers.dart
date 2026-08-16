import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/api_client.dart';
import '../data/auth_repository.dart';
import '../data/auth_repository_interface.dart';
import '../data/docs_repository.dart';
import '../data/docs_repository_interface.dart';
import '../data/analytics_repository.dart';
import '../data/models/analytics_summary.dart';

import '../data/offline_cache_repository.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(ref.watch(secureStorageProvider));
  ref.onDispose(client.dispose);
  return client;
});

/// Auth operations. Override with `MockAuthRepository` during Week 1:
///
/// ```dart
/// authRepositoryProvider.overrideWithValue(MockAuthRepository()),
/// ```
final authRepositoryProvider = Provider<IAuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  ),
);

/// Document operations with local offline caching.
final docsRepositoryProvider = Provider<IDocsRepository>(
  (ref) => OfflineCacheDocsRepository(
    DocsRepository(ref.watch(apiClientProvider)),
    ref.watch(secureStorageProvider),
  ),
);

final analyticsRepositoryProvider = Provider<AnalyticsRepositoryInterface>(
  (ref) => AnalyticsRepository(ref.watch(apiClientProvider)),
);

final analyticsFutureProvider = FutureProvider.autoDispose<AnalyticsSummary>((ref) {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getAnalytics();
});
