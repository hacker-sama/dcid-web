/// A document as listed by `GET /api/documents` (docs/PLAN-FLUTTER-DOCS.md §3.1).
class DocumentSummary {
  const DocumentSummary({
    required this.id,
    required this.title,
    this.machineCode,
    this.category,
    this.minRole,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String? machineCode;
  final String? category;
  final String? minRole;
  final String? description;
  final String? createdAt;
  final String? updatedAt;

  factory DocumentSummary.fromJson(Map<String, dynamic> json) => DocumentSummary(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        machineCode: json['machineCode'] as String?,
        category: json['category'] as String?,
        minRole: json['minRole'] as String?,
        description: json['description'] as String?,
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
      );
}
