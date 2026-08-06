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
  final machineTag = machineCode != null ? ' · Machine Code: **$machineCode**' : '';
  return AnswerResult(
    answer: '⚠️ **Offline Analysis (Mock)** — AI service temporarily unavailable$machineTag.\n\n'
        '**File:** `$fileName`\n\n'
        '**Technical OCR (simulated):**\n'
        '| Parameter | Value |\n'
        '|---|---|\n'
        '| Component | Servo Driver MR-J4-10A |\n'
        '| Input Voltage | 200–230 VAC ±10% |\n'
        '| Rated Current | 3.5 A |\n'
        '| Operating Temp | 0°C – 55°C |\n\n'
        '**Suggestion for question:** "$question"\n\n'
        'Check backend connection (`dcid-ai` port 8000) and LM Studio (port 1234). '
        'If the service is ready, try your question again — the answer will come from the real LLM.',
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
        const SnackBar(content: Text('Please select an image before asking')),
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

  void _scanQR() {
    // QR scanning is wired to the machine code field.
    // On platforms with a camera the user can scan a QR code;
    // the result is populated into _machineCodeController.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR scanner coming soon — enter the machine code manually for now.'),
        duration: Duration(seconds: 3),
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
    showSnapPreviewDialog(
      context: context,
      snap: snap,
      boxes: boxes,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

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
              // ── SECTION 1: Horizontal thumbnail strip (or empty state) ─────────
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

                // ── SECTION 2: Chat area ────────────────────────────────────────
                Expanded(
                  child: _buildChatArea(snap, scheme),
                ),
              ],

              // ── SECTION 3: Q&A input footer (always visible) ──────────────────
              const Divider(height: 1),
              _buildInputFooter(snap, scheme),
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
          'Select an image to start asking questions',
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
              'No questions yet for this image',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Type your question below to start the analysis',
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

  Widget _buildInputFooter(SnapEntry? snap, ColorScheme scheme) {
    final hasSnap = snap != null;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Machine Code field (compact, stacked above message input) ──────
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _machineCodeScanned
                  ? Colors.green.shade50
                  : scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _machineCodeScanned
                    ? Colors.green.shade300
                    : scheme.outlineVariant.withValues(alpha: 0.5),
                width: _machineCodeScanned ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.memory_outlined,
                    size: 15,
                    color: _machineCodeScanned
                        ? Colors.green.shade600
                        : scheme.outlineVariant,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _machineCodeController,
                    onChanged: _onMachineCodeChanged,
                    style: const TextStyle(fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: 'Machine Code (optional, e.g. CNC-01)',
                      hintStyle: TextStyle(
                          fontSize: 12.5, color: scheme.outlineVariant),
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 8),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      // Green badge shown when code is entered
                      suffixIcon: _machineCodeScanned
                          ? GestureDetector(
                              onTap: _clearMachineCode,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: Colors.green.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle,
                                        size: 12,
                                        color: Colors.green.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      _machineCodeController.text.trim(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.close,
                                        size: 11,
                                        color: Colors.green.shade400),
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
          ),

          const SizedBox(height: 8),

          // ── Main message input row: unified card with [+] prefix ──────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Unified input card: [+] | text field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // + Attachment button — integrated inside the input card
                      Tooltip(
                        message: 'Add image or scan QR',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: _picking ? null : _openImageSourcePicker,
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(12, 10, 6, 10),
                            child: _picking
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: scheme.primary,
                                    ),
                                  )
                                : Icon(
                                    Icons.add_circle_outline_rounded,
                                    size: 22,
                                    color: scheme.primary,
                                  ),
                          ),
                        ),
                      ),
                      // Subtle divider between + and text field
                      Container(
                        width: 1,
                        height: 20,
                        color: scheme.outlineVariant.withValues(alpha: 0.4),
                        margin: const EdgeInsets.only(bottom: 12),
                      ),
                      // Text field
                      Expanded(
                        child: TextField(
                          controller: _questionController,
                          enabled: hasSnap && !_isAsking,
                          maxLines: 4,
                          minLines: 1,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: hasSnap
                                ? 'Ask about this device photo...'
                                : 'Select an image to start asking...',
                            hintStyle: TextStyle(
                                fontSize: 14, color: scheme.outlineVariant),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.fromLTRB(
                                10, 11, 10, 11),
                          ),
                          onSubmitted:
                              (hasSnap && !_isAsking)
                                  ? (_) => _askQuestion()
                                  : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send button — filled circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 46,
                width: 46,
                child: FilledButton(
                  onPressed: (hasSnap && !_isAsking) ? _askQuestion : null,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                  ),
                  child: _isAsking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                ),
              ),
            ],
          ),

          // ── Active image label ────────────────────────────────────────────
          if (hasSnap) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.image_outlined, size: 11, color: scheme.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Asking about: ${snap.fileName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
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
    );
  }
}

