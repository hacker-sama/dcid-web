import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/theme.dart';
import '../../../data/models/document_summary.dart';
import 'search_scope_header.dart';

/// Floating card container combining scope header controls and the chat text input.
class SearchChatInput extends ConsumerWidget {
  const SearchChatInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.inputFocused,
    required this.loading,
    required this.selectedVersionIdsByDocId,
    required this.availableDocs,
    required this.resolvingDocIds,
    required this.hasChatMessages,
    required this.onAsk,
    required this.onSetDocumentSelected,
    required this.onClearDocSelection,
    required this.onClearChat,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool inputFocused;
  final bool loading;
  final Map<String, String> selectedVersionIdsByDocId;
  final List<DocumentSummary> availableDocs;
  final Set<String> resolvingDocIds;
  final bool hasChatMessages;
  final VoidCallback onAsk;
  final Future<void> Function(DocumentSummary document, bool selected)
  onSetDocumentSelected;
  final VoidCallback onClearDocSelection;
  final VoidCallback onClearChat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final accent = accentFor(context);
    final accentGlow = accentGlowFor(context);
    final strings = ref.watch(appStringsProvider);

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
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                  blurRadius: 16,
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
                loading: loading,
                hasChatMessages: hasChatMessages,
                onSetDocumentSelected: onSetDocumentSelected,
                onClearDocSelection: onClearDocSelection,
                onClearChat: onClearChat,
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: isDark
                    ? kDarkBorder
                    : colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              _buildTextInput(context, colorScheme, accent, strings),
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
    dynamic strings,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.enter): () {
                  if (!loading && controller.text.trim().isNotEmpty) {
                    onAsk();
                  }
                },
                const SingleActivator(LogicalKeyboardKey.numpadEnter): () {
                  if (!loading && controller.text.trim().isNotEmpty) {
                    onAsk();
                  }
                },
              },
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onSubmitted: (_) {
                  if (!loading && controller.text.trim().isNotEmpty) {
                    onAsk();
                  }
                },
                textInputAction: TextInputAction.send,
                maxLines: 5,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontSize: 14, height: 1.5),
                decoration: InputDecoration(
                  hintText: selectedVersionIdsByDocId.isEmpty
                      ? strings.searchPlaceholderAll
                      : strings.searchPlaceholderSelected(selectedVersionIdsByDocId.length),
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              final isInputEmpty = value.text.trim().isEmpty;
              return SearchSendButton(
                onTap: (loading || isInputEmpty) ? null : onAsk,
                isLoading: loading,
                accent: accent,
              );
            },
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
    final colorScheme = Theme.of(context).colorScheme;

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
                      color: colorScheme.primary.withValues(alpha: 0.35),
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
                : Icon(
                    Icons.arrow_upward_rounded,
                    size: 18,
                    color: enabled
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
          ),
        ),
      ),
    );
  }
}
