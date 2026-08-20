import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constrained_content.dart';
import '../../core/localization/locale_controller.dart';
import '../../data/models/answer_result.dart';
import '../../data/models/snap_entry.dart';
import '../../state/providers.dart';
import '../../state/snap_providers.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/image_source_picker_sheet.dart';
import 'widgets/snap_empty_state.dart';
import 'widgets/snap_image_picker_bar.dart';
import 'widgets/snap_input_footer.dart';
import 'widgets/snap_preview_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fallback answer used when API returns 5xx or is unreachable
// ─────────────────────────────────────────────────────────────────────────────

AnswerResult _buildFallbackAnswer(
  String fileName,
  String? machineCode,
  Object error,
  dynamic strings,
) {
  final machineTag = machineCode != null
      ? ' · Machine Code: **$machineCode**'
      : '';
  final status = error is DioException ? error.response?.statusCode : null;
  final String message;
  if (status == 401 || status == 403) {
    message =
        '⚠️ **Session expired.** Please log in again before analyzing images.';
  } else if (status == 429 || status == 503) {
    message =
        '⚠️ **Hệ thống AI đang bận.** Yêu cầu chưa được xử lý; vui lòng thử lại sau ít phút.';
  } else if (status == 504) {
    message =
        '⚠️ **Phân tích ảnh quá thời gian chờ.** OCR hoặc model ảnh xử lý quá lâu; vui lòng thử lại.';
  } else if (error is DioException &&
      error.type == DioExceptionType.receiveTimeout) {
    message =
        '⚠️ **Phân tích ảnh quá thời gian chờ.** Model ảnh xử lý quá lâu; vui lòng thử lại hoặc dùng ảnh nhỏ, rõ hơn.';
  } else if (error is DioException &&
      (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout)) {
    message =
        '⚠️ **Cannot connect to image analysis service.** Please check backend and AI service then retry.';
  } else {
    message =
        '⚠️ **Image analysis failed.** Server did not return a valid result; please retry.';
  }
  return AnswerResult(
    answer: '$message$machineTag\n\n**File:** `$fileName`',
    confidence: 0.0,
    locked: true,
    numericRule: false,
    reasoningMode: false,
    isOfflineFallback: true,
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
  final FocusNode _questionFocusNode = FocusNode();
  final ScrollController _chatScrollController = ScrollController();
  final ScrollController _thumbnailScrollController = ScrollController();

  static final _locRegex = RegExp(
    r'\[LOC\]\s*\(([^,]+),([^)]+)\),\s*\(([^,]+),([^)]+)\)\s*\[/LOC\]',
  );

  // ── Image capture / pick ──────────────────────────────────────────────────

  Future<void> _takePhoto() async {
    setState(() => _picking = true);
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        // Preserve drawing labels and dimensions for OCR. The AI service
        // creates a smaller derivative for the vision model separately.
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 88,
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
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 88,
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
    // Keyboard submit and send-button tap can arrive in the same frame on web.
    // Guard before reading state so one user action creates at most one request.
    if (_isAsking) return;

    final strings = ref.read(appStringsProvider);
    final snapState = ref.read(snapProvider);
    final snapIndex = snapState.selectedIndex;
    final snap = snapState.selectedSnap;

    if (snap == null || snapIndex == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.selectImageBeforeAsking)));
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

      String cleanText = rawAnswer.answer;
      for (final m in _locRegex.allMatches(cleanText)) {
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

      finalAnswer = AnswerResult(
        answer: cleanText,
        confidence: rawAnswer.confidence,
        locked: rawAnswer.locked,
        numericRule: rawAnswer.numericRule,
        reasoningMode: rawAnswer.reasoningMode,
        citations: rawAnswer.citations,
      );
    } catch (e) {
      finalAnswer = _buildFallbackAnswer(
        snap.fileName,
        machineCode.isNotEmpty ? machineCode : null,
        e,
        strings,
      );
      isError = true;
    }

    if (!mounted) return;

    ref
        .read(snapProvider.notifier)
        .addMessage(
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

  void _scanQR() {
    final strings = ref.read(appStringsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(strings.scanQrDesc),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _openImageSourcePicker() {
    showImageSourcePickerSheet(
      context: context,
      onTakePhoto: _takePhoto,
      onPickImage: _pickImage,
      onScanQR: _scanQR,
    );
  }

  void _openPreview(SnapEntry snap, List<Rect> boxes) {
    showSnapPreviewDialog(context: context, snap: snap, boxes: boxes);
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }

  @override
  void dispose() {
    _questionController.dispose();
    _questionFocusNode.dispose();
    _machineCodeController.dispose();
    _chatScrollController.dispose();
    _thumbnailScrollController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final snapState = ref.watch(snapProvider);
    final strings = ref.watch(appStringsProvider);
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
              if (snaps.isEmpty) ...[
                Expanded(
                  child: SnapEmptyState(
                    onAdd: _openImageSourcePicker,
                    scheme: scheme,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 10),
                RepaintBoundary(
                  child: SnapImagePickerBar(
                    snaps: snaps,
                    selectedIndex: selectedIndex,
                    scrollController: _thumbnailScrollController,
                    formatDate: _formatDate,
                    onSelect: _selectSnap,
                    onDelete: _deleteSnap,
                    onPreview: (i) => _openPreview(snaps[i], latestBoxes),
                    scheme: scheme,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    'Ảnh đang chọn ${(selectedIndex ?? 0) + 1}/${snaps.length} · Mỗi câu hỏi xử lý 1 ảnh',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(child: _buildChatArea(snap, scheme, strings)),
              ],
              RepaintBoundary(
                child: SnapInputFooter(
                  snap: snap,
                  isAsking: _isAsking,
                  picking: _picking,
                  questionController: _questionController,
                  questionFocusNode: _questionFocusNode,
                  machineCodeController: _machineCodeController,
                  machineCodeScanned: _machineCodeScanned,
                  onMachineCodeChanged: _onMachineCodeChanged,
                  onClearMachineCode: _clearMachineCode,
                  onOpenImageSourcePicker: _openImageSourcePicker,
                  onAskQuestion: _askQuestion,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Chat area ─────────────────────────────────────────────────────────────

  Widget _buildChatArea(SnapEntry? snap, ColorScheme scheme, dynamic strings) {
    if (snap == null) {
      return Center(
        child: Text(
          strings.selectImageToAsk,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }
    if (snap.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: scheme.outlineVariant,
            ),
            const SizedBox(height: 10),
            Text(
              strings.noQuestionsYet,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              strings.typeQuestionBelow,
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
}
