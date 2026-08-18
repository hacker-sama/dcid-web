/// Một bản ghi phản hồi (feedback) từ người dùng cho Admin.
class FeedbackAdminItem {
  const FeedbackAdminItem({
    required this.id,
    required this.question,
    required this.createdAt,
    this.actorId,
    this.actorUsername = 'Guest',
    this.answerPreview,
    this.confidence,
    this.locked = false,
    this.feedback,
    this.feedbackNote,
    this.feedbackAt,
  });

  final String id;
  final String? actorId;
  final String actorUsername;
  final String question;
  final String? answerPreview;
  final double? confidence;
  final bool locked;
  final int? feedback;
  final String? feedbackNote;
  final DateTime? feedbackAt;
  final DateTime createdAt;

  factory FeedbackAdminItem.fromJson(Map<String, dynamic> json) {
    return FeedbackAdminItem(
      id: json['id'] as String? ?? '',
      actorId: json['actorId'] as String?,
      actorUsername: json['actorUsername'] as String? ?? 'Guest',
      question: json['question'] as String? ?? '',
      answerPreview: json['answerPreview'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      locked: json['locked'] == true,
      feedback: (json['feedback'] as num?)?.toInt(),
      feedbackNote: json['feedbackNote'] as String?,
      feedbackAt: json['feedbackAt'] != null
          ? DateTime.parse(json['feedbackAt'] as String).toLocal()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String).toLocal()
          : DateTime.now(),
    );
  }
}
