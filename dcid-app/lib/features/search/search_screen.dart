import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constrained_content.dart';
import '../../data/models/answer_result.dart';
import '../../state/providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  AnswerResult? _result;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final question = _controller.text.trim();
    if (question.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await ref.read(docsRepositoryProvider).ask(question);
      if (mounted) setState(() => _result = result);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không truy vấn được. Kiểm tra kết nối backend/AI.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedContent(
      maxWidth: 840,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _ask(),
                  decoration: const InputDecoration(
                    hintText: 'Hỏi về SOP, thông số, bản vẽ...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _loading ? null : _ask,
                icon: const Icon(Icons.send),
                label: const Text('Hỏi'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          if (_result != null) Expanded(child: _AnswerView(result: _result!)),
        ],
      ),
    ),
   );
  }
}

class _AnswerView extends StatelessWidget {
  const _AnswerView({required this.result});

  final AnswerResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      children: [
        // ── Guardrail RED banner ─────────────────────────────────────
        if (result.locked)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '⚠ Không đủ dữ liệu chắc chắn.\n'
                    'Yêu cầu kỹ sư xác minh từ bản vẽ đính kèm.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),

        // ── Answer card ──────────────────────────────────────────────
        if (!result.locked)
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                result.answer,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),

        const SizedBox(height: 8),

        // ── Confidence + metadata ────────────────────────────────────
        Text(
          'Độ tin cậy: ${(result.confidence * 100).toStringAsFixed(0)}%'
          '${result.numericRule ? '  ·  Trích số liệu trực tiếp' : ''}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),

        // ── Citations ────────────────────────────────────────────────
        if (result.citations.isNotEmpty) ...[
          Text(
            'Nguồn tham chiếu',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          for (final c in result.citations)
            Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    '${c.pageNo}',
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                title: Text('Trang ${c.pageNo}'),
                subtitle: c.snippet != null
                    ? Text(
                        c.snippet!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    : Text(
                        c.versionId,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () {
                  // Navigate to the document viewer with page number.
                  context.push(
                    '/viewer/${c.versionId}?page=${c.pageNo}',
                  );
                },
              ),
            ),
        ],
      ],
    );
  }
}
