import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constrained_content.dart';
import '../../data/models/answer_result.dart';
import '../../state/providers.dart';
import '../search/answer_view.dart';

/// A single captured/uploaded image entry in the Snap & Ask gallery.
class _SnapEntry {
  _SnapEntry({
    required this.bytes,
    required this.fileName,
    required this.capturedAt,
  });

  final Uint8List bytes;
  final String fileName;
  final DateTime capturedAt;
}

class SnapAskScreen extends ConsumerStatefulWidget {
  const SnapAskScreen({super.key});

  @override
  ConsumerState<SnapAskScreen> createState() => _SnapAskScreenState();
}

class _SnapAskScreenState extends ConsumerState<SnapAskScreen> {
  final _imagePicker = ImagePicker();
  final List<_SnapEntry> _snaps = [];
  bool _picking = false;
  bool _isAsking = false;
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _machineCodeController = TextEditingController();
  AnswerResult? _answer;
  List<Rect> _boundingBoxes = [];
  
  static final _locRegex = RegExp(r'\[LOC\]\s*\(([^,]+),([^)]+)\),\s*\(([^,]+),([^)]+)\)\s*\[/LOC\]');

  // ── Camera: chụp ảnh trực tiếp ────────────────────────────────────
  Future<void> _takePhoto() async {
    setState(() => _picking = true);
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      _addSnap(bytes, photo.name);
    } catch (_) {
      // Camera not available — silently ignore.
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  // ── Gallery/File: chọn ảnh từ thư viện hoặc máy tính ─────────────
  Future<void> _pickImage() async {
    setState(() => _picking = true);
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        _addSnap(bytes, image.name);
        return;
      }
    } catch (_) {
      // Fallback to file_picker on web/desktop
    }
    await _pickWithFilePicker();
    if (mounted) setState(() => _picking = false);
  }

  Future<void> _pickWithFilePicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    _addSnap(file.bytes!, file.name);
  }

  void _addSnap(Uint8List bytes, String fileName) {
    setState(() {
      _snaps.insert(
        0,
        _SnapEntry(
          bytes: bytes,
          fileName: fileName,
          capturedAt: DateTime.now(),
        ),
      );
    });
  }

  void _deleteSnap(int index) {
    setState(() => _snaps.removeAt(index));
  }

  Future<void> _askQuestion() async {
    if (_snaps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn hoặc chụp một ảnh trước')),
      );
      return;
    }
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _isAsking = true;
      _answer = null;
    });

    try {
      final repo = ref.read(docsRepositoryProvider);
      final entry = _snaps.first;
      final machineCode = _machineCodeController.text.trim();
      final rawAnswer = await repo.askWithImage(question, entry.bytes, entry.fileName, machineCode: machineCode.isNotEmpty ? machineCode : null);
      
      String cleanText = rawAnswer.answer;
      final matches = _locRegex.allMatches(cleanText);
      final List<Rect> parsedBoxes = [];
      for (final m in matches) {
        try {
          final x1 = double.parse(m.group(1)!);
          final y1 = double.parse(m.group(2)!);
          final x2 = double.parse(m.group(3)!);
          final y2 = double.parse(m.group(4)!);
          if (x1 < x2 && y1 < y2) {
             parsedBoxes.add(Rect.fromLTRB(x1, y1, x2, y2));
          }
        } catch (_) {}
      }
      cleanText = cleanText.replaceAll(_locRegex, '').trim();

      final finalAnswer = AnswerResult(
        answer: cleanText,
        confidence: rawAnswer.confidence,
        locked: rawAnswer.locked,
        numericRule: rawAnswer.numericRule,
        reasoningMode: rawAnswer.reasoningMode,
        citations: rawAnswer.citations,
      );

      setState(() {
        _answer = finalAnswer;
        _boundingBoxes = parsedBoxes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _isAsking = false);
    }
  }

  // ── Bottom sheet: chọn cách lấy ảnh ───────────────────────────────
  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Thêm ảnh thiết bị',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                const SizedBox(height: 16),
                if (!kIsWeb)
                  ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    tileColor: scheme.primaryContainer.withValues(alpha: 0.3),
                    leading: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(Icons.camera_alt, color: scheme.primary),
                    ),
                    title: const Text('Chụp ảnh'),
                    subtitle: const Text('Mở camera để chụp thiết bị'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.pop(ctx);
                      _takePhoto();
                    },
                  ),
                if (!kIsWeb) const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  tileColor: scheme.secondaryContainer.withValues(alpha: 0.3),
                  leading: CircleAvatar(
                    backgroundColor: scheme.secondaryContainer,
                    child:
                        Icon(Icons.photo_library, color: scheme.secondary),
                  ),
                  title: Text(kIsWeb ? 'Chọn ảnh từ máy tính' : 'Chọn từ thư viện'),
                  subtitle: Text(kIsWeb
                      ? 'Tải lên tệp ảnh từ máy tính'
                      : 'Chọn ảnh có sẵn trên thiết bị'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage();
                  },
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Full-screen image preview dialog ──────────────────────────────
  void _showPreview(_SnapEntry snap) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: Center(
                child: CustomPaint(
                  foregroundPainter: _BBoxPainter(_boundingBoxes),
                  child: Image.memory(snap.bytes),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton.filled(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ConstrainedContent(
      maxWidth: 840,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── HEADER: Capture Zone ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _CaptureHeader(
              onAdd: _showImageSourcePicker,
              loading: _picking,
              snapCount: _snaps.length,
              scheme: scheme,
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),

          // ── BODY: Snap list ────────────────────────────────────────────
          Expanded(
            child: _snaps.isEmpty
                ? _EmptyState(onAdd: _showImageSourcePicker, scheme: scheme)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: _snaps.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final snap = _snaps[index];
                      return _SnapCard(
                        snap: snap,
                        index: index,
                        formatDate: _formatDate,
                        onPreview: () => _showPreview(snap),
                        onDelete: () => _deleteSnap(index),
                        scheme: scheme,
                      );
                    },
                  ),
          ),
          
          // ── ANSWER RESULT ──────────────────────────────────────────────
          if (_answer != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AnswerView(result: _answer!),
              ),
            ),
          
          // ── FOOTER: CHAT INPUT ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.qr_code_scanner, color: scheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _machineCodeController,
                        decoration: InputDecoration(
                          hintText: 'Mã máy (tuỳ chọn, vd: CNC-01)',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _questionController,
                        decoration: InputDecoration(
                          hintText: 'Hỏi về ảnh thiết bị này (vd: vị trí ở đâu?)...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _askQuestion(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _isAsking ? null : _askQuestion,
                      icon: _isAsking 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : const Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header / Capture Zone widget ──────────────────────────────────────────
class _CaptureHeader extends StatelessWidget {
  const _CaptureHeader({
    required this.onAdd,
    required this.loading,
    required this.snapCount,
    required this.scheme,
  });

  final VoidCallback onAdd;
  final bool loading;
  final int snapCount;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: scheme.primaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: loading ? null : onAdd,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: scheme.primaryContainer,
                child: loading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: scheme.primary,
                        ),
                      )
                    : Icon(Icons.add_a_photo_outlined,
                        size: 28, color: scheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kIsWeb
                          ? 'Tải lên ảnh thiết bị'
                          : 'Chụp hoặc tải lên ảnh thiết bị',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      snapCount == 0
                          ? 'Nhấn để thêm ảnh đầu tiên'
                          : 'Đang lưu $snapCount ảnh · Nhấn để thêm ảnh mới',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty State widget ─────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd, required this.scheme});

  final VoidCallback onAdd;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_roll_outlined,
              size: 64, color: scheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'Chưa có ảnh thiết bị nào',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Chụp hoặc tải lên ảnh thiết bị\nđể lưu vào danh sách Snap & Ask',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: scheme.outline),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Thêm ảnh đầu tiên'),
          ),
        ],
      ),
    );
  }
}

// ── Individual Snap Card ───────────────────────────────────────────────────
class _SnapCard extends StatelessWidget {
  const _SnapCard({
    required this.snap,
    required this.index,
    required this.formatDate,
    required this.onPreview,
    required this.onDelete,
    required this.scheme,
  });

  final _SnapEntry snap;
  final int index;
  final String Function(DateTime) formatDate;
  final VoidCallback onPreview;
  final VoidCallback onDelete;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    // Remove extension for display
    final displayName = snap.fileName.contains('.')
        ? snap.fileName.substring(0, snap.fileName.lastIndexOf('.'))
        : snap.fileName;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onPreview,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  snap.bytes,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 64,
                    height: 64,
                    color: scheme.surfaceContainerHigh,
                    child: Icon(Icons.broken_image,
                        color: scheme.outlineVariant),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName.isNotEmpty ? displayName : 'Ảnh ${index + 1}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 13, color: scheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          formatDate(snap.capturedAt),
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                scheme.tertiaryContainer.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Ảnh ${_formatSize(snap.bytes.length)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: scheme.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.zoom_in_rounded, color: scheme.primary),
                    tooltip: 'Xem ảnh',
                    onPressed: onPreview,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: scheme.error.withValues(alpha: 0.8)),
                    tooltip: 'Xóa ảnh',
                    onPressed: onDelete,
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: scheme.outline),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

// ── Custom Painter for Bounding Boxes ──────────────────────────────────────
class _BBoxPainter extends CustomPainter {
  _BBoxPainter(this.boxes);
  final List<Rect> boxes;

  @override
  void paint(Canvas canvas, Size size) {
    if (boxes.isEmpty) return;

    final paint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    for (final box in boxes) {
      final rect = Rect.fromLTRB(
        (box.left / 1000.0) * size.width,
        (box.top / 1000.0) * size.height,
        (box.right / 1000.0) * size.width,
        (box.bottom / 1000.0) * size.height,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BBoxPainter oldDelegate) => true;
}
