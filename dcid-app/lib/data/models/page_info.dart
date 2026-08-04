/// Page image metadata from the ingest callback (`API-CONTRACT.md` §1.2).
class PageInfo {
  const PageInfo({
    required this.pageNo,
    required this.imageKey,
    this.width,
    this.height,
    this.ocrText,
  });

  final int pageNo;

  /// MinIO key, e.g. `documents/{docId}/v1/pages/1.png`.
  final String imageKey;

  /// Original page pixel width (from OCR/render).
  final int? width;

  /// Original page pixel height (from OCR/render).
  final int? height;

  final String? ocrText;

  factory PageInfo.fromJson(Map<String, dynamic> json) => PageInfo(
        pageNo: (json['pageNo'] as num?)?.toInt() ?? 0,
        imageKey: json['imageKey'] as String? ?? '',
        width: (json['width'] as num?)?.toInt(),
        height: (json['height'] as num?)?.toInt(),
        ocrText: json['ocrText'] as String?,
      );
}

/// A bounding box overlay for a specific area on a page.
///
/// Coordinates are **normalized** (0.0–1.0) relative to the page's
/// `width` × `height`. The viewer scales them to the display size:
///
/// ```
/// displayX = bbox.x * displayWidth
/// displayY = bbox.y * displayHeight
/// displayW = bbox.width * displayWidth
/// displayH = bbox.height * displayHeight
/// ```
class BoundingBox {
  const BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.label,
  });

  /// Left edge, 0.0–1.0.
  final double x;

  /// Top edge, 0.0–1.0.
  final double y;

  /// Box width, 0.0–1.0.
  final double width;

  /// Box height, 0.0–1.0.
  final double height;

  /// Optional label (e.g. snippet preview) shown near the box.
  final String? label;

  factory BoundingBox.fromJson(Map<String, dynamic> json) => BoundingBox(
        x: (json['x'] as num?)?.toDouble() ?? 0,
        y: (json['y'] as num?)?.toDouble() ?? 0,
        width: (json['width'] as num?)?.toDouble() ?? 0,
        height: (json['height'] as num?)?.toDouble() ?? 0,
        label: json['label'] as String?,
      );
}
