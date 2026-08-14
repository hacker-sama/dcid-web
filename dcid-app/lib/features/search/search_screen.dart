import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constrained_content.dart';
import '../../core/theme.dart';
import '../../data/models/answer_result.dart';
import '../../data/models/document_detail.dart';
import '../../data/models/document_summary.dart';
import '../../data/models/sse_event.dart';
import '../../state/providers.dart';
import 'widgets/search_chat_input.dart';
import 'widgets/search_empty_state.dart';
import 'answer_view.dart';
import '../../state/chat_sessions_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SearchScreen

// ─────────────────────────────────────────────────────────────────────────────
// SearchScreen
// ─────────────────────────────────────────────────────────────────────────────

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _loading = false;
  bool _inputFocused = false;
  String? _error;

  List<DocumentSummary> _availableDocs = [];
  final Map<String, String> _selectedVersionIdsByDocId = {};
  final Set<String> _resolvingDocIds = {};

  @override
  void initState() {
    super.initState();
    _loadDocs();

    _focusNode.addListener(() {
      if (mounted) setState(() => _inputFocused = _focusNode.hasFocus);
    });
  }

  Future<void> _loadDocs() async {
    try {
      final docs = await ref.read(docsRepositoryProvider).listDocuments();
      if (mounted) setState(() => _availableDocs = docs);
    } catch (_) {
      // Backend may not be ready yet — silent fail
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _useSuggestion(String text) {
    setState(() {
      _controller.text = text;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: text.length),
      );
    });
    _focusNode.requestFocus();
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

  Future<void> _setDocumentSelected(
    DocumentSummary document,
    bool selected,
  ) async {
    if (!selected) {
      setState(() => _selectedVersionIdsByDocId.remove(document.id));
      return;
    }

    setState(() => _resolvingDocIds.add(document.id));
    try {
      final detail = await ref
          .read(docsRepositoryProvider)
          .getDocumentDetail(document.id);
      final VersionSummary? version = detail.queryableVersion;
      if (!mounted) return;

      if (version == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Document "${document.title}" is still processing and cannot be used for AI queries yet.',
            ),
          ),
        );
        return;
      }

      setState(() {
        _selectedVersionIdsByDocId[document.id] = version.id;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load document version. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _resolvingDocIds.remove(document.id));
    }
  }

  Future<void> _ask() async {
    final question = _controller.text.trim();
    if (question.isEmpty || _loading) return;

    _controller.clear();

    String? sessionId = ref.read(activeChatSessionIdProvider);
    if (sessionId == null) {
      final session = ref
          .read(chatSessionsProvider.notifier)
          .createSession(question);
      sessionId = session.id;
      ref.read(activeChatSessionIdProvider.notifier).setId(sessionId);
    }

    final userMessage = ChatMessage(role: 'user', content: question);
    ref.read(chatSessionsProvider.notifier).addMessage(sessionId, userMessage);

    var assistantMessage = ChatMessage(role: 'assistant', content: '');
    assistantMessage = ref
        .read(chatSessionsProvider.notifier)
        .addMessage(sessionId, assistantMessage);

    setState(() {
      _loading = true;
      _error = null;
    });
    _scrollToBottom();

    try {
      final session = ref
          .read(chatSessionsProvider)
          .firstWhere((s) => s.id == sessionId);
      final history = session.messages
          .take(session.messages.length - 2)
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final stream = ref
          .read(docsRepositoryProvider)
          .askStream(
            question,
            reasoningMode: true,
            selectedVersionIds: _selectedVersionIdsByDocId.isEmpty
                ? null
                : _selectedVersionIdsByDocId.values.toList(),
            history: history,
          );

      List<Citation> currentCitations = [];
      bool isLocked = false;
      bool isNumeric = false;
      const bool isReasoning = true;
      double confidenceVal = 0.0;

      await for (final event in stream) {
        if (!mounted) break;
        if (event.type == SseEventType.meta) {
          currentCitations = event.citations;
          isLocked = event.locked;
          isNumeric = event.numericRule;
          confidenceVal = event.confidence;

          assistantMessage.result = AnswerResult(
            answer: assistantMessage.content,
            confidence: confidenceVal,
            locked: isLocked,
            numericRule: isNumeric,
            reasoningMode: isReasoning,
            citations: currentCitations,
          );
          ref
              .read(chatSessionsProvider.notifier)
              .updateMessage(sessionId, assistantMessage);
        } else if (event.type == SseEventType.delta) {
          if (event.textDelta != null) {
            assistantMessage.content += event.textDelta!;
            assistantMessage.result = AnswerResult(
              answer: assistantMessage.content,
              confidence: confidenceVal,
              locked: isLocked,
              numericRule: isNumeric,
              reasoningMode: isReasoning,
              citations: currentCitations,
            );
            ref
                .read(chatSessionsProvider.notifier)
                .updateMessage(sessionId, assistantMessage);
            _scrollToBottom();
          }
        } else if (event.type == SseEventType.error) {
          if (event.errorMessage != null &&
              event.errorMessage!.contains('Phiên đăng nhập')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session expired, please sign in again'),
                ),
              );
            }
          } else {
            setState(() {
              _error = event.errorMessage ?? 'Unable to complete query.';
            });
          }
        }
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Unable to complete query. Please check backend/AI connection.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearChat() {
    ref.read(activeChatSessionIdProvider.notifier).setId(null);
    setState(() {
      _error = null;
    });
  }

  // ─────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = accentFor(context);

    final sessionId = ref.watch(activeChatSessionIdProvider);
    // Use select() so the screen only rebuilds when the active session's
    // messages change — not on any other session mutation.
    final messages = ref.watch(
      chatSessionsProvider.select((sessions) {
        if (sessionId == null) return const <ChatMessage>[];
        final session = sessions.where((s) => s.id == sessionId).firstOrNull;
        return session?.messages ?? const <ChatMessage>[];
      }),
    );

    return SafeArea(
      child: ConstrainedContent(
        maxWidth: 960,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Chat history or welcome hero ──────────────────────────────
            Expanded(
              child: messages.isEmpty
                  ? SearchEmptyState(onUseSuggestion: _useSuggestion)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final entry = messages[index];
                        return RepaintBoundary(
                          child: _MessageBubble(entry: entry, accent: accent),
                        );
                      },
                    ),
            ),

            // Loading bar
            if (_loading)
              LinearProgressIndicator(
                color: accent,
                backgroundColor: accent.withValues(alpha: 0.12),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: colorScheme.error, fontSize: 13),
                ),
              ),

            // ── Floating chat input container (maxWidth 768) ───────────────
            RepaintBoundary(
              child: SearchChatInput(
                controller: _controller,
                focusNode: _focusNode,
                inputFocused: _inputFocused,
                loading: _loading,
                selectedVersionIdsByDocId: _selectedVersionIdsByDocId,
                availableDocs: _availableDocs,
                resolvingDocIds: _resolvingDocIds,
                hasChatMessages: messages.isNotEmpty,
                onAsk: _ask,
                onSetDocumentSelected: _setDocumentSelected,
                onClearDocSelection: () =>
                    setState(_selectedVersionIdsByDocId.clear),
                onClearChat: _clearChat,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Message bubble
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.entry, required this.accent});

  final ChatMessage entry;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isUser = entry.role == 'user';
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: isUser ? _buildUserBubble() : _buildAiBubble(colorScheme, isDark),
    );
  }

  // ── User pill bubble (right-aligned, no avatar) ───────────────────────────
  Widget _buildUserBubble() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
          // Lightweight border instead of blurry BoxShadow (GPU paint cost)
          border: Border.all(
            color: accent.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Text(
          entry.content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  // ── AI canvas-style response (no circular avatar) ─────────────────────────
  Widget _buildAiBubble(ColorScheme colorScheme, bool isDark) {
    final isOffline = entry.result?.isOfflineFallback == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Inline header: small icon + "Smart KCN Docs" title
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: isDark ? 0.2 : 0.1),
                border: Border.all(
                  color: accent.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.precision_manufacturing_rounded,
                  size: 13,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Smart KCN Docs',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: accent,
                letterSpacing: 0.1,
              ),
            ),
            if (isOffline) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade400, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 10,
                      color: Colors.amber.shade800,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Offline',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 10),

        // Response body — subtle border container (no heavy fill)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? kDarkCard.withValues(alpha: 0.7)
                : colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: entry.result == null
              ? Text(
                  entry.content.isEmpty ? '…' : entry.content,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    height: 1.5,
                  ),
                )
              : _SearchAnswerInline(entry: entry, accent: accent),
        ),

        const SizedBox(height: 6),

        // Muted "AI Knowledge Base • Smart KCN" metadata chip
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 11,
              color: colorScheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(width: 5),
            Text(
              'AI Knowledge Base  •  Smart KCN',
              style: TextStyle(
                fontSize: 10.5,
                color: colorScheme.onSurface.withValues(alpha: 0.35),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline answer renderer for Search chat (reuses AnswerView)
// ─────────────────────────────────────────────────────────────────────────────

class _SearchAnswerInline extends StatelessWidget {
  const _SearchAnswerInline({required this.entry, required this.accent});

  final ChatMessage entry;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final result = entry.result!;
    return AnswerView(result: result, shrinkWrap: true);
  }
}
