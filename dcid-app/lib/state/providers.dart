import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/api_client.dart';
import '../data/auth_repository.dart';
import '../data/docs_repository.dart';

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

final docsRepositoryProvider =
    Provider<DocsRepository>((ref) => DocsRepository(ref.watch(apiClientProvider)));
