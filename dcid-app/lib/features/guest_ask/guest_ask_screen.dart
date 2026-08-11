import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constrained_content.dart';
import '../../data/models/guest_session_models.dart';
import '../../state/guest_session_controller.dart';

class GuestAskScreen extends ConsumerStatefulWidget {
  const GuestAskScreen({super.key});

  @override
  ConsumerState<GuestAskScreen> createState() => _GuestAskScreenState();
}

class _GuestAskScreenState extends ConsumerState<GuestAskScreen> {
  final _questionController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sessionState = ref.read(guestSessionControllerProvider);
      if (!sessionState.hasActiveSession) {
        ref.read(guestSessionControllerProvider.notifier).initSession();
      }
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        if (file.size > 25 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Dung lượng file vượt quá giới hạn 25MB.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        await ref
            .read(guestSessionControllerProvider.notifier)
            .uploadDocument(file.bytes!, file.name);
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guestSessionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.forum_outlined, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Hỏi đáp Công khai (Phân hệ B)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          if (state.hasActiveSession)
            TextButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Kết thúc phiên làm việc?'),
                    content: const Text(
                      'Tất cả tài liệu PDF và vector tạm thời trong phiên này sẽ bị tiêu hủy hoàn toàn.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Hủy'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Kết thúc ngay'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref
                      .read(guestSessionControllerProvider.notifier)
                      .endSession();
                }
              },
              icon: const Icon(Icons.power_settings_new, color: Colors.red, size: 18),
              label: const Text('Hủy phiên', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: ConstrainedContent(
        child: Column(
          children: [
            // ── Top Session Info Bar ─────────────────────────────────────────
            _buildSessionHeader(context, state),

            if (state.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.red.shade50,
                child: Text(
                  state.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),

            // ── Document List & Upload Bar ──────────────────────────────────
            _buildDocumentSection(context, state),

            const Divider(height: 1),

            // ── Chat Q&A List ───────────────────────────────────────────────
            Expanded(
              child: state.messages.isEmpty
                  ? _buildEmptyState(context, state)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final msg = state.messages[index];
                        return _buildChatBubble(context, msg);
                      },
                    ),
            ),

            if (state.isAsking)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'AI đang phân tích tài liệu và truy vấn...',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),

            // ── Question Input Bar ──────────────────────────────────────────
            _buildInputBar(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionHeader(BuildContext context, GuestSessionState state) {
    if (state.isLoading) {
      return Container(
        padding: const EdgeInsets.all(12),
        color: Colors.blue.shade50,
        child: const Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Đang khởi tạo phiên ẩn danh...'),
          ],
        ),
      );
    }

    if (!state.hasActiveSession) {
      return Container(
        padding: const EdgeInsets.all(12),
        color: Colors.orange.shade50,
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Phiên chưa được tạo hoặc đã hết hạn.',
                style: TextStyle(fontSize: 13),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(guestSessionControllerProvider.notifier).initSession();
              },
              child: const Text('Tạo phiên mới'),
            ),
          ],
        ),
      );
    }

    final expiresAt = state.session!.expiresAt;
    final remainingMins = expiresAt.difference(DateTime.now()).inMinutes;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Colors.green, size: 8),
                SizedBox(width: 4),
                Text(
                  'Phiên tạm ACTIVE',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.timer_outlined, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            'TTL: ${remainingMins > 0 ? '$remainingMins phút' : 'Sắp hết hạn'}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
          ),
          const Spacer(),
          Text(
            'ID: ${state.session!.id.substring(0, 8)}...',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSection(BuildContext context, GuestSessionState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tài liệu tạm (${state.documents.length}/3 file PDF)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              ElevatedButton.icon(
                onPressed: state.isUploading || state.documents.length >= 3
                    ? null
                    : _pickAndUploadPdf,
                icon: state.isUploading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file, size: 16),
                label: Text(state.isUploading ? 'Đang tải...' : '+ Upload PDF'),
              ),
            ],
          ),
          if (state.documents.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.documents.map((doc) {
                return _buildDocumentChip(doc);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentChip(GuestDocumentItem doc) {
    Color bg;
    Widget statusIcon;

    if (doc.isReady) {
      bg = Colors.green.shade50;
      statusIcon = const Icon(Icons.check_circle, color: Colors.green, size: 14);
    } else if (doc.isFailed) {
      bg = Colors.red.shade50;
      statusIcon = const Icon(Icons.error, color: Colors.red, size: 14);
    } else {
      bg = Colors.orange.shade50;
      statusIcon = const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.picture_as_pdf, size: 16, color: Colors.red),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              doc.originalFilename,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 6),
          statusIcon,
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, GuestSessionState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Tải lên file PDF để bắt đầu hỏi đáp',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tài liệu tạm sẽ được phân tích tự động. Mọi dữ liệu sẽ bị tiêu hủy hoàn toàn sau khi kết thúc phiên.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: state.isUploading ? null : _pickAndUploadPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Chọn file PDF ngay'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(BuildContext context, ChatMessageItem msg) {
    final isUser = msg.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).primaryColor
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: isUser ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
            if (!isUser && msg.answerResult != null) ...[
              const SizedBox(height: 8),
              if (msg.answerResult!.citations.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'Nguồn trích dẫn:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                ...msg.answerResult!.citations.map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• Trang ${c.pageNo}: ${c.snippet ?? ''}',
                      style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                    ),
                  );
                }),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, GuestSessionState state) {
    final canAsk = state.hasActiveSession && state.hasReadyDocuments && !state.isAsking;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _questionController,
              enabled: canAsk,
              decoration: InputDecoration(
                hintText: canAsk
                    ? 'Nhập câu hỏi về tài liệu tạm...'
                    : 'Tải PDF và chờ xử lý xong để hỏi...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onSubmitted: (_) {
                if (canAsk) {
                  ref
                      .read(guestSessionControllerProvider.notifier)
                      .askQuestion(_questionController.text);
                  _questionController.clear();
                  _scrollToBottom();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.send),
            onPressed: canAsk
                ? () {
                    ref
                        .read(guestSessionControllerProvider.notifier)
                        .askQuestion(_questionController.text);
                    _questionController.clear();
                    _scrollToBottom();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
