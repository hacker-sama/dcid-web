import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constrained_content.dart';
import '../../data/models/answer_result.dart';
import '../../data/models/snap_entry.dart';
import '../../state/providers.dart';
import '../../state/snap_providers.dart';
import '../search/answer_view.dart';

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

  // Transient UI flags — these are fine as local state because they only
  // matter while the user is actively on this screen.
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
      // ── GRACEFUL FALLBACK: 500, DioException, TimeoutException, etc. ──────
      // Never show a crash or black error bar. Instead surface a structured
      // mock analysis so the screen stays functional even when backend is down.
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

  // ── Bottom sheet: image source picker ────────────────────────────────────

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
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                if (!kIsWeb) ...[
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: scheme.primaryContainer.withValues(alpha: 0.3),
                    leading: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(Icons.camera_alt, color: scheme.primary),
                    ),
                    title: const Text('Chụp ảnh'),
                    subtitle: const Text('Mở camera để chụp thiết bị'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () { Navigator.pop(ctx); _takePhoto(); },
                  ),
                  const SizedBox(height: 8),
                ],
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: scheme.secondaryContainer.withValues(alpha: 0.3),
                  leading: CircleAvatar(
                    backgroundColor: scheme.secondaryContainer,
                    child: Icon(Icons.photo_library, color: scheme.secondary),
                  ),
                  title: Text(kIsWeb ? 'Chọn ảnh từ máy tính' : 'Chọn từ thư viện'),
                  subtitle: Text(kIsWeb ? 'Tải lên tệp ảnh từ máy tính' : 'Chọn ảnh có sẵn trên thiết bị'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () { Navigator.pop(ctx); _pickImage(); },
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Full-screen preview dialog ─────────────────────────────────────────────

  void _showPreview(SnapEntry snap, List<Rect> boxes) {
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
    // Watch the global snap state — rebuilds automatically when snaps or
    // selection change, including when returning to this tab.
    final snapState = ref.watch(snapProvider);
    final snaps = snapState.snaps;
    final snap = snapState.selectedSnap;
    final selectedIndex = snapState.selectedIndex;
    final scheme = Theme.of(context).colorScheme;

    final latestBoxes = (snap != null && snap.messages.isNotEmpty)
        ? snap.messages.last.boundingBoxes
        : <Rect>[];

    return ConstrainedContent(
      maxWidth: 840,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── SECTION 1: Add button header ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _AddImageButton(
              onAdd: _showImageSourcePicker,
              loading: _picking,
              scheme: scheme,
            ),
          ),

          // ── SECTION 2: Horizontal thumbnail strip ─────────────────────────
          if (snaps.isEmpty) ...[
            Expanded(
              child: _EmptyState(onAdd: _showImageSourcePicker, scheme: scheme),
            ),
          ] else ...[
            const SizedBox(height: 10),
            _ThumbnailStrip(
              snaps: snaps,
              selectedIndex: selectedIndex,
              scrollController: _thumbnailScrollController,
              formatDate: _formatDate,
              onSelect: _selectSnap,
              onDelete: _deleteSnap,
              onPreview: (i) => _showPreview(snaps[i], latestBoxes),
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
      itemBuilder: (context, i) => _ChatBubble(
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
                color: _machineCodeScanned ? Colors.green : (hasSnap ? scheme.primary : scheme.outlineVariant),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 13, color: Colors.green.shade700),
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
                                  Icon(Icons.close, size: 12, color: Colors.green.shade400),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (hasSnap && !_isAsking) ? (_) => _askQuestion() : null,
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
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
                    style: TextStyle(fontSize: 11, color: scheme.primary, fontStyle: FontStyle.italic),
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

// ─────────────────────────────────────────────────────────────────────────────
// Add Image Button (compact header)
// ─────────────────────────────────────────────────────────────────────────────

class _AddImageButton extends StatelessWidget {
  const _AddImageButton({required this.onAdd, required this.loading, required this.scheme});

  final VoidCallback onAdd;
  final bool loading;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: loading ? null : onAdd,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: scheme.primaryContainer.withValues(alpha: 0.5),
        foregroundColor: scheme.onPrimaryContainer,
      ),
      icon: loading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: scheme.primary),
            )
          : const Icon(Icons.add_a_photo_outlined, size: 20),
      label: Text(
        loading
            ? 'Đang tải...'
            : (kIsWeb ? 'Tải lên ảnh thiết bị' : 'Chụp / Tải lên ảnh thiết bị'),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Horizontal Thumbnail Strip
// ─────────────────────────────────────────────────────────────────────────────

class _ThumbnailStrip extends StatelessWidget {
  const _ThumbnailStrip({
    required this.snaps,
    required this.selectedIndex,
    required this.scrollController,
    required this.formatDate,
    required this.onSelect,
    required this.onDelete,
    required this.onPreview,
    required this.scheme,
  });

  final List<SnapEntry> snaps;
  final int? selectedIndex;
  final ScrollController scrollController;
  final String Function(DateTime) formatDate;
  final void Function(int) onSelect;
  final void Function(int) onDelete;
  final void Function(int) onPreview;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: snaps.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final snap = snaps[index];
          final isSelected = selectedIndex == index;
          return _ThumbnailCard(
            snap: snap,
            index: index,
            isSelected: isSelected,
            formatDate: formatDate,
            onTap: () => onSelect(index),
            onDelete: () => onDelete(index),
            onPreview: () => onPreview(index),
            scheme: scheme,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual Thumbnail Card
// ─────────────────────────────────────────────────────────────────────────────

class _ThumbnailCard extends StatelessWidget {
  const _ThumbnailCard({
    required this.snap,
    required this.index,
    required this.isSelected,
    required this.formatDate,
    required this.onTap,
    required this.onDelete,
    required this.onPreview,
    required this.scheme,
  });

  final SnapEntry snap;
  final int index;
  final bool isSelected;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onPreview;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final chatCount = snap.messages.length;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 82,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: scheme.primary.withValues(alpha: 0.25), blurRadius: 8, spreadRadius: 1)]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image fill
              Image.memory(
                snap.bytes,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: scheme.surfaceContainerHigh,
                  child: Icon(Icons.broken_image, color: scheme.outlineVariant),
                ),
              ),

              // Gradient overlay at bottom
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.45, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                ),
              ),

              // Timestamp bottom-left
              Positioned(
                left: 5,
                bottom: 5,
                right: 22,
                child: Text(
                  formatDate(snap.capturedAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w500),
                ),
              ),

              // Chat count badge (top-left)
              if (chatCount > 0)
                Positioned(
                  top: 5,
                  left: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$chatCount',
                      style: TextStyle(color: scheme.onPrimary, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

              // Active checkmark (top-right)
              if (isSelected)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, size: 11, color: scheme.onPrimary),
                  ),
                ),

              // Delete button (bottom-right, overlaid)
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 11, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat Bubble
// ─────────────────────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.scheme,
    required this.formatDate,
  });

  final ChatMessage message;
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  if (message.machineCode != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.memory_outlined, size: 11, color: scheme.onPrimaryContainer.withValues(alpha: 0.7)),
                        const SizedBox(width: 3),
                        Text(
                          message.machineCode!,
                          style: TextStyle(color: scheme.onPrimaryContainer.withValues(alpha: 0.7), fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    formatDate(message.askedAt),
                    style: TextStyle(color: scheme.onPrimaryContainer.withValues(alpha: 0.55), fontSize: 10),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Answer / error card (left-aligned)
          Container(
            decoration: BoxDecoration(
              color: message.isError
                  ? Colors.amber.shade50
                  : scheme.surfaceContainerLow,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: message.isError
                    ? Colors.amber.shade300
                    : scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fallback badge
                if (message.isError) ...[
                  Row(
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 13, color: Colors.amber.shade800),
                      const SizedBox(width: 5),
                      Text(
                        'Phân tích ngoại tuyến — Backend không phản hồi',
                        style: TextStyle(fontSize: 11, color: Colors.amber.shade800, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                ],
                AnswerView(result: message.answer, shrinkWrap: true),
              ],
            ),
          ),
        ],
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
          Icon(Icons.camera_roll_outlined, size: 64, color: scheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'Chưa có ảnh thiết bị nào',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
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
// BBox Painter
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
      canvas.drawRect(
        Rect.fromLTRB(
          (box.left / 1000.0) * size.width,
          (box.top / 1000.0) * size.height,
          (box.right / 1000.0) * size.width,
          (box.bottom / 1000.0) * size.height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BBoxPainter oldDelegate) => true;
}
