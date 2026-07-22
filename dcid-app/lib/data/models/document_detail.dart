import 'document_summary.dart';

/// `GET /api/documents/{id}` → `data` (docs/PLAN-FLUTTER-DOCS.md §3.2).
class DocumentDetail {
  const DocumentDetail({required this.document, required this.versions});

  final DocumentSummary document;
  final List<VersionSummary> versions;

  factory DocumentDetail.fromJson(Map<String, dynamic> json) => DocumentDetail(
        document:
            DocumentSummary.fromJson(json['document'] as Map<String, dynamic>),
        versions: (json['versions'] as List<dynamic>? ?? const [])
            .map((e) => VersionSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// One version of a document. `pageCount`/`ingestedAt`/`lang` are null while
/// the version is still PROCESSING.
class VersionSummary {
  const VersionSummary({
    required this.id,
    required this.versionNo,
    required this.status,
    this.lang,
    this.pageCount,
    this.originalFilename,
    this.fileSize,
    this.createdAt,
    this.ingestedAt,
  });

  final String id;
  final int versionNo;

  /// PROCESSING | READY | ACTIVE | SUPERSEDED | OBSOLETE | FAILED
  final String status;
  final String? lang;
  final int? pageCount;
  final String? originalFilename;
  final int? fileSize;
  final String? createdAt;
  final String? ingestedAt;

  factory VersionSummary.fromJson(Map<String, dynamic> json) => VersionSummary(
        id: json['id'] as String,
        versionNo: json['versionNo'] as int? ?? 0,
        status: json['status'] as String? ?? 'PROCESSING',
        lang: json['lang'] as String?,
        pageCount: json['pageCount'] as int?,
        originalFilename: json['originalFilename'] as String?,
        fileSize: json['fileSize'] as int?,
        createdAt: json['createdAt'] as String?,
        ingestedAt: json['ingestedAt'] as String?,
      );
}
