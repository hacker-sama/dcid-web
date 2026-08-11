import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constrained_content.dart';
import '../../core/theme.dart';
import '../../data/models/answer_result.dart';
import '../../data/models/document_detail.dart';
import '../../data/models/document_summary.dart';
import '../../data/models/sse_event.dart';
import '../../state/providers.dart';
import 'widgets/search_chat_input.dart';
import 'widgets/search_empty_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class _ChatEntry {
  final String role; // 'user' or 'assistant'
  String content;
  AnswerResult? result;

  _ChatEntry({required this.role, required this.content});
}

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
  bool _reasoningMode = false;
  bool _inputFocused = false;
  String? _error;

  List<DocumentSummary> _availableDocs = [];
  final Map<String, String> _selectedVersionIdsByDocId = {};
  final Set<String> _resolvingDocIds = {};
  final List<_ChatEntry> _chatMessages = [];

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
    final assistantEntry = _ChatEntry(role: 'assistant', content: '');

    setState(() {
      _loading = true;
      _error = null;
      _chatMessages.add(_ChatEntry(role: 'user', content: question));
      _chatMessages.add(assistantEntry);
    });
    _scrollToBottom();

    try {
      final history = _chatMessages
          .take(_chatMessages.length - 2)
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final stream = ref.read(docsRepositoryProvider).askStream(
            question,
            reasoningMode: _reasoningMode,
            selectedVersionIds: _selectedVersionIdsByDocId.isEmpty
                ? null
                : _selectedVersionIdsByDocId.values.toList(),
            history: history,
          );

      List<Citation> currentCitations = [];
      bool isLocked = false;
      bool isNumeric = false;
      bool isReasoning = _reasoningMode;
      double confidenceVal = 0.0;

      await for (final event in stream) {
        if (!mounted) break;
        if (event.type == SseEventType.meta) {
          currentCitations = event.citations;
          isLocked = event.locked;
          isNumeric = event.numericRule;
          isReasoning = event.reasoningMode;
          confidenceVal = event.confidence;
          setState(() {
            assistantEntry.result = AnswerResult(
              answer: assistantEntry.content,
              confidence: confidenceVal,
              locked: isLocked,
              numericRule: isNumeric,
              reasoningMode: isReasoning,
              citations: currentCitations,
            );
          });
        } else if (event.type == SseEventType.delta) {
          if (event.textDelta != null) {
            setState(() {
              assistantEntry.content += event.textDelta!;
              assistantEntry.result = AnswerResult(
                answer: assistantEntry.content,
                confidence: confidenceVal,
                locked: isLocked,
                numericRule: isNumeric,
                reasoningMode: isReasoning,
                citations: currentCitations,
              );
            });
            _scrollToBottom();
          }
        } else if (event.type == SseEventType.error) {
          setState(() {
            _error = event.errorMessage ?? 'Unable to complete query.';
          });
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
    setState(() {
      _chatMessages.clear();
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

    return ConstrainedContent(
      maxWidth: 960,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Chat history or welcome hero ──────────────────────────────
          Expanded(
            child: _chatMessages.isEmpty
                ? SearchEmptyState(onUseSuggestion: _useSuggestion)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, index) {
                      final entry = _chatMessages[index];
                      return _MessageBubble(entry: entry, accent: accent);
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                _error!,
                style: TextStyle(color: colorScheme.error, fontSize: 13),
              ),
            ),

          // ── Floating chat input container (maxWidth 768) ───────────────
          SearchChatInput(
            controller: _controller,
            focusNode: _focusNode,
            inputFocused: _inputFocused,
            loading: _loading,
            selectedVersionIdsByDocId: _selectedVersionIdsByDocId,
            availableDocs: _availableDocs,
            resolvingDocIds: _resolvingDocIds,
            reasoningMode: _reasoningMode,
            hasChatMessages: _chatMessages.isNotEmpty,
            onAsk: _ask,
            onSetDocumentSelected: _setDocumentSelected,
            onClearDocSelection: () =>
                setState(_selectedVersionIdsByDocId.clear),
            onClearChat: _clearChat,
            onReasoningModeChanged: (val) =>
                setState(() => _reasoningMode = val),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message bubble
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.entry, required this.accent});

  final _ChatEntry entry;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isUser = entry.role == 'user';
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI avatar
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? kDarkCard : Colors.white,
                border: Border.all(
                  color: accent.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.precision_manufacturing_rounded,
                  size: 16,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Bubble body
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                        colors: [
                          accent,
                          accent.withValues(alpha: 0.82),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser
                    ? null
                    : (isDark ? kDarkCard : Colors.white),
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                  bottomLeft: !isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                border: !isUser
                    ? Border.all(
                        color: isDark
                            ? kDarkBorder
                            : colorScheme.outlineVariant
                                .withValues(alpha: 0.35),
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? accent.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Offline fallback banner
                  if (!isUser && entry.result?.isOfflineFallback == true) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade400, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.wifi_off_rounded, size: 18, color: Colors.amber.shade900),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '⚠️ Backend/AI offline — Showing cached results',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Main text
                  Text(
                    entry.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : colorScheme.onSurface,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  // Meta badges & citations
                  if (!isUser && entry.result != null) ...[
                    const SizedBox(height: 10),
                    Divider(
                      height: 1,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _Badge(
                          label:
                              'Confidence: ${(entry.result!.confidence * 100).toStringAsFixed(0)}%',
                          color: colorScheme.secondaryContainer,
                          textColor: colorScheme.onSecondaryContainer,
                        ),
                        if (entry.result!.numericRule)
                          _Badge(
                            label: 'Direct Data Extraction',
                            color: colorScheme.tertiaryContainer,
                            textColor: colorScheme.onTertiaryContainer,
                          ),
                        if (entry.result!.reasoningMode)
                          _Badge(
                            label: 'AI Reasoning',
                            color: accent.withValues(alpha: 0.15),
                            textColor: accent,
                          ),
                      ],
                    ),
                    if (entry.result!.citations.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Citations:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      for (final c in entry.result!.citations)
                        _CitationChip(citation: c, accent: accent),
                    ],
                  ],
                ],
              ),
            ),
          ),

          // User avatar
          if (isUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.secondaryContainer,
              ),
              child: Center(
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 18,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Citation chip
// ─────────────────────────────────────────────────────────────────────────────

class _CitationChip extends StatelessWidget {
  const _CitationChip({required this.citation, required this.accent});

  final Citation citation;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => _CitationDialog(
            citation: citation,
            colorScheme: colorScheme,
            accent: accent,
          ),
        );
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 14, color: accent),
            const SizedBox(width: 4),
            Text(
              citation.bboxKey != null
                  ? 'Page ${citation.pageNo} [Bbox]'
                  : 'Page ${citation.pageNo} (${citation.versionId.substring(0, 8)}...)',
              style: TextStyle(fontSize: 12, color: accent),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Citation dialog
// ─────────────────────────────────────────────────────────────────────────────

class _CitationDialog extends StatelessWidget {
  const _CitationDialog({
    required this.citation,
    required this.colorScheme,
    required this.accent,
  });

  final Citation citation;
  final ColorScheme colorScheme;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.spatial_tracking_outlined, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Citation — Page ${citation.pageNo}',
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
            if (citation.bboxKey != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.crop_free, size: 16, color: accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Bbox Coords: ${citation.bboxKey}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Original Content (with spatial context):',
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
                citation.snippet ?? 'No detailed information available.',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            context.push(
              '/viewer/${citation.versionId}?page=${citation.pageNo}',
            );
          },
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text('Open Document Viewer'),
          style: FilledButton.styleFrom(backgroundColor: accent),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
  });

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
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
