class CreateSessionData {
  CreateSessionData({
    required this.sessionId,
    required this.sessionToken,
    required this.expiresAt,
  });

  final String sessionId;
  final String sessionToken;
  final DateTime expiresAt;

  factory CreateSessionData.fromJson(Map<String, dynamic> json) {
    return CreateSessionData(
      sessionId: json['sessionId'] as String? ?? '',
      sessionToken: json['sessionToken'] as String? ?? '',
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : DateTime.now().add(const Duration(hours: 2)),
    );
  }
}

class GuestDocumentItem {
  GuestDocumentItem({
    required this.id,
    required this.sessionId,
    required this.originalFilename,
    required this.fileSize,
    required this.status,
    this.pageCount,
    this.errorMessage,
    required this.createdAt,
  });

  final String id;
  final String sessionId;
  final String originalFilename;
  final int fileSize;
  final String status;
  final int? pageCount;
  final String? errorMessage;
  final DateTime createdAt;

  factory GuestDocumentItem.fromJson(Map<String, dynamic> json) {
    return GuestDocumentItem(
      id: json['id'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      originalFilename: json['originalFilename'] as String? ?? 'tài_liệu.pdf',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'PROCESSING',
      pageCount: (json['pageCount'] as num?)?.toInt(),
      errorMessage: json['errorMessage'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  bool get isReady => status == 'READY' || status == 'ACTIVE';
  bool get isFailed => status == 'FAILED';
  bool get isProcessing => status == 'PROCESSING';
}

class GuestSessionData {
  GuestSessionData({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.documentCount,
    required this.totalSize,
    required this.documents,
  });

  final String id;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int documentCount;
  final int totalSize;
  final List<GuestDocumentItem> documents;

  factory GuestSessionData.fromJson(Map<String, dynamic> json) {
    final docs = (json['documents'] as List<dynamic>? ?? [])
        .map((e) => GuestDocumentItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return GuestSessionData(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : DateTime.now().add(const Duration(hours: 2)),
      documentCount: (json['documentCount'] as num?)?.toInt() ?? 0,
      totalSize: (json['totalSize'] as num?)?.toInt() ?? 0,
      documents: docs,
    );
  }
}
