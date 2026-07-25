/// One source reference returned with an answer (page + optional bbox crop + snippet text).
class Citation {
  const Citation({required this.versionId, required this.pageNo, this.bboxKey, this.snippet});

  final String versionId;
  final int pageNo;
  final String? bboxKey;
  final String? snippet;

  factory Citation.fromJson(Map<String, dynamic> json) => Citation(
        versionId: json['versionId'] as String? ?? '',
        pageNo: (json['pageNo'] as num?)?.toInt() ?? 0,
        bboxKey: json['bboxKey'] as String?,
        snippet: json['snippet'] as String?,
      );
}

/// Result of `POST /api/query` (RAG + guardrails).
class AnswerResult {
  const AnswerResult({
    required this.answer,
    required this.confidence,
    required this.locked,
    required this.numericRule,
    this.reasoningMode = false,
    required this.citations,
  });

  final String answer;
  final double confidence;

  /// Guardrail locked the generated answer (cosine < threshold).
  final bool locked;

  /// Answer came from rule-based numeric extraction (không do LLM sinh).
  final bool numericRule;

  /// Answer came from reasoning / assembly procedure mode.
  final bool reasoningMode;
  final List<Citation> citations;

  factory AnswerResult.fromJson(Map<String, dynamic> json) {
    final guard = json['guard'] as Map<String, dynamic>? ?? const {};
    final citations = (json['citations'] as List<dynamic>? ?? const [])
        .map((e) => Citation.fromJson(e as Map<String, dynamic>))
        .toList();
    return AnswerResult(
      answer: json['answer'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      locked: guard['locked'] as bool? ?? false,
      numericRule: guard['numericRule'] as bool? ?? false,
      reasoningMode: guard['reasoningMode'] as bool? ?? false,
      citations: citations,
    );
  }
}
