/// Một mục trong lịch sử câu hỏi của user, từ `GET /api/query/history`.
class QueryHistoryItem {
  const QueryHistoryItem({
    required this.id,
    required this.question,
    required this.createdAt,
    this.answerPreview,
    this.confidence,
    this.locked = false,
    this.numericRuleHit = false,
    this.latencyMs,
    this.feedback,
  });

  final String id;
  final String question;
  final String? answerPreview;
  final double? confidence;
  final bool locked;
  final bool numericRuleHit;
  final int? latencyMs;
  final DateTime createdAt;

  /// Feedback của user: 1 = helpful, -1 = not helpful, null = chưa feedback.
  final int? feedback;

  factory QueryHistoryItem.fromJson(Map<String, dynamic> json) {
    return QueryHistoryItem(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      answerPreview: json['answerPreview'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      locked: json['locked'] == true,
      numericRuleHit: json['numericRuleHit'] == true,
      latencyMs: (json['latencyMs'] as num?)?.toInt(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String).toLocal()
          : DateTime.now(),
      feedback: (json['feedback'] as num?)?.toInt(),
    );
  }
}
