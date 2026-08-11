import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/models/document_summary.dart';
import 'search_scope_header.dart';

/// Floating card container combining scope header controls and the chat text input.
class SearchChatInput extends StatelessWidget {
  const SearchChatInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.inputFocused,
    required this.loading,
    required this.selectedVersionIdsByDocId,
    required this.availableDocs,
    required this.resolvingDocIds,
    required this.reasoningMode,
    required this.hasChatMessages,
    required this.onAsk,
    required this.onSetDocumentSelected,
    required this.onClearDocSelection,
    required this.onClearChat,
    required this.onReasoningModeChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool inputFocused;
  final bool loading;
  final Map<String, String> selectedVersionIdsByDocId;
  final List<DocumentSummary> availableDocs;
  final Set<String> resolvingDocIds;
  final bool reasoningMode;
  final bool hasChatMessages;
  final VoidCallback onAsk;
  final Future<void> Function(DocumentSummary document, bool selected)
      onSetDocumentSelected;
  final VoidCallback onClearDocSelection;
  final VoidCallback onClearChat;
  final ValueChanged<bool> onReasoningModeChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final accent = accentFor(context);
    final accentGlow = accentGlowFor(context);

    final containerBg = isDark ? kDarkCard : Colors.white;
    final borderColor = inputFocused
        ? accent.withValues(alpha: 0.6)
        : (isDark
            ? kDarkBorder
            : colorScheme.outlineVariant.withValues(alpha: 0.5));

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 768),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          decoration: BoxDecoration(
            color: containerBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              if (inputFocused)
                BoxShadow(color: accentGlow, blurRadius: 16, spreadRadius: 0)
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.07),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SearchScopeHeader(
                selectedVersionIdsByDocId: selectedVersionIdsByDocId,
                availableDocs: availableDocs,
                resolvingDocIds: resolvingDocIds,
                reasoningMode: reasoningMode,
                loading: loading,
                hasChatMessages: hasChatMessages,
                onSetDocumentSelected: onSetDocumentSelected,
                onClearDocSelection: onClearDocSelection,
                onClearChat: onClearChat,
                onReasoningModeChanged: onReasoningModeChanged,
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: isDark
                    ? kDarkBorder
                    : colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
              _buildTextInput(context, colorScheme, accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput(
    BuildContext context,
    ColorScheme colorScheme,
    Color accent,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onSubmitted: (_) => onAsk(),
              textInputAction: TextInputAction.send,
              maxLines: 5,
              minLines: 1,
              style: const TextStyle(fontSize: 14, height: 1.5),
              decoration: InputDecoration(
                hintText: selectedVersionIdsByDocId.isEmpty
                    ? 'Ask about SOPs, specs, drawings (All documents)…'
                    : 'Ask about ${selectedVersionIdsByDocId.length} selected document(s)…',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.35),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SearchSendButton(
            onTap: loading ? null : onAsk,
            isLoading: loading,
            accent: accent,
          ),
        ],
      ),
    );
  }
}

class SearchSendButton extends StatefulWidget {
  const SearchSendButton({
    super.key,
    required this.onTap,
    required this.isLoading,
    required this.accent,
  });

  final VoidCallback? onTap;
  final bool isLoading;
  final Color accent;

  @override
  State<SearchSendButton> createState() => _SearchSendButtonState();
}

class _SearchSendButtonState extends State<SearchSendButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled
                ? (_hovered
                    ? widget.accent.withValues(alpha: 0.85)
                    : widget.accent)
                : widget.accent.withValues(alpha: 0.25),
            boxShadow: enabled && _hovered
                ? [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.arrow_upward_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
          ),
        ),
      ),
    );
  }
}
