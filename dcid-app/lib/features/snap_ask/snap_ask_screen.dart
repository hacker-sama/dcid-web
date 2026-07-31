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

// ─────────────────────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────────────────────

/// A single Q&A exchange associated with one captured image.
class _ChatMessage {
  _ChatMessage({
    required this.question,
    required this.machineCode,
    required this.answer,
    required this.boundingBoxes,
    required this.askedAt,
  });

  final String question;
  final String? machineCode;
  final AnswerResult answer;
  final List<Rect> boundingBoxes;
  final DateTime askedAt;
}

/// A single captured/uploaded image entry in the Snap & Ask gallery.
/// Each entry owns its independent Q&A [messages] history.
class _SnapEntry {
  _SnapEntry({
    required this.bytes,
    required this.fileName,
    required this.capturedAt,
  });

  final Uint8List bytes;
  final String fileName;
  final DateTime capturedAt;

  /// Per-image Q&A chat history. Populated as the user asks questions about
  /// this specific image. Never cleared when switching to another image.
  final List<_ChatMessage> messages = [];
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class SnapAskScreen extends ConsumerStatefulWidget {
  const SnapAskScreen({super.key});

  @override
  ConsumerState<SnapAskScreen> createState() => _SnapAskScreenState();
}

class _SnapAskScreenState extends ConsumerState<SnapAskScreen> {
  final _imagePicker = ImagePicker();
  final List<_SnapEntry> _snaps = [];

  /// Index of the currently "active" image in [_snaps]. null = nothing selected.
  int? _selectedIndex;

  bool _picking = false;
  bool _isAsking = false;

  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _machineCodeController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  static final _locRegex = RegExp(
      r'\[LOC\]\s*\(([^,]+),([^)]+)\),\s*\(([^,]+),([^)]+)\)\s*\[/LOC\]');

  // ── Convenience getters ───────────────────────────────────────────────────

  _SnapEntry? get _selectedSnap =>
      (_selectedIndex != null && _selectedIndex! < _snaps.length)
          ? _snaps[_selectedIndex!]
          : null;

  // ── Image capture / pick ──────────────────────────────────────────────────

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
      // Camera not available on web — silently ignore.
    } finally {
      // FIX: always reset the loading state, even on early return.
      if (mounted) setState(() => _picking = false);
    }
  }

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
        // FIX: return without resetting _picking — the finally block handles it.
        return;
      }
      // Fallback to file_picker (web / desktop)
      await _pickWithFilePicker();
    } catch (_) {
      // image_picker threw (e.g. permissions denied) — try file_picker.
      await _pickWithFilePicker();
    } finally {
      // FIX: guaranteed reset regardless of which branch was taken.
      if (mounted) setState(() => _picking = false);
    }
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
    final newEntry = _SnapEntry(
      bytes: bytes,
      fileName: fileName,
      capturedAt: DateTime.now(),
    );
    setState(() {
      _snaps.insert(0, newEntry);
      // Auto-select the newly added image.
      _selectedIndex = 0;
    });
  }

  void _selectSnap(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    // Scroll the chat area to the bottom after switching images.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollChatToBottom());
  }

  void _deleteSnap(int index) {
    setState(() {
      _snaps.removeAt(index);
      if (_snaps.isEmpty) {
        _selectedIndex = null;
      } else if (_selectedIndex != null) {
        if (_selectedIndex! >= _snaps.length) {
          _selectedIndex = _snaps.length - 1;
        }
      }
    });
  }

  // ── Q&A ──────────────────────────────────────────────────────────────────

  Future<void> _askQuestion() async {
    final snap = _selectedSnap;
    if (snap == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh trước khi hỏi')),
      );
      return;
    }
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() => _isAsking = true);

    final machineCode = _machineCodeController.text.trim();

    try {
      final repo = ref.read(docsRepositoryProvider);
      final rawAnswer = await repo.askWithImage(
        question,
        snap.bytes,
        snap.fileName,
        machineCode: machineCode.isNotEmpty ? machineCode : null,
      );

      // Parse [LOC] bounding-box tags out of the answer text.
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

      if (!mounted) return;
      setState(() {
        snap.messages.add(
          _ChatMessage(
            question: question,
            machineCode: machineCode.isNotEmpty ? machineCode : null,
            answer: finalAnswer,
            boundingBoxes: parsedBoxes,
            askedAt: DateTime.now(),
          ),
        );
        _questionController.clear();
      });

      // Scroll to the latest chat message.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollChatToBottom());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _isAsking = false);
    }
  }

  void _scrollChatToBottom() {
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ── Bottom sheet: pick image source ──────────────────────────────────────

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
                    child: Icon(Icons.photo_library, color: scheme.secondary),
                  ),
                  title: Text(
                      kIsWeb ? 'Chọn ảnh từ máy tính' : 'Chọn từ thư viện'),
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

  // ── Full-screen image preview dialog ─────────────────────────────────────

  void _showPreview(_SnapEntry snap, List<Rect> boxes) {
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
                  foregroundPainter: _BBoxPainter(boxes),
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _questionController.dispose();
    _machineCodeController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final snap = _selectedSnap;
    // Latest bboxes from the most recent message of the selected image.
    final latestBoxes =
        (snap != null && snap.messages.isNotEmpty)
            ? snap.messages.last.boundingBoxes
            : <Rect>[];

    return ConstrainedContent(
      maxWidth: 840,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── HEADER: Capture Zone ──────────────────────────────────────────
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

          // ── BODY: Image list (fixed height) ──────────────────────────────
          if (_snaps.isEmpty)
            Expanded(
              flex: 2,
              child: _EmptyState(onAdd: _showImageSourcePicker, scheme: scheme),
            )
          else
            SizedBox(
              height: 260,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: _snaps.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = _snaps[index];
                  return _SnapCard(
                    snap: entry,
                    index: index,
                    isSelected: _selectedIndex == index,
                    formatDate: _formatDate,
                    onSelect: () => _selectSnap(index),
                    onPreview: () => _showPreview(entry, latestBoxes),
                    onDelete: () => _deleteSnap(index),
                    scheme: scheme,
                  );
                },
              ),
            ),

          // ── CHAT AREA: per-image Q&A history ─────────────────────────────
          if (_snaps.isNotEmpty) ...[
            const Divider(height: 1),
            Expanded(
              child: snap == null
                  ? Center(
                      child: Text(
                        'Chọn một ảnh để bắt đầu hỏi–đáp',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    )
                  : snap.messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 40, color: scheme.outlineVariant),
                              const SizedBox(height: 10),
                              Text(
                                'Chưa có câu hỏi nào cho ảnh này',
                                style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Nhập câu hỏi bên dưới để phân tích ảnh',
                                style: TextStyle(
                                    color: scheme.outline, fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _chatScrollController,
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          itemCount: snap.messages.length,
                          itemBuilder: (context, i) {
                            final msg = snap.messages[i];
                            return _ChatBubble(
                              message: msg,
                              scheme: scheme,
                              formatDate: _formatDate,
                            );
                          },
                        ),
            ),
          ],

          // ── FOOTER: Q&A Input ─────────────────────────────────────────────
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Machine code field
                Row(
                  children: [
                    Icon(Icons.qr_code_scanner,
                        color: _selectedSnap != null
                            ? scheme.primary
                            : scheme.outlineVariant,
                        size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _machineCodeController,
                        enabled: _selectedSnap != null,
                        decoration: InputDecoration(
                          hintText: 'Mã máy (tuỳ chọn, vd: CNC-01)',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Question input + send button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _questionController,
                        enabled: _selectedSnap != null && !_isAsking,
                        maxLines: 3,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: _selectedSnap == null
                              ? 'Chọn một ảnh để bắt đầu hỏi...'
                              : 'Hỏi về ảnh thiết bị này (vd: Phân tích hình ảnh này)...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: _selectedSnap != null && !_isAsking
                            ? (_) => _askQuestion()
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: IconButton.filled(
                        onPressed: (_selectedSnap != null && !_isAsking)
                            ? _askQuestion
                            : null,
                        icon: _isAsking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                      ),
                    ),
                  ],
                ),

                // Active image indicator
                if (_selectedSnap != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.image_outlined,
                          size: 13, color: scheme.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Đang hỏi về: ${_selectedSnap!.fileName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat Bubble Widget
// ─────────────────────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.scheme,
    required this.formatDate,
  });

  final _ChatMessage message;
  final ColorScheme scheme;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question bubble (right-aligned)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.question,
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (message.machineCode != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Mã máy: ${message.machineCode}',
                      style: TextStyle(
                        color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    formatDate(message.askedAt),
                    style: TextStyle(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Answer card (left-aligned, uses AnswerView)
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            padding: const EdgeInsets.all(12),
            child: AnswerView(result: message.answer),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header / Capture Zone
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

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
            'Chụp hoặc tải lên ảnh thiết bị\nđể bắt đầu phân tích bằng AI',
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

// ─────────────────────────────────────────────────────────────────────────────
// Individual Snap Card
// ─────────────────────────────────────────────────────────────────────────────

class _SnapCard extends StatelessWidget {
  const _SnapCard({
    required this.snap,
    required this.index,
    required this.isSelected,
    required this.formatDate,
    required this.onSelect,
    required this.onPreview,
    required this.onDelete,
    required this.scheme,
  });

  final _SnapEntry snap;
  final int index;
  final bool isSelected;
  final String Function(DateTime) formatDate;
  final VoidCallback onSelect;
  final VoidCallback onPreview;
  final VoidCallback onDelete;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final displayName = snap.fileName.contains('.')
        ? snap.fileName.substring(0, snap.fileName.lastIndexOf('.'))
        : snap.fileName;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? scheme.primary
              : scheme.outlineVariant.withValues(alpha: 0.5),
          width: isSelected ? 2.0 : 1.0,
        ),
        color: isSelected
            ? scheme.primaryContainer.withValues(alpha: 0.15)
            : scheme.surface,
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Selected indicator
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.check_circle,
                      color: scheme.primary, size: 18),
                ),

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
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isSelected ? scheme.primary : null,
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
                            color: scheme.tertiaryContainer
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _formatSize(snap.bytes.length),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: scheme.onTertiaryContainer,
                            ),
                          ),
                        ),
                        if (snap.messages.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: scheme.secondaryContainer
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${snap.messages.length} câu hỏi',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: scheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
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
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)}KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painter for Bounding Boxes
// ─────────────────────────────────────────────────────────────────────────────

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
