import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/locale_controller.dart';
import '../../data/models/answer_result.dart';

/// Shared widget to display an AI answer, confidence metadata, guardrail banners,
/// and a list of interactive citations. Used by both [SearchScreen] and [SnapAskScreen].
///
/// Set [shrinkWrap] to `true` when embedding inside another scrollable widget
/// (e.g. a `ListView.builder` in SnapAskScreen) to prevent the
/// `box.dart:2251` unbounded-height constraint crash.
class AnswerView extends ConsumerWidget {
  const AnswerView({
    required this.result,
    this.shrinkWrap = false,
    this.onFeedback,
    super.key,
  });

  final AnswerResult result;
  final bool shrinkWrap;

  /// Callback khi user feedback (helpful=true/false). Nếu null thì không hiển thị feedback row.
  final void Function(bool helpful)? onFeedback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final strings = ref.watch(appStringsProvider);

    // Build the children list once — shared between shrinkWrap and full modes.
    final children = <Widget>[
      // ── Guardrail RED banner ───────────────────────────────────────────────
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
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings.lockedAnswerWarning,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

      // ── Markdown answer ────────────────────────────────────────────────────
      // Luôn hiển thị nội dung phản hồi. Khi guardrail khóa vì không có nguồn
      // hoặc dịch vụ lỗi, banner phía trên vẫn giải thích trạng thái an toàn.
      if (result.answer.isNotEmpty)
        _MarkdownAnswer(
          text: result.answer,
          scheme: scheme,
          shrinkWrap: shrinkWrap,
        ),

      const SizedBox(height: 8),

      // ── Confidence + metadata + Copy row ───────────────────────────────────
      Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _MetaBadge(
            icon: Icons.analytics_outlined,
            label: '${strings.confidence}: ${(result.confidence * 100).toStringAsFixed(0)}%',
            scheme: scheme,
          ),
          if (result.numericRule)
            _MetaBadge(
              icon: Icons.pin_outlined,
              label: strings.directDataExtraction,
              scheme: scheme,
              color: scheme.tertiaryContainer,
              onColor: scheme.onTertiaryContainer,
            ),
          if (result.reasoningMode)
            _MetaBadge(
              icon: Icons.psychology_outlined,
              label: strings.reasoningMode,
              scheme: scheme,
              color: scheme.secondaryContainer,
              onColor: scheme.onSecondaryContainer,
            ),
          if (!result.locked && result.answer.isNotEmpty)
            _CopyAnswerButton(
              key: const ValueKey('copy_answer_button'),
              textToCopy: result.answer,
              scheme: scheme,
            ),
        ],
      ),

      // ── Citations ─────────────────────────────────────────────────────────────
      if (result.citations.isNotEmpty) ...[
        const SizedBox(height: 14),
        Text(
          strings.referenceSources,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        for (final c in result.citations)
          _CitationCard(citation: c, scheme: scheme, textTheme: textTheme),
      ],

      // ── Feedback row ──────────────────────────────────────────────────────
      if (onFeedback != null && !result.locked && result.answer.isNotEmpty) ...[
        const SizedBox(height: 12),
        _FeedbackRow(onFeedback: onFeedback!, scheme: scheme),
      ],
    ];

    if (shrinkWrap) {
      // Embedded mode: Column + no outer scroll (parent handles scrolling).
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      );
    }

    // Top-level mode (e.g. SearchScreen): full-height scrollable list.
    return ListView(
      padding: EdgeInsets.zero,
      children: children,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Markdown answer card
// ─────────────────────────────────────────────────────────────────────────────

class _MarkdownAnswer extends StatelessWidget {
  const _MarkdownAnswer({
    required this.text,
    required this.scheme,
    required this.shrinkWrap,
  });

  final String text;
  final ColorScheme scheme;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Markdown style sheet — matches app's Material theme.
    final mdStyle = MarkdownStyleSheet(
      // Body text
      p: textTheme.bodyMedium,
      // Bold
      strong: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      // Italic
      em: textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
      // Inline code
      code: textTheme.bodySmall?.copyWith(
        fontFamily: 'monospace',
        backgroundColor: scheme.surfaceContainerHighest,
        color: scheme.primary,
      ),
      // Code block
      codeblockDecoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      // Headings
      h1: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      h2: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      h3: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      // Block quote
      blockquoteDecoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border(left: BorderSide(color: scheme.primary, width: 3)),
      ),
      blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      // Horizontal rule
      horizontalRuleDecoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      // Table
      tableHead: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      tableBody: textTheme.bodySmall,
      tableBorder: TableBorder.all(
        color: scheme.outlineVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      tableHeadAlign: TextAlign.left,
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      tableColumnWidth: const FlexColumnWidth(),
      // Lists
      listBullet: textTheme.bodyMedium,
      listIndent: 20,
      // Spacings
      blockSpacing: 10,
      h1Padding: const EdgeInsets.only(top: 8, bottom: 4),
      h2Padding: const EdgeInsets.only(top: 6, bottom: 2),
      h3Padding: const EdgeInsets.only(top: 4, bottom: 2),
    );

    return MarkdownBody(
      data: text,
      styleSheet: mdStyle,
      shrinkWrap: shrinkWrap,
      selectable: true,
      softLineBreak: true,
      onTapLink: (_, _, _) {
        // Links inside AI responses are ignored gracefully.
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Metadata badge chip
// ─────────────────────────────────────────────────────────────────────────────

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({
    required this.icon,
    required this.label,
    required this.scheme,
    Color? color,
    Color? onColor,
  })  : _color = color,
        _onColor = onColor;

  final IconData icon;
  final String label;
  final ColorScheme scheme;
  final Color? _color;
  final Color? _onColor;

  @override
  Widget build(BuildContext context) {
    final bg = _color ?? scheme.surfaceContainerHighest;
    final fg = _onColor ?? scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Copy answer button
// ─────────────────────────────────────────────────────────────────────────────

class _CopyAnswerButton extends ConsumerStatefulWidget {
  const _CopyAnswerButton({
    super.key,
    required this.textToCopy,
    required this.scheme,
  });

  final String textToCopy;
  final ColorScheme scheme;

  @override
  ConsumerState<_CopyAnswerButton> createState() => _CopyAnswerButtonState();
}

class _CopyAnswerButtonState extends ConsumerState<_CopyAnswerButton> {
  bool _copied = false;

  Future<void> _copy() async {
    if (widget.textToCopy.isEmpty) return;
    try {
      await Clipboard.setData(ClipboardData(text: widget.textToCopy));
    } catch (_) {}
    if (!mounted) return;
    setState(() => _copied = true);

    final strings = ref.read(appStringsProvider);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(strings.copySuccessSnackbar),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final isDark = widget.scheme.brightness == Brightness.dark;
    final fg = _copied
        ? (isDark ? Colors.green.shade300 : Colors.green.shade800)
        : widget.scheme.onSurfaceVariant;
    final bg = _copied
        ? (isDark ? Colors.green.shade900.withValues(alpha: 0.35) : Colors.green.shade50)
        : widget.scheme.surfaceContainerHighest.withValues(alpha: 0.7);

    return InkWell(
      onTap: _copy,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _copied
                ? (isDark ? Colors.green.shade700 : Colors.green.shade300)
                : widget.scheme.outlineVariant.withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _copied ? Icons.check_rounded : Icons.copy_rounded,
              size: 12,
              color: fg,
            ),
            const SizedBox(width: 4),
            Text(
              _copied ? strings.copied : strings.copy,
              style: TextStyle(
                fontSize: 11,
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Citation card
// ─────────────────────────────────────────────────────────────────────────────

class _CitationCard extends ConsumerWidget {
  const _CitationCard({
    required this.citation,
    required this.scheme,
    required this.textTheme,
  });

  final Citation citation;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: scheme.primaryContainer,
          child: Text(
            '${citation.pageNo}',
            style: TextStyle(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(strings.pageNumber(citation.pageNo), style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: citation.snippet != null
            ? Text(
                citation.snippet!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              )
            : Text(
                citation.versionId,
                style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
        trailing: Icon(Icons.open_in_new, size: 16, color: scheme.primary),
        onTap: () => context.push('/viewer/${citation.versionId}?page=${citation.pageNo}'),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feedback row (👍 / 👎) — stateful để disable sau khi submit
// ─────────────────────────────────────────────────────────────────────────────

class _FeedbackRow extends ConsumerStatefulWidget {
  const _FeedbackRow({required this.onFeedback, required this.scheme});
  final void Function(bool helpful) onFeedback;
  final ColorScheme scheme;

  @override
  ConsumerState<_FeedbackRow> createState() => _FeedbackRowState();
}

class _FeedbackRowState extends ConsumerState<_FeedbackRow> {
  bool? _selected; // null = chưa chọn, true = helpful, false = not helpful

  void _pick(bool helpful) {
    if (_selected != null) return; // idempotent
    setState(() => _selected = helpful);
    widget.onFeedback(helpful);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final strings = ref.watch(appStringsProvider);

    return Row(
      children: [
        Text(
          strings.wasAnswerHelpful,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(width: 10),
        _FeedbackChip(
          label: '👍',
          selected: _selected == true,
          disabled: _selected != null,
          onTap: () => _pick(true),
          scheme: scheme,
        ),
        const SizedBox(width: 6),
        _FeedbackChip(
          label: '👎',
          selected: _selected == false,
          disabled: _selected != null,
          onTap: () => _pick(false),
          scheme: scheme,
        ),
        if (_selected != null) ...[
          const SizedBox(width: 8),
          Text(
            strings.thankYouFeedback,
            style: TextStyle(fontSize: 11, color: scheme.primary, fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }
}

class _FeedbackChip extends StatelessWidget {
  const _FeedbackChip({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onTap,
    required this.scheme,
  });

  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest.withValues(alpha: 0.6);
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.5 : 0.8,
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 15)),
      ),
    );
  }
}
