import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/document_detail.dart';
import '../data/models/document_summary.dart';
import 'providers.dart';

/// Danh sách tài liệu (`GET /api/documents`). Refresh bằng
/// `ref.invalidate(documentsProvider)` hoặc `ref.refresh(documentsProvider.future)`.
final documentsProvider =
    AsyncNotifierProvider<DocumentsController, List<DocumentSummary>>(
        DocumentsController.new);

class DocumentsController extends AsyncNotifier<List<DocumentSummary>> {
  @override
  Future<List<DocumentSummary>> build() =>
      ref.watch(docsRepositoryProvider).listDocuments();
}

/// Chi tiết một tài liệu (`GET /api/documents/{id}`), keyed theo documentId.
final documentDetailProvider = FutureProvider.autoDispose
    .family<DocumentDetail, String>(
        (ref, id) => ref.watch(docsRepositoryProvider).getDocumentDetail(id));
