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

  Map<String, dynamic> toJson() => {
        'versionId': versionId,
        'pageNo': pageNo,
        'bboxKey': bboxKey,
        'snippet': snippet,
      };
}

/// Result of `POST /api/query` (RAG + guardrails).
class AnswerResult {
  const AnswerResult({
    required this.answer,
    required this.confidence,
    required this.locked,
    required this.numericRule,
    this.reasoningMode = false,
    this.isOfflineFallback = false,
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

  /// True when backend/AI network request failed and fallback response is returned.
  final bool isOfflineFallback;
  final List<Citation> citations;

  factory AnswerResult.fromJson(Map<String, dynamic> json) {
    final guard = (json['guard'] as Map<String, dynamic>?) ?? const {};

    bool parseBool(dynamic val) {
      if (val is bool) return val;
      if (val is String) return val.toLowerCase() == 'true';
      return false;
    }

    final citations = (json['citations'] as List<dynamic>? ?? const [])
        .map((e) => Citation.fromJson(e as Map<String, dynamic>))
        .toList();

    return AnswerResult(
      answer: json['answer'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      locked: parseBool(json['locked'] ?? guard['locked']),
      numericRule: parseBool(json['numericRule'] ?? guard['numericRule']),
      reasoningMode: parseBool(json['reasoningMode'] ?? guard['reasoningMode']),
      isOfflineFallback: parseBool(json['isOfflineFallback']),
      citations: citations,
    );
  }

  Map<String, dynamic> toJson() => {
        'answer': answer,
        'confidence': confidence,
        'citations': citations.map((c) => c.toJson()).toList(),
        'guard': {
          'locked': locked,
          'numericRule': numericRule,
          'reasoningMode': reasoningMode,
        },
        'isOfflineFallback': isOfflineFallback,
      };
}
