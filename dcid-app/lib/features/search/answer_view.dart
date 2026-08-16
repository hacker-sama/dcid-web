import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/answer_result.dart';

/// Shared widget to display an AI answer, confidence metadata, guardrail banners,
/// and a list of interactive citations. Used by both [SearchScreen] and [SnapAskScreen].
///
/// Set [shrinkWrap] to `true` when embedding inside another scrollable widget
/// (e.g. a `ListView.builder` in SnapAskScreen) to prevent the
/// `box.dart:2251` unbounded-height constraint crash.
class AnswerView extends StatelessWidget {
  const AnswerView({
    required this.result,
    this.shrinkWrap = false,
    super.key,
  });

  final AnswerResult result;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                  '⚠ Insufficient data confidence.\n'
                  'Engineer verification required from attached drawing.',
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
      if (!result.locked && result.answer.isNotEmpty)
        _MarkdownAnswer(
          text: result.answer,
          scheme: scheme,
          shrinkWrap: shrinkWrap,
        ),

      const SizedBox(height: 8),

      // ── Confidence + metadata row ──────────────────────────────────────────
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _MetaBadge(
            icon: Icons.analytics_outlined,
            label: 'Confidence: ${(result.confidence * 100).toStringAsFixed(0)}%',
            scheme: scheme,
          ),
          if (result.numericRule)
            _MetaBadge(
              icon: Icons.pin_outlined,
              label: 'Direct Data Extraction',
              scheme: scheme,
              color: scheme.tertiaryContainer,
              onColor: scheme.onTertiaryContainer,
            ),
          if (result.reasoningMode)
            _MetaBadge(
              icon: Icons.psychology_outlined,
              label: 'Reasoning mode',
              scheme: scheme,
              color: scheme.secondaryContainer,
              onColor: scheme.onSecondaryContainer,
            ),
        ],
      ),

      // ── Citations ──────────────────────────────────────────────────────────
      if (result.citations.isNotEmpty) ...[
        const SizedBox(height: 14),
        Text(
          'Reference Sources',
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        for (final c in result.citations)
          _CitationCard(citation: c, scheme: scheme, textTheme: textTheme),
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
// Citation card
// ─────────────────────────────────────────────────────────────────────────────

class _CitationCard extends StatelessWidget {
  const _CitationCard({
    required this.citation,
    required this.scheme,
    required this.textTheme,
  });

  final Citation citation;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
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
        title: Text('Page ${citation.pageNo}', style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
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
