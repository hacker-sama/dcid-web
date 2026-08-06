import 'package:flutter/material.dart';

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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question bubble (right-aligned)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.question,
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (message.machineCode != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.memory_outlined,
                          size: 11,
                          color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          message.machineCode!,
                          style: TextStyle(
                            color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    formatDate(message.askedAt),
                    style: TextStyle(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.55),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Answer / error card (left-aligned)
          Container(
            decoration: BoxDecoration(
              color: message.isError
                  ? Colors.amber.shade50
                  : scheme.surfaceContainerLow,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: message.isError
                    ? Colors.amber.shade300
                    : scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fallback badge
                if (message.isError) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        size: 13,
                        color: Colors.amber.shade800,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Offline analysis — Backend not responding',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                ],
                AnswerView(result: message.answer, shrinkWrap: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
