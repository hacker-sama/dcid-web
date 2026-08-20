import 'answer_result.dart';

enum SseEventType { meta, delta, done, error }

class SseEvent {
  const SseEvent({
    required this.type,
    this.textDelta,
    this.citations = const [],
    this.locked = false,
    this.numericRule = false,
    this.reasoningMode = false,
    this.confidence = 0.0,
    this.latencyMs,
    this.queryLogId,
    this.errorMessage,
  });

  final SseEventType type;
  final String? textDelta;
  final List<Citation> citations;
  final bool locked;
  final bool numericRule;
  final bool reasoningMode;
  final double confidence;
  final int? latencyMs;
  final String? queryLogId;
  final String? errorMessage;
}
