import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/api_client.dart';
import '../data/auth_repository.dart';
import '../data/docs_repository.dart';
import '../data/docs_repository_interface.dart';

final secureStorageProvider =
    Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

final apiClientProvider =
    Provider<ApiClient>((ref) => ApiClient(ref.watch(secureStorageProvider)));

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  ),
);

/// Document operations. Override with `MockDocsRepository` during Week 1:
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     docsRepositoryProvider.overrideWithValue(MockDocsRepository()),
///   ],
///   child: const DcidApp(),
/// )
/// ```
final docsRepositoryProvider =
    Provider<IDocsRepository>((ref) => DocsRepository(ref.watch(apiClientProvider)));
