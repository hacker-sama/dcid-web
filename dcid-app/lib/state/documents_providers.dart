import 'dart:async';
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
/// Nếu có version đang ở trạng thái PROCESSING hoặc INGESTING, tự động poll mỗi 3 giây
/// cho đến khi xử lý xong (ACTIVE/READY/FAILED).
final documentDetailProvider = FutureProvider.autoDispose
    .family<DocumentDetail, String>((ref, id) async {
  final detail = await ref.watch(docsRepositoryProvider).getDocumentDetail(id);
  final isProcessing = detail.versions.any(
    (v) => v.status == 'PROCESSING' || v.status == 'INGESTING',
  );
  if (isProcessing) {
    final timer = Timer(const Duration(seconds: 3), () {
      ref.invalidateSelf();
    });
    ref.onDispose(() => timer.cancel());
  }
  return detail;
});
