import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/query_history_item.dart';
import '../../state/providers.dart';

/// Provider tải lịch sử câu hỏi, tự refresh khi rebuild.
final _historyProvider = FutureProvider.autoDispose<List<QueryHistoryItem>>((ref) async {
  final raw = await ref.watch(docsRepositoryProvider).getQueryHistory(page: 0, size: 50);
  return raw
      .map((e) => QueryHistoryItem.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Màn hình lịch sử câu hỏi cá nhân.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_historyProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử câu hỏi'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_historyProvider),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: e.toString(), onRetry: () => ref.invalidate(_historyProvider)),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyState(scheme: scheme);
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) => _HistoryTile(
              item: items[index],
              scheme: scheme,
              onFeedback: (helpful, note) => _submitFeedback(
                context, ref, items[index].id, helpful, note,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitFeedback(
    BuildContext context,
    WidgetRef ref,
    String id,
    bool helpful,
    String? note,
  ) async {
    try {
      await ref.read(docsRepositoryProvider).submitFeedback(id, helpful: helpful, note: note);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(helpful ? '👍 Cảm ơn phản hồi!' : '👎 Đã ghi nhận phản hồi.'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        ref.invalidate(_historyProvider);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không gửi được phản hồi. Thử lại sau.')),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History tile
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.item,
    required this.scheme,
    required this.onFeedback,
  });

  final QueryHistoryItem item;
  final ColorScheme scheme;
  final void Function(bool helpful, String? note) onFeedback;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Question ────────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                item.locked ? Icons.lock_outline_rounded : Icons.chat_bubble_outline_rounded,
                size: 16,
                color: item.locked ? Colors.orange : scheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.question,
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // ── Answer preview ──────────────────────────────────────────────────
          if (item.answerPreview != null && item.answerPreview!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                item.answerPreview!,
                style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          const SizedBox(height: 8),

          // ── Metadata row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Row(
              children: [
                // Timestamp
                Icon(Icons.schedule, size: 12, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(dateStr, style: textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),

                // Confidence badge
                if (item.confidence != null) ...[
                  const SizedBox(width: 12),
                  _SmallBadge(
                    label: '${(item.confidence! * 100).toStringAsFixed(0)}%',
                    color: _confidenceColor(item.confidence!),
                    scheme: scheme,
                  ),
                ],

                // Locked badge
                if (item.locked) ...[
                  const SizedBox(width: 6),
                  _SmallBadge(label: 'Locked', color: Colors.orange, scheme: scheme),
                ],

                const Spacer(),

                // Feedback buttons — chỉ hiển thị nếu chưa feedback
                if (item.feedback == null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _FeedbackButton(
                        icon: Icons.thumb_up_outlined,
                        label: '👍',
                        onTap: () => _confirmFeedback(context, true),
                        scheme: scheme,
                      ),
                      const SizedBox(width: 4),
                      _FeedbackButton(
                        icon: Icons.thumb_down_outlined,
                        label: '👎',
                        onTap: () => _confirmFeedback(context, false),
                        scheme: scheme,
                      ),
                    ],
                  )
                else
                  _SmallBadge(
                    label: item.feedback == 1 ? '👍 Hữu ích' : '👎 Không hữu ích',
                    color: item.feedback == 1 ? Colors.green : Colors.red,
                    scheme: scheme,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _confidenceColor(double c) {
    if (c >= 0.7) return Colors.green;
    if (c >= 0.5) return Colors.orange;
    return Colors.red;
  }

  void _confirmFeedback(BuildContext context, bool helpful) {
    final noteCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(helpful ? '👍 Hữu ích' : '👎 Không hữu ích'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              helpful
                  ? 'Đánh dấu câu trả lời này là hữu ích?'
                  : 'Đánh dấu câu trả lời này là không hữu ích?',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tuỳ chọn)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Huỷ')),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onFeedback(helpful, noteCtrl.text.isEmpty ? null : noteCtrl.text);
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label, required this.color, required this.scheme});
  final String label;
  final Color color;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.scheme,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty / Error states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 56, color: scheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'Chưa có câu hỏi nào',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Các câu hỏi bạn đặt sẽ xuất hiện ở đây.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          const Text('Không tải được lịch sử'),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
