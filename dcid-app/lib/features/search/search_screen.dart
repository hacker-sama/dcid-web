import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constrained_content.dart';
import '../../data/models/answer_result.dart';
import '../../data/models/document_summary.dart';
import '../../state/providers.dart';

class _ChatEntry {
  final String role; // 'user' or 'assistant'
  final String content;
  final AnswerResult? result;

  _ChatEntry({required this.role, required this.content, this.result});
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _loading = false;
  bool _reasoningMode = false;
  String? _error;

  List<DocumentSummary> _availableDocs = [];
  final Set<String> _selectedDocIds = {};
  final List<_ChatEntry> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    try {
      final docs = await ref.read(docsRepositoryProvider).listDocuments();
      if (mounted) {
        setState(() => _availableDocs = docs);
      }
    } catch (_) {
      // Bỏ qua lỗi tải danh sách tài liệu nếu backend tạm thời chưa sẵn sàng
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _ask() async {
    final question = _controller.text.trim();
    if (question.isEmpty || _loading) return;

    _controller.clear();
    setState(() {
      _loading = true;
      _error = null;
      _chatMessages.add(_ChatEntry(role: 'user', content: question));
    });
    _scrollToBottom();

    try {
      final history = _chatMessages
          .take(_chatMessages.length - 1)
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final result = await ref.read(docsRepositoryProvider).ask(
            question,
            reasoningMode: _reasoningMode,
            selectedVersionIds: _selectedDocIds.isEmpty ? null : _selectedDocIds.toList(),
            history: history,
          );

      if (mounted) {
        setState(() {
          _chatMessages.add(_ChatEntry(
            role: 'assistant',
            content: result.answer,
            result: result,
          ));
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không truy vấn được. Kiểm tra kết nối backend/AI.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearChat() {
    setState(() {
      _chatMessages.clear();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedContent(
      maxWidth: 960,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Thanh chọn tài liệu nguồn (NotebookLM Source Panel) ──
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.library_books_outlined, size: 18, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          _selectedDocIds.isEmpty
                              ? '🌐 Phạm vi: Tất cả tài liệu (Global RAG)'
                              : '📌 Phạm vi: Đã chỉ định ${_selectedDocIds.length} tài liệu nguồn',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        if (_selectedDocIds.isNotEmpty)
                          TextButton.icon(
                            onPressed: () => setState(() => _selectedDocIds.clear()),
                            icon: const Icon(Icons.clear_all, size: 16),
                            label: const Text('Bỏ chọn tất cả', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                      ],
                    ),
                    if (_availableDocs.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _availableDocs.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final doc = _availableDocs[index];
                            final isSelected = _selectedDocIds.contains(doc.id);
                            return FilterChip(
                              label: Text(
                                doc.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                              ),
                              selected: isSelected,
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    _selectedDocIds.add(doc.id);
                                  } else {
                                    _selectedDocIds.remove(doc.id);
                                  }
                                });
                              },
                              avatar: isSelected ? const Icon(Icons.check, size: 16) : null,
                              visualDensity: VisualDensity.compact,
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Tùy chọn Suy luận & Nút làm mới hội thoại ──
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Chế độ Tư vấn / Suy luận quy trình lắp đặt',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    subtitle: const Text(
                      'AI suy luận chi tiết các bước thao tác, tháo lắp từ phân tích cấu tạo bản vẽ',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _reasoningMode,
                    onChanged: _loading ? null : (val) => setState(() => _reasoningMode = val),
                  ),
                ),
                if (_chatMessages.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _clearChat,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Xóa hội thoại'),
                  ),
              ],
            ),
            const Divider(height: 16),

            // ── Khung lịch sử tin nhắn NotebookLM ──
            Expanded(
              child: _chatMessages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_outlined, size: 48, color: colorScheme.outline),
                          const SizedBox(height: 12),
                          Text(
                            'Trợ lý AI Smart KCN Docs sẵn sàng',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colorScheme.outline),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Chọn tài liệu phía trên hoặc hỏi trực tiếp để bắt đầu hội thoại',
                            style: TextStyle(fontSize: 13, color: colorScheme.outline),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _chatMessages.length,
                      itemBuilder: (context, index) {
                        final entry = _chatMessages[index];
                        return _MessageBubble(entry: entry);
                      },
                    ),
            ),

            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(_error!, style: TextStyle(color: colorScheme.error)),
              ),
            const SizedBox(height: 8),

            // ── Ô nhập câu hỏi ──
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _ask(),
                    decoration: InputDecoration(
                      hintText: _selectedDocIds.isEmpty
                          ? 'Hỏi về SOP, thông số, bản vẽ (Toàn bộ tài liệu)...'
                          : 'Hỏi về ${_selectedDocIds.length} tài liệu đã chọn...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _loading ? null : _ask,
                  icon: const Icon(Icons.send),
                  label: const Text('Gửi'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.entry});

  final _ChatEntry entry;

  @override
  Widget build(BuildContext context) {
    final isUser = entry.role == 'user';
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(Icons.auto_awesome, size: 16, color: colorScheme.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? colorScheme.primary : colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(16),
                  bottomLeft: !isUser ? const Radius.circular(2) : const Radius.circular(16),
                ),
                border: !isUser ? Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.content,
                    style: TextStyle(
                      color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  if (!isUser && entry.result != null) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _Badge(
                          label: 'Độ tin cậy: ${(entry.result!.confidence * 100).toStringAsFixed(0)}%',
                          color: colorScheme.secondaryContainer,
                          textColor: colorScheme.onSecondaryContainer,
                        ),
                        if (entry.result!.numericRule)
                          _Badge(
                            label: 'Trích số liệu trực tiếp',
                            color: colorScheme.tertiaryContainer,
                            textColor: colorScheme.onTertiaryContainer,
                          ),
                        if (entry.result!.reasoningMode)
                          _Badge(
                            label: 'Tư vấn / Suy luận AI',
                            color: colorScheme.primaryContainer,
                            textColor: colorScheme.onPrimaryContainer,
                          ),
                      ],
                    ),
                    if (entry.result!.citations.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Nguồn trích dẫn:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.outline),
                      ),
                      const SizedBox(height: 4),
                      for (final c in entry.result!.citations)
                        InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Row(
                                  children: [
                                    Icon(Icons.spatial_tracking_outlined, color: colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Trích dẫn - Trang ${c.pageNo}',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (c.bboxKey != null) ...[
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.crop_free, size: 16, color: colorScheme.primary),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Tọa độ Bbox: ${c.bboxKey}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: colorScheme.primary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      Text(
                                        'Nội dung gốc (kèm ngữ cảnh không gian):',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.outline,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: colorScheme.outlineVariant),
                                        ),
                                        child: Text(
                                          c.snippet ?? 'Không có thông tin chi tiết.',
                                          style: const TextStyle(fontSize: 13, height: 1.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Đóng'),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      context.push('/viewer/${c.versionId}?page=${c.pageNo}');
                                    },
                                    icon: const Icon(Icons.open_in_new, size: 16),
                                    label: const Text('Mở trang xem tài liệu (Viewer)'),
                                  ),
                                ],
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.description_outlined, size: 14, color: colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  c.bboxKey != null
                                      ? 'Trang ${c.pageNo} [Bbox]'
                                      : 'Trang ${c.pageNo} (${c.versionId.substring(0, 8)}...)',
                                  style: TextStyle(fontSize: 12, color: colorScheme.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.secondary,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.textColor});

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }
}
