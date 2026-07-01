/// A document as listed by `GET /api/documents`.
class DocumentSummary {
  const DocumentSummary({
    required this.id,
    required this.title,
    this.machineCode,
    this.category,
  });

  final String id;
  final String title;
  final String? machineCode;
  final String? category;

  factory DocumentSummary.fromJson(Map<String, dynamic> json) => DocumentSummary(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        machineCode: json['machineCode'] as String?,
        category: json['category'] as String?,
      );
}
