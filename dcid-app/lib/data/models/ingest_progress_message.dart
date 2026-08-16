class IngestProgressMessage {
  const IngestProgressMessage({
    required this.versionId,
    required this.step,
    required this.progress,
    required this.message,
  });

  factory IngestProgressMessage.fromJson(Map<String, dynamic> json) {
    return IngestProgressMessage(
      versionId: json['versionId']?.toString() ?? '',
      step: json['step']?.toString() ?? 'PROCESSING',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      message: json['message']?.toString() ?? '',
    );
  }

  final String versionId;
  final String step;
  final int progress;
  final String message;

  bool get isDone => step == 'READY' || progress >= 100;
  bool get isFailed => step == 'FAILED';
}
