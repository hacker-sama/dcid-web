import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constrained_content.dart';
import '../../data/models/answer_result.dart';
import '../../data/models/snap_entry.dart';
import '../../state/providers.dart';
import '../../state/snap_providers.dart';
import 'widgets/add_image_button.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/empty_state.dart';
import 'widgets/image_source_picker_sheet.dart';
import 'widgets/snap_preview_dialog.dart';
import 'widgets/thumbnail_strip.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fallback answer used when API returns 5xx or is unreachable
// ─────────────────────────────────────────────────────────────────────────────

AnswerResult _buildFallbackAnswer(
    String question, String fileName, String? machineCode) {
  final machineTag = machineCode != null ? ' · Mã máy: **$machineCode**' : '';
  return AnswerResult(
    answer: '⚠️ **Phân tích ngoại tuyến (Mock)** — Dịch vụ AI tạm thời không '
        'phản hồi$machineTag.\n\n'
        '**Tệp:** `$fileName`\n\n'
        '**OCR kỹ thuật (giả lập):**\n'
        '| Thông số | Giá trị |\n'
        '|---|---|\n'
        '| Linh kiện | Servo Driver MR-J4-10A |\n'
        '| Điện áp vào | 200–230 VAC ±10% |\n'
        '| Dòng định mức | 3.5 A |\n'
        '| Nhiệt độ vận hành | 0°C – 55°C |\n\n'
        '**Gợi ý cho câu hỏi:** "$question"\n\n'
        'Kiểm tra kết nối backend (`dcid-ai` port 8000) và LM Studio (port 1234). '
        'Nếu dịch vụ sẵn sàng, thử lại câu hỏi — kết quả sẽ đến từ LLM thực.',
    confidence: 0.0,
    locked: false,
    numericRule: false,
    reasoningMode: false,
    citations: [],
  );
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

  // Transient UI flags
  bool _picking = false;
  bool _isAsking = false;

  // Machine code field + scanned state
  final TextEditingController _machineCodeController = TextEditingController();
  bool _machineCodeScanned = false; // true = green badge shown

  final TextEditingController _questionController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final ScrollController _thumbnailScrollController = ScrollController();

  static final _locRegex = RegExp(
      r'\[LOC\]\s*\(([^,]+),([^)]+)\),\s*\(([^,]+),([^)]+)\)\s*\[/LOC\]');

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
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _pickImage() async {
    setState(() => _picking = true);
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (images.isNotEmpty) {
        final List<({Uint8List bytes, String fileName})> items = [];
        for (final image in images) {
          final bytes = await image.readAsBytes();
          items.add((bytes: bytes, fileName: image.name));
        }
        _addSnaps(items);
        return;
      }
      await _pickWithFilePicker();
    } catch (_) {
      await _pickWithFilePicker();
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _pickWithFilePicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final List<({Uint8List bytes, String fileName})> items = [];
    for (final file in result.files) {
      if (file.bytes != null) {
        items.add((bytes: file.bytes!, fileName: file.name));
      }
    }
    if (items.isNotEmpty) {
      _addSnaps(items);
    }
  }

  void _addSnap(Uint8List bytes, String fileName) {
    _addSnaps([(bytes: bytes, fileName: fileName)]);
  }

  void _addSnaps(List<({Uint8List bytes, String fileName})> items) {
    if (items.isEmpty) return;
    ref.read(snapProvider.notifier).addSnaps(items);
    // Scroll thumbnail strip to the start (newest images).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_thumbnailScrollController.hasClients) {
        _thumbnailScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _selectSnap(int index) {
    ref.read(snapProvider.notifier).selectSnap(index);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollChatToBottom());
  }

  void _deleteSnap(int index) {
    ref.read(snapProvider.notifier).deleteSnap(index);
  }

  // ── Machine code helpers ──────────────────────────────────────────────────

  void _onMachineCodeChanged(String value) {
    setState(() => _machineCodeScanned = value.trim().isNotEmpty);
  }

  void _clearMachineCode() {
    _machineCodeController.clear();
    setState(() => _machineCodeScanned = false);
  }

  // ── Q&A ──────────────────────────────────────────────────────────────────

  Future<void> _askQuestion() async {
    final snapState = ref.read(snapProvider);
    final snapIndex = snapState.selectedIndex;
    final snap = snapState.selectedSnap;

    if (snap == null || snapIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh trước khi hỏi')),
      );
      return;
    }
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() => _isAsking = true);

    final machineCode = _machineCodeController.text.trim();
    AnswerResult finalAnswer;
    List<Rect> parsedBoxes = [];
    bool isError = false;

    try {
      final repo = ref.read(docsRepositoryProvider);
      final rawAnswer = await repo.askWithImage(
        question,
        snap.bytes,
        snap.fileName,
        machineCode: machineCode.isNotEmpty ? machineCode : null,
      );

      // Parse [LOC] bounding-box annotations.
      String cleanText = rawAnswer.answer;
      for (final m in _locRegex.allMatches(cleanText)) {
        try {
          final x1 = double.parse(m.group(1)!);
          final y1 = double.parse(m.group(2)!);
          final x2 = double.parse(m.group(3)!);
          final y2 = double.parse(m.group(4)!);
          if (x1 < x2 && y1 < y2) parsedBoxes.add(Rect.fromLTRB(x1, y1, x2, y2));
        } catch (_) {}
      }
      cleanText = cleanText.replaceAll(_locRegex, '').trim();

      finalAnswer = AnswerResult(
        answer: cleanText,
        confidence: rawAnswer.confidence,
        locked: rawAnswer.locked,
        numericRule: rawAnswer.numericRule,
        reasoningMode: rawAnswer.reasoningMode,
        citations: rawAnswer.citations,
      );
    } catch (e) {
      // ── GRACEFUL FALLBACK ──────
      finalAnswer = _buildFallbackAnswer(
        question,
        snap.fileName,
        machineCode.isNotEmpty ? machineCode : null,
      );
      isError = true;
    }

    if (!mounted) return;

    ref.read(snapProvider.notifier).addMessage(
          snapIndex,
          ChatMessage(
            question: question,
            machineCode: machineCode.isNotEmpty ? machineCode : null,
            answer: finalAnswer,
            boundingBoxes: parsedBoxes,
            askedAt: DateTime.now(),
            isError: isError,
          ),
        );

    setState(() {
      _questionController.clear();
      _isAsking = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollChatToBottom());
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

  void _openImageSourcePicker() {
    showImageSourcePickerSheet(
      context: context,
      onTakePhoto: _takePhoto,
      onPickImage: _pickImage,
    );
  }

  void _openPreview(SnapEntry snap, List<Rect> boxes) {
    showSnapPreviewDialog(
      context: context,
      snap: snap,
      boxes: boxes,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
    if (diff.inHours < 24) return '${diff.inHours} giờ';
    return '${dt.day}/${dt.month}';
  }

  @override
  void dispose() {
    _questionController.dispose();
    _machineCodeController.dispose();
    _chatScrollController.dispose();
    _thumbnailScrollController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final snapState = ref.watch(snapProvider);
    final snaps = snapState.snaps;
    final snap = snapState.selectedSnap;
    final selectedIndex = snapState.selectedIndex;
    final scheme = Theme.of(context).colorScheme;

    final latestBoxes = (snap != null && snap.messages.isNotEmpty)
        ? snap.messages.last.boundingBoxes
        : <Rect>[];

    return Scaffold(
      body: SafeArea(
        child: ConstrainedContent(
          maxWidth: 840,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── SECTION 1: Add button header ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: AddImageButton(
                  onAdd: _openImageSourcePicker,
                  loading: _picking,
                  scheme: scheme,
                ),
              ),

              // ── SECTION 2: Horizontal thumbnail strip ─────────────────────────
              if (snaps.isEmpty) ...[
                Expanded(
                  child: EmptyState(onAdd: _openImageSourcePicker, scheme: scheme),
                ),
              ] else ...[
                const SizedBox(height: 10),
                ThumbnailStrip(
                  snaps: snaps,
                  selectedIndex: selectedIndex,
                  scrollController: _thumbnailScrollController,
                  formatDate: _formatDate,
                  onSelect: _selectSnap,
                  onDelete: _deleteSnap,
                  onPreview: (i) => _openPreview(snaps[i], latestBoxes),
                  scheme: scheme,
                ),
                const Divider(height: 1),

                // ── SECTION 3: Chat area ────────────────────────────────────────
                Expanded(
                  child: _buildChatArea(snap, scheme),
                ),

                // ── SECTION 4: Q&A input footer ─────────────────────────────────
                const Divider(height: 1),
                _buildInputFooter(snap, scheme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Chat area ─────────────────────────────────────────────────────────────

  Widget _buildChatArea(SnapEntry? snap, ColorScheme scheme) {
    if (snap == null) {
      return Center(
        child: Text(
          'Chọn một ảnh để bắt đầu hỏi–đáp',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }
    if (snap.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 40, color: scheme.outlineVariant),
            const SizedBox(height: 10),
            Text(
              'Chưa có câu hỏi nào cho ảnh này',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Nhập câu hỏi bên dưới để phân tích',
              style: TextStyle(color: scheme.outline, fontSize: 12),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _chatScrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: snap.messages.length,
      itemBuilder: (context, i) => ChatBubble(
        message: snap.messages[i],
        scheme: scheme,
        formatDate: _formatDate,
      ),
    );
  }

  // ── Input footer ──────────────────────────────────────────────────────────

  Widget _buildInputFooter(SnapEntry? snap, ColorScheme scheme) {
    final hasSnap = snap != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Machine code row with scanned badge
          Row(
            children: [
              Icon(
                Icons.qr_code_scanner,
                color: _machineCodeScanned
                    ? Colors.green
                    : (hasSnap ? scheme.primary : scheme.outlineVariant),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _machineCodeController,
                  enabled: hasSnap,
                  onChanged: _onMachineCodeChanged,
                  decoration: InputDecoration(
                    hintText: 'Mã máy (tuỳ chọn, vd: CNC-01)',
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _machineCodeScanned ? Colors.green : scheme.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _machineCodeScanned
                            ? Colors.green
                            : scheme.outlineVariant,
                        width: _machineCodeScanned ? 1.8 : 1.0,
                      ),
                    ),
                    // Green "Đã quét" badge as suffix
                    suffixIcon: _machineCodeScanned
                        ? GestureDetector(
                            onTap: _clearMachineCode,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 5),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 13, color: Colors.green.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Đã quét: ${_machineCodeController.text.trim()}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.close,
                                      size: 12, color: Colors.green.shade400),
                                ],
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Question input + send
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _questionController,
                  enabled: hasSnap && !_isAsking,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: hasSnap
                        ? 'Hỏi về ảnh thiết bị này (vd: Phân tích hình ảnh này)...'
                        : 'Chọn một ảnh để bắt đầu hỏi...',
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted:
                      (hasSnap && !_isAsking) ? (_) => _askQuestion() : null,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: IconButton.filled(
                  onPressed: (hasSnap && !_isAsking) ? _askQuestion : null,
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

          // Active image label
          if (hasSnap) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.image_outlined, size: 12, color: scheme.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Đang hỏi về: ${snap.fileName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        color: scheme.primary,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
