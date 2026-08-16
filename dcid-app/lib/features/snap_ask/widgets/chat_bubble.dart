import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/models/snap_entry.dart';
import '../../search/answer_view.dart';

/// Single Q&A chat bubble rendered in the Snap & Ask conversation list.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.scheme,
    required this.formatDate,
  });

  final ChatMessage message;
  final ColorScheme scheme;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    final accent = accentFor(context);
    final isDark = scheme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── User question bubble (right-aligned, no avatar) ──────────────
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.question,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                  if (message.machineCode != null) ...[
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.memory_outlined,
                          size: 11,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          message.machineCode!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    formatDate(message.askedAt),
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── AI Response — canvas-style, no heavy box ─────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Inline header: icon + "Smart KCN Docs"
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
                  if (message.isError) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.amber.shade400, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off_rounded,
                              size: 10, color: Colors.amber.shade800),
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

              // Response body — subtle container (very light border only)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? kDarkCard.withValues(alpha: 0.7)
                      : scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: AnswerView(result: message.answer, shrinkWrap: true),
              ),

              const SizedBox(height: 8),

              // Subtle AI metadata chip at the bottom
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 11,
                    color: scheme.onSurface.withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'AI Knowledge Base  •  Smart KCN',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: scheme.onSurface.withValues(alpha: 0.35),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
